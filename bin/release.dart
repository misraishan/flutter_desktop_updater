import 'dart:io';

import 'package:archive/archive_io.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print("PLATFORM must be specified: macos, windows, linux");
    exit(1);
  }

  final platform = args[0];

  if (platform != 'macos' && platform != 'windows' && platform != 'linux') {
    print("PLATFORM must be specified: macos, windows, linux");
    exit(1);
  }

  // Get current build name and number from pubspec.yaml
  final pubspec = File('pubspec.yaml');
  final pubspecContent = await pubspec.readAsString();
  
  // 1.0.0+1
  final buildRegExp = RegExp(r'version: (.+)').firstMatch(pubspecContent)!.group(1);
  final buildName = buildRegExp?.split('+').first;
  final buildNumber = buildRegExp?.split('+').last;

  final buildCommand = [
    'flutter',
    'build',
    platform,
    '--dart-define',
    'FLUTTER_BUILD_NAME=$buildName',
    '--dart-define',
    'FLUTTER_BUILD_NUMBER=$buildNumber'
  ];

  final result = await Process.run(buildCommand[0], buildCommand.sublist(1));
  if (result.exitCode != 0) {
    print("Build failed with exit code ${result.exitCode}");
    exit(1);
  }

  // Found executable file name in build folder
  final buildDir = Directory('build/$platform/x64/runner/Release');
  final files = await buildDir.list().toList();
  final file = files.firstWhere((file) => file.path.endsWith('.exe'));

  final appName = file.path.split('/').last.split('.').first;

  final buildPath = 'build/$platform/x64/runner/Release';
  final zipPath = 'dist/$buildNumber/$appName-$platform-x64.zip';

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  encoder.addDirectory(Directory(buildPath), includeDirName: false);
  encoder.close();

  print("Zip created to $zipPath");
}