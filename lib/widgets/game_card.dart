import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/psp_game.dart';
import '../services/cover_art_service.dart';
import '../services/download_manager.dart';

class GameCard extends StatefulWidget {
  final PspGame game;

  const GameCard({Key? key, required this.game}) : super(key: key);

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  @override
  Widget build(BuildContext context) {
    final coverUrl = CoverArtService.getCoverUrl(widget.game.titleId);

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailsDialog(context, coverUrl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[800],
                child: const Center(child: Icon(Icons.videogame_asset, size: 50, color: Colors.white54)),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.game.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(0, 2))],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.game.region,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
            onPressed: () {
              Navigator.pop(context);
              DownloadManager().addDownload(widget.game);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download added to queue')),
              );
            },
            child: const Text('Download'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

