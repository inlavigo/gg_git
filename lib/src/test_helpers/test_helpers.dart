// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_git/gg_git.dart';
import 'package:gg_is_github/gg_is_github.dart';

// coverage:ignore-file

// .............................................................................
/// Initializes a test directory
Future<Directory> initTestDir() async {
  final tmpBase = await Directory('/tmp').exists()
      ? Directory('/tmp')
      : Directory.systemTemp;

  final tmp = await tmpBase.createTemp('gg_git_test');

  final testDir = Directory('${tmp.path}/test');
  if (await testDir.exists()) {
    await testDir.delete(recursive: true);
  }
  await testDir.create(recursive: true);

  return testDir;
}

// ######################
// Init Git Repos
// ######################

// .............................................................................
/// Init git repository in test directory
Future<void> initGit(Directory testDir) async => initLocalGit(testDir);

// .............................................................................
/// Init local git repository in directory
Future<void> initLocalGit(Directory testDir) async {
  _setupGitHub(testDir);

  final localDir = testDir;

  final result = await Process.run(
    'git',
    ['init', '--initial-branch=main'],
    workingDirectory: localDir.path,
  );
  if (result.exitCode != 0) {
    throw Exception('Could not initialize local git repository.');
  }

  final result2 = await Process.run(
    'git',
    ['checkout', '-b', 'main'],
    workingDirectory: localDir.path,
  );

  if (result2.exitCode != 0) {
    throw Exception('Could not create main branch.');
  }
}

// .............................................................................
/// Init remote git repository in directory
Future<void> initRemoteGit(Directory testDir) async {
  final remoteDir = testDir;
  await remoteDir.create(recursive: true);
  final result = await Process.run(
    'git',
    ['init', '--bare', '--initial-branch=main'],
    workingDirectory: remoteDir.path,
  );
  if (result.exitCode != 0) {
    throw Exception('Could not initialize remote git repository.');
  }
}

// ...........................................................................
/// Adds a remote git repo to a local git repo
Future<void> addRemoteToLocal({
  required Directory local,
  required Directory remote,
}) async {
  // Add remote
  final result2 = await Process.run(
    'git',
    [
      'remote',
      'add',
      'origin',
      remote.path,
    ],
    workingDirectory: local.path,
  );

  if (result2.exitCode != 0) {
    throw Exception(
      'Could not add remote to local git repository. ${result2.stderr}',
    );
  }

  final result3 = await Process.run(
    'git',
    [
      'push',
      '--set-upstream',
      'origin',
      'main',
    ],
    workingDirectory: local.path,
  );

  if (result3.exitCode != 0) {
    throw Exception('Could not set up-stream. ${result3.stderr}');
  }
}

// .............................................................................
void _setupGitHub(Directory testDir) async {
  if (isGitHub) {
    final result2 = await Process.run(
      'git',
      ['config', '--global', 'user.email', 'githubaction@inlavigo.com'],
      workingDirectory: testDir.path,
    );

    if (result2.exitCode != 0) {
      throw Exception('Could not set mail. ${result2.stderr}');
    }

    final result3 = await Process.run(
      'git',
      ['config', '--global', 'user.name', 'Github Action'],
      workingDirectory: testDir.path,
    );

    if (result3.exitCode != 0) {
      throw Exception('Could not set mail. ${result3.stderr}');
    }
  }
}

// ######################
// Git Ignore
// ######################

// .............................................................................
/// Adds a gitignore file to the test directory
Future<void> addAndCommitGitIgnoreFile(
  Directory d, {
  String content = '',
}) =>
    addAndCommitSampleFile(d, fileName: '.gitignore', content: content);

// #############
// # Tag helpers
// #############

/// Add tag to test directory
Future<void> addTag(Directory testDir, String tag) async {
  final result = await Process.run(
    'git',
    ['tag', tag],
    workingDirectory: testDir.path,
  );
  if (result.exitCode != 0) {
    throw Exception('Could not add tag $tag.');
  }
}

/// Add tags to test directory
Future<void> addTags(Directory testDir, List<String> tags) async {
  for (final tag in tags) {
    await addTag(testDir, tag);
  }
}

// ##############
// # File helpers
// ##############

// .............................................................................
/// Init a file with a name in the test directory
Future<File> addFileWithoutCommitting(
  Directory testDir, {
  String fileName = 'test.txt',
  String content = 'Content',
}) async {
  final result = File('${testDir.path}/$fileName');
  await result.writeAsString(content);
  return result;
}

