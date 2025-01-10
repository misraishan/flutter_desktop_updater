/// Class to represent the progress of the update.
class UpdateProgress {
  UpdateProgress({
    required this.totalBytes,
    required this.receivedBytes,
    required this.currentFile,
    required this.totalFiles,
    required this.completedFiles,
  });
  final double totalBytes;
  final double receivedBytes;
  final String currentFile;
  final int totalFiles;
  final int completedFiles;
}
