import "dart:io";

import "package:http/http.dart" as http;
import "package:path/path.dart" as path;

/// Modified downloadFile to report progress.
/// [progressCallback] receives two integers: bytes received and total bytes.
Future<void> downloadFile(
  String? host,
  String filePath,
  String savePath,
  void Function(int received, int total)? progressCallback,
) async {
  if (host == null) return;

  final client = http.Client();
  final url = "$host/$filePath";
  final request = http.Request("GET", Uri.parse(url));
  final response = await client.send(request);

  if (response.statusCode != 200) {
    client.close();
    throw HttpException("Failed to download file: $url");
  }

  // Create full save path including directories
  final fullSavePath = path.join("$savePath/update", filePath);
  final saveDirectory = Directory(path.dirname(fullSavePath));

  // Create all necessary directories
  if (!saveDirectory.existsSync()) {
    await saveDirectory.create(recursive: true);
  }

  // Save the file with progress reporting
  final file = File(fullSavePath);
  final sink = file.openWrite();
  var received = 0;
  final contentLength = response.contentLength ?? 0;

  await response.stream.listen(
    (List<int> chunk) {
      received += chunk.length;
      sink.add(chunk);
      if (progressCallback != null && contentLength != 0) {
        progressCallback(received, contentLength);
      }
    },
    onDone: () async {
      await sink.close();
      client.close();
      print("File downloaded to $fullSavePath");
    },
    onError: (e) {
      sink.close();
      client.close();
      throw e;
    },
    cancelOnError: true,
  ).asFuture();
}
