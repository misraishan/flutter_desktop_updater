import "dart:async";
import "dart:io";

import "package:desktop_updater/desktop_updater.dart";
import "package:desktop_updater/src/download.dart";
import "package:desktop_updater/src/file_hash.dart";
import "package:http/http.dart" as http;

/// Modified updateAppFunction to return a stream of UpdateProgress.
/// The stream emits total kilobytes, received kilobytes, and the currently downloading file's name.
Future<Stream<UpdateProgress>> updateAppFunction({
  required String remoteUpdateFolder,
}) async {
  final executablePath = Platform.resolvedExecutable;

  final directoryPath = executablePath.substring(
    0,
    executablePath.lastIndexOf(Platform.pathSeparator),
  );

  var dir = Directory(directoryPath);

  if (Platform.isMacOS) {
    dir = dir.parent;
  }

  final responseStream = StreamController<UpdateProgress>();

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

      await newHashFileResponse.stream.listen(
        sink.add,
        onDone: () async {
          await sink.close();
          client.close();
        },
        onError: (e) async {
          await sink.close();
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

      if (changes.isEmpty) {
        print("No updates required.");
        await responseStream.close();
        return responseStream.stream;
      }

      var receivedBytes = 0.0;
      final totalFiles = changes.length;
      var completedFiles = 0;

      // Calculate total length in KB
      final totalLengthKB = changes.fold<double>(
        0,
        (previousValue, element) =>
            previousValue + ((element?.length ?? 0) / 1024.0),
      );

      final changesFutureList = <Future<dynamic>>[];

      for (final file in changes) {
        if (file != null) {
          changesFutureList.add(
            downloadFile(
              remoteUpdateFolder,
              file.filePath,
              dir.path,
              (received, total) {
                receivedBytes += received;
                responseStream.add(
                  UpdateProgress(
                    totalBytes: totalLengthKB,
                    receivedBytes: receivedBytes,
                    currentFile: file.filePath,
                    totalFiles: totalFiles,
                    completedFiles: completedFiles,
                  ),
                );
              },
            ).then((_) {
              completedFiles += 1;

              responseStream.add(
                UpdateProgress(
                  totalBytes: totalLengthKB,
                  receivedBytes: receivedBytes,
                  currentFile: file.filePath,
                  totalFiles: totalFiles,
                  completedFiles: completedFiles,
                ),
              );
              print("Completed: ${file.filePath}");
            }).catchError((error) {
              responseStream.addError(error);
              return null;
            }),
          );
        }
      }

      unawaited(
        Future.wait(changesFutureList).then((_) async {
          await responseStream.close();
        }),
      );

      return responseStream.stream;
    }
  } catch (e) {
    responseStream.addError(e);
    await responseStream.close();
  }

  return responseStream.stream;
}
