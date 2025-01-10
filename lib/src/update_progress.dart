/// Class to represent the progress of the update.
class UpdateProgress {
  UpdateProgress({
    required this.totalBytes,
    required this.receivedBytes,
    required this.currentFile,
    required this.totalFiles,
    required this.completedFiles,
  });
  final int totalBytes;
  final int receivedBytes;
  final String currentFile;
  final int totalFiles;
  final int completedFiles;
}
