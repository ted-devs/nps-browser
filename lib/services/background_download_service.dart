import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import 'decryption_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'download_channel', // id
    'Downloads', // name
    description: 'Ongoing downloads and decryption',
    importance: Importance
        .low, // low importance so it doesn't make a sound every update
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'download_channel',
      initialNotificationTitle: 'NPS Browser Service',
      initialNotificationContent: 'Downloading games...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  DecryptionService().initialize();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final Map<String, CancelToken> activeTokens = {};

  service.on('cancelDownload').listen((event) {
    final titleId = event?['titleId'] as String?;
    if (titleId != null && activeTokens.containsKey(titleId)) {
      activeTokens[titleId]?.cancel();
      activeTokens.remove(titleId);
      service.invoke('update', {
        'titleId': titleId,
        'status': 'cancelled',
      });
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Download Cancelled',
          content: 'The download was stopped.',
        );
      }
      
      // Auto-stop if queue is empty
      if (activeTokens.isEmpty) {
        service.stopSelf();
      }
    }
  });

  service.on('addDownload').listen((event) async {
    if (event == null) return;

    final titleId = event['titleId'] as String;
    final name = event['name'] as String;
    final pkgLink = event['pkgLink'] as String;
    final zrif = event['zrif'] as String;

    print('Background Service: Received addDownload for $name ($titleId)');

    final prefs = await SharedPreferences.getInstance();
    final targetFolder = prefs.getString('game_folder');

    if (targetFolder == null || targetFolder.isEmpty) {
      service.invoke('update', {
        'titleId': titleId,
        'status': 'error',
        'error': 'No output folder set.',
      });
      return;
    }

    try {
      final dio = Dio();
      final cancelToken = CancelToken();
      activeTokens[titleId] = cancelToken;

      final tempDir = await getTemporaryDirectory();
      final pkgPath = p.join(tempDir.path, '$titleId.pkg');

      service.invoke('update', {
        'titleId': titleId,
        'status': 'downloading',
        'progress': 0.0,
      });
      await _updateTaskStatusInStorage(titleId, 'downloading', progress: 0.0);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Downloading $name',
          content: '0%',
        );
      }

      int lastUpdate = DateTime.now().millisecondsSinceEpoch;
      double lastProgress = 0.0;

      int retryCount = 0;
      bool success = false;
      
      while (retryCount < 3 && !success) {
        try {
          await dio.download(
            pkgLink,
            pkgPath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                double progress = received / total;
                int now = DateTime.now().millisecondsSinceEpoch;

                if (now - lastUpdate > 1000 ||
                    (progress - lastProgress).abs() > 0.05 ||
                    progress == 1.0) {
                  lastUpdate = now;
                  lastProgress = progress;

                  service.invoke('update', {
                    'titleId': titleId,
                    'status': 'downloading',
                    'progress': progress,
                  });

                  if (service is AndroidServiceInstance) {
                    service.setForegroundNotificationInfo(
                      title: 'Downloading $name',
                      content: '${(progress * 100).toInt()}%',
                    );
                  }
                }
              }
            },
            options: Options(
              followRedirects: true,
              receiveTimeout: const Duration(minutes: 5),
            ),
            cancelToken: cancelToken,
          );
          success = true;
        } catch (e) {
          if (e is DioException && e.type == DioExceptionType.cancel) {
            rethrow;
          }
          retryCount++;
          if (retryCount >= 3) rethrow;
          print('Download failed, retrying ($retryCount/3): $e');
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      activeTokens.remove(titleId);

      service.invoke('update', {'titleId': titleId, 'status': 'decrypting'});
      await _updateTaskStatusInStorage(titleId, 'decrypting');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Extracting $name',
          content: 'Decrypting...',
        );
      }

      bool decrypted = await DecryptionService().decryptPkg(
        pkgPath,
        targetFolder,
        zrif: zrif,
      );

      if (decrypted) {
        service.invoke('update', {'titleId': titleId, 'status': 'completed'});
        await _updateTaskStatusInStorage(titleId, 'completed');
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: '$name Downloaded',
            content: 'Ready to play',
          );
        }
      } else {
        service.invoke('update', {
          'titleId': titleId,
          'status': 'error',
          'error': 'Decryption failed.',
        });
        await _updateTaskStatusInStorage(titleId, 'error', error: 'Decryption failed.');
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: '$name Error',
            content: 'Decryption failed',
          );
        }
      }
    } catch (e) {
      activeTokens.remove(titleId);
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return;
      }
      service.invoke('update', {
        'titleId': titleId,
        'status': 'error',
        'error': e.toString(),
      });
      await _updateTaskStatusInStorage(titleId, 'error', error: e.toString());
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Download Error',
          content: e.toString(),
        );
      }
    } finally {
      // Robust cleanup of the temporary PKG file
      try {
        final tempDir = await getTemporaryDirectory();
        final pkgPath = p.join(tempDir.path, '$titleId.pkg');
        final file = File(pkgPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      
      // Auto-stop service if no more active downloads
      if (activeTokens.isEmpty) {
        service.stopSelf();
      }
    }
  });
}

Future<void> _updateTaskStatusInStorage(String titleId, String status, {double? progress, String? error}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('download_tasks');
    if (tasksJson != null) {
      final List<dynamic> tasks = jsonDecode(tasksJson);
      for (var task in tasks) {
        if (task['game']['titleId'] == titleId) {
          task['status'] = 'DownloadStatus.$status';
          if (progress != null) task['progress'] = progress;
          if (error != null) task['error'] = error;
          break;
        }
      }
      await prefs.setString('download_tasks', jsonEncode(tasks));
    }
  } catch (e) {
    print('Error updating task in storage: $e');
  }
}

