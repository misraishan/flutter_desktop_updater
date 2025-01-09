import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cryptography_plus/cryptography_plus.dart";
import "package:desktop_updater/desktop_updater.dart";
import "package:desktop_updater/src/app_archive.dart";

Future<String> getFileHash(File file) async {
  try {
    // Dosya içeriğini okuyun
    final List<int> fileBytes = await file.readAsBytes();

    // blake2s algoritmasıyla hash hesaplayın

    final hash = await Blake2b().hash(fileBytes);

    // Hash'i utf-8 base64'e dönüştürün ve geri döndürün
    return base64.encode(hash.bytes);
  } catch (e) {
    print("Error reading file ${file.path}: $e");
    return "";
  }
}

Future<bool> verifyFileHash(File file, String expectedHash) async {
  // Dosyanın hash'ini al
  final hash = await getFileHash(file);

  // Hash'ler eşleşiyorsa
  if (hash == expectedHash) {
    return true;
  } else {
    return false;
  }
}

// Dizin içindeki tüm dosyaların hash'lerini alıp bir dosyaya yazan fonksiyon
Future<String?> genFileHashes({String? path}) async {
  path ??= await DesktopUpdater().getExecutablePath();

  final directoryPath =
      path?.substring(0, path.lastIndexOf(Platform.pathSeparator));

  if (directoryPath == null) {
    throw Exception("Desktop Updater: Executable path is null");
  }

  var dir = Directory(directoryPath);
  
  if (Platform.isMacOS) {
    dir = dir.parent;
  }

  print("Generating file hashes for ${dir.path}");

  // Eğer belirtilen yol bir dizinse
  if (await dir.exists()) {
    // dir + output.txt dosyası oluşturulur
    final outputFile = File("${dir.path}${Platform.pathSeparator}hashes.json");

    // Çıktı dosyasını açıyoruz
    final sink = outputFile.openWrite();

    // Dizin içindeki tüm dosyaları döngüyle okuyoruz
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        // Dosyanın hash'ini al
        final hash = await getFileHash(entity);

        final foundPath = entity.path.substring(dir.path.length + 1);
  
        // Dosya yolunu ve hash değerini yaz
        if (hash.isNotEmpty) {
          final hashObj = FileHashModel(
            filePath: foundPath,
            calculatedHash: hash,
            length: entity.lengthSync(),
          );
          // Stringify json
          final jsonString = jsonEncode(hashObj.toJson());
          sink.writeln(jsonString);
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
