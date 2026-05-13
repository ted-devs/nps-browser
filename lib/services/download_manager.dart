import 'package:dio/dio.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();

  /// Downloads a file and reports progress.
  /// 
  /// [url]: The URL to download.
  /// [savePath]: The absolute path where the file will be saved.
  /// [onProgress]: Callback with (receivedBytes, totalBytes).
  /// Returns true if successful.
  Future<bool> downloadFile(String url, String savePath, void Function(int, int) onProgress) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      return true;
    } catch (e) {
      print('Download error: $e');
      return false;
    }
  }

  void cancelDownload() {
    // Basic cancel setup if needed later
  }
}