// .............................................................................
/// Commit the file with a name in the test directory
Future<void> commitFile(
  Directory testDir,
  String fileName, {
  String message = 'Commit Message',
}) async {
  await stageFile(testDir, fileName);

  final result2 = await Process.run(
    'git',
    ['commit', '-m', message],
    workingDirectory: testDir.path,
  );
  if (result2.exitCode != 0) {
    throw Exception('Could not commit $fileName.');
  }
}

// .............................................................................
/// Commit the file with a name in the test directory
Future<void> stageFile(
  Directory testDir,
  String fileName,
) async {
  final result = await Process.run(
    'git',
    ['add', fileName],
    workingDirectory: testDir.path,
  );
  if (result.exitCode != 0) {
    throw Exception('Could not add $fileName.');
  }
}

// .............................................................................
/// Returns a list of modified files in the directory
Future<List<String>> modifiedFiles(Directory directory) {
  return ModifiedFiles(
    ggLog: print,
  ).get(directory: directory, ggLog: print);
}

// ## sample.txt

/// The name of the sample file
const String sampleFileName = 'test.txt';

// .............................................................................
/// Add and commit sample file
Future<File> addAndCommitSampleFile(
  Directory testDir, {
  String fileName = sampleFileName,
  String content = 'sample',
  String message = 'Commit Message',
}) async {
  final file = await addFileWithoutCommitting(
    testDir,
    fileName: fileName,
    content: content,
  );
  await commitFile(testDir, fileName, message: message);
  return file;
}

// .............................................................................
/// Update and commit sample file
Future<void> updateSampleFileWithoutCommitting(
  Directory testDir, {
  String fileName = sampleFileName,
  String message = 'Commit Message',
}) async {
  final file = File('${testDir.path}/$fileName');
  final content = await file.exists() ? file.readAsString() : '';
  final newContent = '${content}updated';
  await File('${testDir.path}/sample.txt').writeAsString(newContent);
}

// .............................................................................
/// Update and commit sample file
Future<void> updateAndCommitSampleFile(
  Directory testDir, {
  String message = 'Commit Message',
  String fileName = sampleFileName,
}) async {
  final file = File('${testDir.path}/$fileName');
  final content = await file.exists() ? file.readAsString() : '';
  final newContent = '${content}updated';
  await File('${testDir.path}/sample.txt').writeAsString(newContent);
  await commitFile(testDir, sampleFileName, message: message);
}

// ## uncommitted.txt

// .............................................................................
/// Init uncommitted file
Future<void> initUncommittedFile(
  Directory testDir, {
  String fileName = 'uncommitted.txt',
  String content = 'uncommitted',
}) =>
    addFileWithoutCommitting(testDir, fileName, content);

// ## pubspect.yaml

// .............................................................................
/// Create a pubspec.yaml file with a version
Future<void> setPubspec(Directory testDir, {required String? version}) async {
  final file = File('${testDir.path}/pubspec.yaml');

  var content = await file.exists()
      ? await file.readAsString()
      : 'name: test\nversion: $version\n';

  if (version == null) {
    content = content.replaceAll(RegExp(r'version: .*'), '');
  } else {
    content = content.replaceAll(RegExp(r'version: .*'), 'version: $version');
  }

  await file.writeAsString(content);
}

// .............................................................................
/// Commit the pubspec file
Future<void> commitPubspec(Directory testDir) =>
    commitFile(testDir, 'pubspec.yaml');

// ## CHANGELOG.md

// .............................................................................
/// Create a CHANGELOG.md file with a version
Future<void> setChangeLog(
  Directory testDir, {
  required String? version,
}) async {
  var content = '# Change log\n\n';
  if (version != null) {
    content += '## $version\n\n';
  }

  await addFileWithoutCommitting(testDir, 'CHANGELOG.md', content);
}

// .............................................................................
/// Commit the changelog file
Future<void> commitChangeLog(Directory testDir) =>
    commitFile(testDir, 'CHANGELOG.md');

// ## Version files

// .............................................................................
/// Write version into pubspec.yaml, Changelog.md and add a tag
Future<void> setupVersions(
  Directory testDir, {
  required String? pubspec,
  required String? changeLog,
  required String? gitHead,
}) async {
  await setPubspec(testDir, version: pubspec);
  await commitPubspec(testDir);
  await setChangeLog(testDir, version: changeLog);
  await commitChangeLog(testDir);

  if (gitHead != null) {
    await addTag(testDir, gitHead);
  }
}
