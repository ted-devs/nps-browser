import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/psp_game.dart';

enum DownloadStatus { pending, downloading, decrypting, completed, error, cancelled }

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

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      game: PspGame.fromJson(json['game']),
      status: DownloadStatus.values.firstWhere((e) => e.toString() == json['status']),
      progress: json['progress'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game': game.toJson(),
      'status': status.toString(),
      'progress': progress,
      'error': error,
    };
  }
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  
  final List<DownloadTask> _tasks = [];
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadManager._internal() {
    _loadTasks();
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
          case 'cancelled':
            task.status = DownloadStatus.cancelled;
            break;
        }
        notifyListeners();
        _saveTasks();
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
    _saveTasks();

    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) {
      await service.startService();
      // Wait for the service isolate to start and register listeners
      await Future.delayed(const Duration(seconds: 1));
    }

    service.invoke('addDownload', {
      'titleId': game.titleId,
      'name': game.name,
      'pkgLink': game.pkgLink,
      'zrif': game.zrif,
    });
  }

  void cancelDownload(String titleId) {
    _tasks.removeWhere((t) => t.game.titleId == titleId);
    notifyListeners();
    _saveTasks();
    FlutterBackgroundService().invoke('cancelDownload', {'titleId': titleId});
  }
  
  void clearCompleted() {
    _tasks.removeWhere((t) => 
      t.status == DownloadStatus.completed || 
      t.status == DownloadStatus.error || 
      t.status == DownloadStatus.cancelled
    );
    notifyListeners();
    _saveTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('download_tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks.clear();
      _tasks.addAll(decoded.map((t) => DownloadTask.fromJson(t)).toList());
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('download_tasks', encoded);
  }
}
