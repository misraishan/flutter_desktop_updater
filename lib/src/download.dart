import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as path;

Future<void> downloadFile(
  String? host,
  String filePath,
  String savePath,
) async {
  if (host == null) return;

  final client = http.Client();
  final url = "$host/$filePath";
  final request = http.Request("GET", Uri.parse(url));
  final response = await client.send(request);

  // Create full save path including directories
  final fullSavePath = path.join("$savePath/update", filePath);
  final saveDirectory = Directory(path.dirname(fullSavePath));

  // Create all necessary directories
  if (!saveDirectory.existsSync()) {
    await saveDirectory.create(recursive: true);
  }

  // Save the file
  final file = File(fullSavePath);
  await response.stream.pipe(file.openWrite());
  client.close();

  print("File downloaded to $fullSavePath");
}
