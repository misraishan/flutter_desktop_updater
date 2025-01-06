import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:desktop_updater/desktop_updater_platform_interface.dart';

Future<String> getFileHash(File file) async {
  try {
    // Dosya içeriğini okuyun
    List<int> fileBytes = await file.readAsBytes();
    
    // blake2s algoritmasıyla hash hesaplayın

    final hash = await Blake2s().hash(fileBytes);

    // Hash'i utf-8 base64'e dönüştürün ve geri döndürün
    return base64.encode(hash.bytes);
  } catch (e) {
    print("Error reading file ${file.path}: $e");
    return "";
  }
}

verifyFileHash(File file, String expectedHash) async {
  // Dosyanın hash'ini al
  String hash = await getFileHash(file);

  // Hash'ler eşleşiyorsa
  if (hash == expectedHash) {
    print('${file.path} hash matches');
  } else {
    print('${file.path} hash does not match');
  }
}

// Dizin içindeki tüm dosyaların hash'lerini alıp bir dosyaya yazan fonksiyon
Future<void> genFileHashes() async {
  final executablePath = await DesktopUpdaterPlatform.instance.getExecutablePath();

  // .exe'yi ve dosya adını sil sadece path'i getir
  final directoryPath = executablePath?.substring(0, executablePath.lastIndexOf(Platform.pathSeparator));
  
  print(directoryPath);

  if (directoryPath == null) {
    print("Executable path not found");
    return;
  }

  final dir = Directory(directoryPath);
  
  // Eğer belirtilen yol bir dizinse
  if (await dir.exists()) {
    // dir + output.txt dosyası oluşturulur
    File outputFile = File('${dir.path}${Platform.pathSeparator}output.txt');
    
    // Çıktı dosyasını açıyoruz
    IOSink sink = outputFile.openWrite();

    // Dizin içindeki tüm dosyaları döngüyle okuyoruz
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        // Dosyanın hash'ini al
        String hash = await getFileHash(entity);

        // Dosya yolunu düzenle, başındaki dizin yolu kırpılır
        final path = entity.path.substring(directoryPath.length + 1);

        // Dosya yolunu ve hash değerini yaz
        if (hash.isNotEmpty) {
          sink.writeln('$path $hash');
        }
      }
    }

    // Çıktıyı kaydediyoruz
    await sink.close();
    print('Hashes have been written to ${outputFile.path}');
;
  } else {
    print("Directory not found at $directoryPath");
  }
}
