import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/psp_game.dart';
import 'decryption_service.dart';

enum DownloadStatus { pending, downloading, decrypting, completed, error }

class DownloadTask {
  final PspGame game;
  DownloadStatus status;
  double progress;
  String? error;

  DownloadTask({
    required this.game,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.error,
  });
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  final List<DownloadTask> _tasks = [];

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  void addDownload(PspGame game) {
    // Check if already in tasks
    if (_tasks.any((t) => t.game.titleId == game.titleId && t.status != DownloadStatus.error)) {
      return;
    }

    final task = DownloadTask(game: game, status: DownloadStatus.pending);
    _tasks.add(task);
    notifyListeners();

    _startDownload(task);
  }

  Future<void> _startDownload(DownloadTask task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetFolder = task.game.isDlc ? prefs.getString('dlcFolder') : prefs.getString('gameFolder');

      if (targetFolder == null || targetFolder.isEmpty) {
        task.status = DownloadStatus.error;
        task.error = 'No output folder set in Settings.';
        notifyListeners();
        return;
      }

      task.status = DownloadStatus.downloading;
      task.progress = 0.0;
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final pkgPath = p.join(tempDir.path, '${task.game.titleId}.pkg');

      await _dio.download(
        task.game.pkgLink,
        pkgPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.progress = received / total;
            notifyListeners();
          }
        },
        options: Options(responseType: ResponseType.bytes, followRedirects: true),
      );

      task.status = DownloadStatus.decrypting;
      notifyListeners();

      bool decrypted = await DecryptionService().decryptPkg(
        pkgPath,
        targetFolder,
        zrif: task.game.zrif,
      );

      // Clean up temp pkg
      try { File(pkgPath).deleteSync(); } catch (_) {}

      if (decrypted) {
        task.status = DownloadStatus.completed;
      } else {
        task.status = DownloadStatus.error;
        task.error = 'Decryption failed.';
      }
      notifyListeners();
    } catch (e) {
      task.status = DownloadStatus.error;
      task.error = e.toString();
      notifyListeners();
    }
  }

  void cancelDownload() {
    // Not implemented yet
  }
}
