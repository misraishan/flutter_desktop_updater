import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print("PLATFORM must be specified: macos, windows, linux");
    exit(1);
  }

  final platform = args[0];

  if (platform != "macos" && platform != "windows" && platform != "linux") {
    print("PLATFORM must be specified: macos, windows, linux");
    exit(1);
  }

  // Get current build name and number from pubspec.yaml
  final pubspec = File("pubspec.yaml");
  final pubspecContent = await pubspec.readAsString();

  // 1.0.0+1
  final buildRegExp =
      RegExp(r"version: (.+)").firstMatch(pubspecContent)!.group(1);

  if (buildRegExp == null) {
    print("version not found in pubspec.yaml");
    exit(1);
  }

  print("Building version ${buildRegExp.replaceAll('"', '')}");

  final buildName = buildRegExp.replaceAll('"', "").split("+").first.trim();
  final buildNumber = buildRegExp.replaceAll('"', "").split("+").last.trim();
  final appNamePubspec =
      RegExp(r"name: (.+)").firstMatch(pubspecContent)!.group(1);

  // Get flutter path
  final flutterPath = Platform.environment["FLUTTER_ROOT"];

  // print current working directory
  print("Current working directory: ${Directory.current.path}");

  // Determine the Flutter executable based on the platform
  var flutterExecutable = "flutter";
  if (Platform.isWindows) {
    flutterExecutable += ".bat";
  }
  if (Platform.isLinux || Platform.isMacOS) {
    flutterExecutable = "flutter";
  }

  final buildCommand = [
    "$flutterPath${Platform.pathSeparator}bin${Platform.pathSeparator}$flutterExecutable",
    "build",
    platform,
    "--dart-define",
    "FLUTTER_BUILD_NAME=$buildName",
    "--dart-define",
    "FLUTTER_BUILD_NUMBER=$buildNumber",
  ];

  // Replace Process.run with Process.start to handle real-time output
  final process =
      await Process.start(buildCommand.first, buildCommand.sublist(1));

  process.stdout.transform(utf8.decoder).listen(print);

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.writeln(data);
  });

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    stderr.writeln("Build failed with exit code $exitCode");
    exit(1);
  }

  print("Build completed");

  late Directory buildDir;

  // Found executable file name in build folder
  if (platform == "windows") {
    buildDir = Directory(
      "build${Platform.pathSeparator}$platform${Platform.pathSeparator}x64${Platform.pathSeparator}runner${Platform.pathSeparator}Release",
    );
  } else if (platform == "macos") {
    buildDir = Directory(
      "build/macos/Build/Products/Release/$appNamePubspec.app",
    );
  }

  // final files = await buildDir.list(recursive: true).toList();

  // Get only last part of the path
  final appName = appNamePubspec;

  final zipPath =
      "dist${Platform.pathSeparator}$buildNumber${Platform.pathSeparator}$appName-$buildName+$buildNumber-$platform.zip";

  // Create zip file with zipPath
  final encoder = ZipFileEncoder()..create(zipPath, level: 0);

  await encoder.addDirectory(
    buildDir,
    includeDirName: true,
  );

  await encoder.close();

  print("Zip created to $zipPath");
}
