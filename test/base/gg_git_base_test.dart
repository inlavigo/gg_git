// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_git/src/base/gg_git_base.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

import '../commands/test_helpers.dart';

void main() {
  final messages = <String>[];
  late CommandRunner<void> runner;
  late GgGitCommandExample ggIsCommited;
  late Directory d;

  // ...........................................................................
  void initCommand({GgProcessWrapper? processWrapper}) {
    ggIsCommited = GgGitCommandExample(
      log: messages.add,
      processWrapper: processWrapper ?? const GgProcessWrapper(),
    );
    runner.addCommand(ggIsCommited);
  }

  // ...........................................................................
  setUp(() {
    runner = CommandRunner<void>('test', 'test');
    d = initTestDir();
    messages.clear();
  });

  group('GgGitCommandExample', () {
    // #########################################################################
    group('run(), isCommited()', () {
      group('should throw', () {
        // .....................................................................
        test('if directory does not exist', () async {
          initCommand();
          await expectLater(
            runner.run(['example', '--directory', 'xyz']),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'Directory "xyz" does not exist.',
              ),
            ),
          );
        });

        // .....................................................................
        test('if directory is not a git repository', () async {
          initTestDir();
          initCommand();
          await expectLater(
            runner.run(['example', '--directory', d.path]),
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
    });

    // #########################################################################
    test('should succeed', () async {
      initTestDir();
      await initGit(d);
      initCommand();
      await runner.run(['example', '--directory', d.path]);
      expect(messages, ['Example executed for "test".']);
      expect(exitCode, 0);
    });
  });
}
