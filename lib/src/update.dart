import "dart:async";
import "dart:io";

import "package:desktop_updater/desktop_updater.dart";
import "package:desktop_updater/src/download.dart";
import "package:desktop_updater/src/file_hash.dart";
import "package:http/http.dart" as http;

/// Modified updateAppFunction to return a stream of UpdateProgress.
/// The stream emits total bytes, received bytes, and the currently downloading file's name.
Future<Stream<UpdateProgress>> updateAppFunction({
  required String remoteUpdateFolder,
}) async {
  final executablePath = await DesktopUpdater().getExecutablePath();

  final directoryPath = executablePath?.substring(
    0,
    executablePath.lastIndexOf(Platform.pathSeparator),
  );

  if (directoryPath == null) {
    throw Exception("Desktop Updater: Executable path is null");
  }

  var dir = Directory(directoryPath);

  if (Platform.isMacOS) {
    dir = dir.parent;
  }

  final responseStream = StreamController<UpdateProgress>();
  final downloadFutures = <Future<void>>[];
  var totalBytes = 0;
  var receivedBytes = 0;
  var totalFiles = 0;
  var completedFiles = 0;

  try {
    if (await dir.exists()) {
      final tempDir = await Directory.systemTemp.createTemp("desktop_updater");

      final client = http.Client();

      final newHashFileUrl = "$remoteUpdateFolder/hashes.json";
      final newHashFileRequest = http.Request("GET", Uri.parse(newHashFileUrl));
      final newHashFileResponse = await client.send(newHashFileRequest);

      if (newHashFileResponse.statusCode != 200) {
        client.close();
        throw const HttpException("Failed to download hashes.json");
      }

      final outputFile =
          File("${tempDir.path}${Platform.pathSeparator}hashes.json");
      final sink = outputFile.openWrite();
      var received = 0;
      final contentLength = newHashFileResponse.contentLength ?? 0;

      await newHashFileResponse.stream.listen(
        (List<int> chunk) {
          received += chunk.length;
          sink.add(chunk);
          if (contentLength != 0) {
            // final progress = received / contentLength;
            responseStream.add(
              UpdateProgress(
                totalBytes: contentLength,
                receivedBytes: received,
                currentFile: "hashes.json",
                totalFiles: totalFiles,
                completedFiles: completedFiles,
              ),
            );
          }
        },
        onDone: () async {
          await sink.close();
          client.close();
          print("Hashes file downloaded to ${outputFile.path}");
        },
        onError: (e) {
          sink.close();
          client.close();
          throw e;
        },
        cancelOnError: true,
      ).asFuture();

      final oldHashFilePath = await genFileHashes();
      final newHashFilePath = outputFile.path;

      print("Old hashes file: $oldHashFilePath");

      final changes = await verifyFileHashes(
        oldHashFilePath,
        newHashFilePath,
      );

      print("Changes: ${changes.length} files");

      totalFiles = changes.length;
      final totalLength = changes.fold<int>(
        0,
        (previousValue, element) => previousValue + (element?.length ?? 0),
      );

      // Calculate total bytes to download
      for (final file in changes) {
        if (file != null) {
          final fileUrl = "$remoteUpdateFolder/${file.filePath}";
          final headResponse = await client.head(Uri.parse(fileUrl));
          if (headResponse.statusCode == 200 &&
              headResponse.headers.containsKey("content-length")) {
            totalBytes += int.parse(headResponse.headers["content-length"]!);
          }
        }
      }

      for (final file in changes) {
        if (file != null) {
          downloadFutures.add(
            downloadFile(
              remoteUpdateFolder,
              file.filePath,
              dir.path,
              (received, total) {
                receivedBytes += received;
                responseStream.add(
                  UpdateProgress(
                    totalBytes: totalLength,
                    receivedBytes: receivedBytes,
                    currentFile: file.filePath,
                    totalFiles: totalFiles,
                    completedFiles: completedFiles,
                  ),
                );
              },
            ).then((_) {
              completedFiles += 1;
              print("Completed: ${file.filePath}");
            }).catchError((error) {
              responseStream.addError(error);
              return null;
            }),
          );
        }
      }

      await Future.wait(downloadFutures);
      await responseStream.close();
    }

    await responseStream.close();
  } catch (e) {
    responseStream.addError(e);
    await responseStream.close();
  }

  return responseStream.stream;
}
