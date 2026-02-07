import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final String year;

  const AlbumDetailsScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.year = "2024",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$artist • $year",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMain.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.shuffle,
                        label: "Shuffle",
                        onTap: () {},
                      ),
                      const SizedBox(width: 40),
                      AppPlayButton(
                        isPlaying: false,
                        size: 64,
                        color: AppColors.primaryGreen,
                        iconColor: Colors.white,
                        onTap: () {},
                      ),
                      const SizedBox(width: 40),
                      _buildActionButton(
                        context,
                        icon: Icons.playlist_add,
                        label: "Add to Playlist",
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildSongTile(index + 1);
            }, childCount: 12),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white70, size: 28),
        ),
      ],
    );
  }

  Widget _buildSongTile(int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Text(
        index.toString(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      title: Text(
        "Album Song $index",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        artist,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
        onPressed: () {},
      ),
      onTap: () {},
    );
  }
}
