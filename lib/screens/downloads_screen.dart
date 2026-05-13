import 'package:flutter/material.dart';
import '../services/download_manager.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Finished',
            onPressed: () => DownloadManager().clearCompleted(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: DownloadManager(),
        builder: (context, child) {
          final tasks = DownloadManager().tasks;
          
          if (tasks.isEmpty) {
            return const Center(
              child: Text('No active downloads.'),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: const Icon(Icons.download),
                title: Text(task.game.name),
                subtitle: _buildSubtitle(task),
                trailing: _buildTrailing(task),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubtitle(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.pending:
        return const Text('Pending...');
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloading... ${(task.progress * 100).toInt()}%'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: task.progress),
          ],
        );
      case DownloadStatus.decrypting:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Decrypting & Extracting...'),
            SizedBox(height: 4),
            LinearProgressIndicator(),
          ],
        );
      case DownloadStatus.completed:
        return const Text('Completed');
      case DownloadStatus.cancelled:
        return const Text('Cancelled', style: TextStyle(color: Colors.orange));
      case DownloadStatus.error:
        return Text('Error: ${task.error}', style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildTrailing(DownloadTask task) {
    switch (task.status) {
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.orange);
      default:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => DownloadManager().cancelDownload(task.game.titleId),
        );
    }
  }
}
