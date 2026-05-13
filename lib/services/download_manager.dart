import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/psp_game.dart';

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
  
  final List<DownloadTask> _tasks = [];
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadManager._internal() {
    FlutterBackgroundService().on('update').listen((event) {
      if (event == null) return;
      
      final titleId = event['titleId'];
      final statusStr = event['status'];
      final progressRaw = event['progress'];
      final progress = progressRaw != null ? (progressRaw as num).toDouble() : null;
      final error = event['error'] as String?;

      try {
        final task = _tasks.firstWhere((t) => t.game.titleId == titleId);
        
        switch (statusStr) {
          case 'downloading':
            task.status = DownloadStatus.downloading;
            if (progress != null) task.progress = progress;
            break;
          case 'decrypting':
            task.status = DownloadStatus.decrypting;
            break;
          case 'completed':
            task.status = DownloadStatus.completed;
            break;
          case 'error':
            task.status = DownloadStatus.error;
            task.error = error;
            break;
        }
        notifyListeners();
      } catch (e) {
        // Task not found in memory (could be app restarted while downloading)
        // Advanced: Re-construct task if needed, but for now we ignore.
      }
    });
  }

  void addDownload(PspGame game) async {
    if (_tasks.any((t) => t.game.titleId == game.titleId && t.status != DownloadStatus.error && t.status != DownloadStatus.completed)) {
      return;
    }

    final task = DownloadTask(game: game, status: DownloadStatus.pending);
    // Remove old task if it was an error or completed to restart
    _tasks.removeWhere((t) => t.game.titleId == game.titleId);
    _tasks.add(task);
    notifyListeners();

    FlutterBackgroundService().invoke('addDownload', {
      'titleId': game.titleId,
      'name': game.name,
      'pkgLink': game.pkgLink,
      'zrif': game.zrif,
    });
  }

  void cancelDownload() {
    // Not implemented yet
  }
}
