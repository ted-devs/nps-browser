import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/psp_game.dart';
import '../services/cover_art_service.dart';
import '../services/download_manager.dart';
import '../services/decryption_service.dart';
import 'package:path/path.dart' as p;

class GameCard extends StatefulWidget {
  final PspGame game;

  const GameCard({Key? key, required this.game}) : super(key: key);

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isDownloading = false;
  bool _isDecrypting = false;
  double _progress = 0.0;
  bool _isDone = false;

  Future<void> _startDownload() async {
    final prefs = await SharedPreferences.getInstance();
    final targetFolder = widget.game.isDlc ? prefs.getString('dlcFolder') : prefs.getString('gameFolder');

    if (!mounted) return;

    if (targetFolder == null || targetFolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please set the ${widget.game.isDlc ? "DLC" : "Game"} Folder in Settings first.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    final tempDir = await getTemporaryDirectory();
    final pkgPath = p.join(tempDir.path, '${widget.game.titleId}.pkg');

    bool success = await DownloadManager().downloadFile(
      widget.game.pkgLink,
      pkgPath,
      (received, total) {
        setState(() {
          _progress = received / total;
        });
      },
    );

    if (success) {
      setState(() {
        _isDownloading = false;
        _isDecrypting = true;
      });

      // Decrypt
      bool decrypted = await DecryptionService().decryptPkg(
        pkgPath,
        targetFolder,
        zrif: widget.game.zrif,
      );

      // Clean up temp pkg
      try { File(pkgPath).deleteSync(); } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isDecrypting = false;
        _isDone = decrypted;
      });

      if (decrypted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.game.name} ready!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Decryption failed!')),
        );
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = CoverArtService.getCoverUrl(widget.game.titleId);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailsDialog(context, coverUrl),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: Icon(Icons.videogame_asset, size: 50, color: Colors.white54)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.game.region, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('${(widget.game.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildAction(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, String coverUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.game.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coverUrl.isNotEmpty) ...[
                Center(
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    height: 150,
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Title ID: ${widget.game.titleId}'),
              const SizedBox(height: 8),
              Text('Region: ${widget.game.region}'),
              const SizedBox(height: 8),
              Text('Content ID: ${widget.game.contentId}'),
              const SizedBox(height: 8),
              Text('Size: ${(widget.game.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
              const SizedBox(height: 8),
              Text('zRIF: ${widget.game.zrif.isNotEmpty ? widget.game.zrif : "None"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (_isDone) {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        radius: 20,
        child: Icon(Icons.check, color: Colors.white),
      );
    }
    if (_isDecrypting) {
      return const CircleAvatar(
        backgroundColor: Colors.orange,
        radius: 20,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }
    if (_isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: _progress, color: Colors.blue),
          Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return InkWell(
      onTap: _startDownload,
      child: const CircleAvatar(
        backgroundColor: Colors.blueAccent,
        radius: 20,
        child: Icon(Icons.download, color: Colors.white),
      ),
    );
  }
}
