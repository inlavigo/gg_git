// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_git/gg_git.dart';
import 'package:gg_git/src/commands/get_tags.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

import 'package:gg_git/src/test_helpers/test_helpers.dart';

void main() {
  late Directory d;
  final messages = <String>[];
  late GetTags getTags;

  // ...........................................................................
  setUp(() {
    d = initTestDir();
    messages.clear();
    getTags = GetTags(
      log: messages.add,
      processWrapper: const GgProcessWrapper(),
    );
  });

  // ...........................................................................
  tearDown(() {
    d.deleteSync(recursive: true);
  });

  // ...........................................................................
  group('HeadTags', () {
    group('fromHead', () {
      group('should throw', () {
        test('when directory is not a git repo', () async {
          await expectLater(
            getTags.fromHead(directory: d),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'Directory "test" is not a git repository.',
              ),
            ),
          );
        });
      });

      group('should return nothing', () {
        test('when no tags are available', () async {
          await initGit(d);
          final result = await getTags.fromHead(directory: d);
          expect(result, isEmpty);
          expect(messages, isEmpty);
        });
      });

      group('should return', () {
        group('one', () {
          test('when available', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTag(d, 'V0');
            expect(await getTags.fromHead(directory: d), ['V0']);
            expect(messages, isEmpty);
          });
        });

        group('multiple', () {
          test('when available', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['V0', 'T0', 'T1']);
            expect(await getTags.fromHead(directory: d), ['V0', 'T1', 'T0']);
          });

          test('but not tags of previous commits', () async {
            await initGit(d);
            await setPubspec(d, version: '1.0.0');
            commitPubspec(d);
            await addTag(d, 'T0');
            expect(await getTags.fromHead(directory: d), ['T0']);

            // Commit a new change -> No tags should be returned
            await setPubspec(d, version: '2.0.0');
            commitPubspec(d);
            expect(await getTags.fromHead(directory: d), isEmpty);
          });
        });
      });
    });

    group('all(....)', () {
      group('should return', () {
        test('all tags', () async {
          await initGit(d);
          addAndCommitSampleFile(d);

          // Initially we should get no tags
          expect(await getTags.all(directory: d), <String>[]);

          // Add a first two tags
          await addTags(d, ['0a', '0b']);
          expect(await getTags.all(directory: d), ['0b', '0a']);

          // Add another commit
          await updateAndCommitSampleFile(d);
          await addTags(d, ['1a', '1b']);
          expect(await getTags.all(directory: d), ['1b', '1a', '0b', '0a']);

          // From head should still work
          expect(await getTags.fromHead(directory: d), ['1b', '1a']);
        });
      });
    });

    group('run()', () {
      group('with --head-only', () {
        group('should log', () {
          test('the tags of the latest revision', () async {
            await initGit(d);
            addAndCommitSampleFile(d);
            await addTags(d, ['0a', '0b']);

            await updateAndCommitSampleFile(d);
            await addTags(d, ['1a', '1b']);

            final runner = CommandRunner<void>('test', 'test');
            runner.addCommand(GetTags(log: messages.add));
            await runner.run(['get-tags', '--input', d.path, '--head-only']);

            expect(messages.last.split('\n'), ['1b', '1a']);
          });
        });
      });

      group('without --head-only', () {
        group('should log', () {
          test('all historic tags', () async {
            await initGit(d);

            addAndCommitSampleFile(d);
            await addTags(d, ['0b', '0a']);

            await updateAndCommitSampleFile(d);
            await addTags(d, ['1b', '1a']);

            final runner = CommandRunner<void>('test', 'test');
            runner.addCommand(GetTags(log: messages.add));
            await runner.run(['get-tags', '--input', d.path]);

            expect(messages.last.split('\n'), ['1b', '1a', '0b', '0a']);
          });
        });
      });
    });
  });
}
