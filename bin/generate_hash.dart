import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:cryptography_plus/cryptography_plus.dart";
import "package:desktop_updater/src/app_archive.dart";

Future<String> getFileHash(File file) async {
  try {
    // Dosya içeriğini okuyun
    final List<int> fileBytes = await file.readAsBytes();

    // blake2s algoritmasıyla hash hesaplayın

    final hash = await Blake2s().hash(fileBytes);

    // Hash'i utf-8 base64'e dönüştürün ve geri döndürün
    return base64.encode(hash.bytes);
  } catch (e) {
    print("Error reading file ${file.path}: $e");
    return "";
  }
}

Future<String?> genFileHashes({String? directory}) async {
  if (directory == null) {
    throw Exception("Desktop Updater: Executable path is null");
  }

  print("Generating file hashes for $directory");

  final dir = Directory(directory);

  // Eğer belirtilen yol bir dizinse
  if (await dir.exists()) {
    // dir + output.txt dosyası oluşturulur
    final outputFile = File("$directory${Platform.pathSeparator}output.txt");

    // Çıktı dosyasını açıyoruz
    final sink = outputFile.openWrite();

    // Dizin içindeki tüm dosyaları döngüyle okuyoruz
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        // Dosyanın hash'ini al
        final hash = await getFileHash(entity);

        // Dosya yolunu düzenle, başındaki dizin yolu kırpılır
        final path = entity.path.substring(directory.length + 1);

        // Dosya yolunu ve hash değerini yaz
        if (hash.isNotEmpty) {
          final hashObj = FileHashModel(
            filePath: path,
            calculatedHash: hash,
            length: entity.lengthSync(),
          );
          sink.writeln(hashObj.toJson());
        }
      }
    }

    // Çıktıyı kaydediyoruz
    await sink.close();
    return outputFile.path;
  } else {
    throw Exception("Desktop Updater: Directory does not exist");
  }
}

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

  // Go to dist directory and get all folder names
  final distDir = Directory("dist");

  if (!await distDir.exists()) {
    print("dist folder could not be found");
    exit(1);
  }

  /// Sort folders by name, it will be the build number,
  /// and get the last one, biggest build number
  final folders = await distDir.list().toList();
  folders.sort((a, b) => a.path.compareTo(b.path));

  final lastBuildNumberFolder = folders.last;

  // Get all files in the last folder path
  final files = await Directory(lastBuildNumberFolder.path).list().toList();

  var platformFound = false;
  String? foundFile;

  /// Check if there is a file in given platform
  for (final file in files) {
    // final appName = file.path.split('-').first;
    // final version = file.path.split('-')[1];
    // final buildNumber = file.path.split('-')[2].split('+').first;
    final foundPlatform = file.path.split("-").last.split(".").first;

    if (foundPlatform == platform) {
      platformFound = true;
      foundFile = file.path;
    }
  }

  if (!platformFound || foundFile == null) {
    print("File not found for platform: $platform");
    exit(1);
  } else {
    print("Using zip: $foundFile");
  }

  /// Check if the file is a zip file
  if (!foundFile.endsWith(".zip")) {
    print("File is not a zip file");
    exit(1);
  }

  // Unzip the file
  // Use an InputFileStream to access the zip file without storing it in memory.
  final inputStream = InputFileStream(foundFile);
  // Decode the zip from the InputFileStream. The archive will have the contents of the
  // zip, without having stored the data in memory.
  final archive = ZipDecoder().decodeStream(inputStream);

  await extractArchiveToDisk(archive, "${lastBuildNumberFolder.path}/unzipped");

  await genFileHashes(
    directory: "${lastBuildNumberFolder.path}${Platform.pathSeparator}unzipped",
  );

  return;
}
