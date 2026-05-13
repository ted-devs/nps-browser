import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/psp_game.dart';
import '../services/cover_art_service.dart';
import '../services/download_manager.dart';
import '../services/game_description_service.dart';

class GameDetailsScreen extends StatelessWidget {
  final PspGame game;

  const GameDetailsScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coverUrl = CoverArtService.getCoverUrl(game.titleId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                game.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: GestureDetector(
                onTap: () => _showFullScreenImage(context, coverUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'cover_${game.titleId}_${game.region}',
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Center(child: Icon(Icons.videogame_asset, size: 80, color: Colors.white54)),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Description'),
                    const SizedBox(height: 8),
                    FutureBuilder<String?>(
                      future: GameDescriptionService.getDescription(game.name),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || snapshot.data == null) {
                          return const Text(
                            'Description not found.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          );
                        }
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Game Information'),
                    const SizedBox(height: 16),
                    _buildDetailRow('Title ID', game.titleId),
                    _buildDetailRow('Region', game.region),
                    _buildDetailRow('Content ID', game.contentId),
                    _buildDetailRow('File Size', '${(game.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: FloatingActionButton.extended(
            onPressed: () {
              DownloadManager().addDownload(game);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${game.name}" added to queue'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'DOWNLOAD GAME',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
