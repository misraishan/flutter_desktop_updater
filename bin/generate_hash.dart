import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:desktop_updater/src/file_hash.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Platform belirtin: macos, windows, linux');
    exit(1);
  }

  final platform = args[0];

  /// Check if platform is valid
  /// If not, print error and exit
  if (platform != 'macos' && platform != 'windows' && platform != 'linux') {
    print('Platform belirtin: macos, windows, linux');
    exit(1);
  }

  // Go to dist directory and get all folder names
  final distDir = Directory('dist');

  if (!await distDir.exists()) {
    print('dist folder could not be found');
    exit(1);
  }

  /// Sort folders by name, it will be the build number,
  /// and get the last one, biggest build number
  final folders = await distDir.list().toList();
  folders.sort((a, b) => a.path.compareTo(b.path));

  final lastBuildNumberFolder = folders.last;

  // Get all files in the last folder path
  final files = await Directory(lastBuildNumberFolder.path).list().toList();

  bool platformFound = false;
  String? foundFile;

  /// Check if there is a file in given platform
  for (var file in files) {
    // final appName = file.path.split('-').first;
    // final version = file.path.split('-')[1];
    // final buildNumber = file.path.split('-')[2].split('+').first;
    final platform = file.path.split('-').last.split('.').first;

    if (platform == platform) {
      print('File found for platform: $platform');
      platformFound = true;
      foundFile = file.path;
    }
  }

  if (!platformFound || foundFile == null) {
    print('File not found for platform: $platform');
    exit(1);
  }

  /// Check if the file is a zip file
  if (!foundFile.endsWith('.zip')) {
    print('File is not a zip file');
    exit(1);
  }

  // Unzip the file
  // Use an InputFileStream to access the zip file without storing it in memory.
  final inputStream = InputFileStream(foundFile);
  // Decode the zip from the InputFileStream. The archive will have the contents of the
  // zip, without having stored the data in memory.
  final archive = ZipDecoder().decodeStream(inputStream);

  extractArchiveToDisk(archive, '${lastBuildNumberFolder.path}/unzipped');

  genFileHashes(path: '${lastBuildNumberFolder.path}/unzipped');
}
