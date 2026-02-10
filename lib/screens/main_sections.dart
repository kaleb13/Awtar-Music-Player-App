import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/search_provider.dart';
import '../providers/player_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 24, right: 24, top: 20),
                child: AppTopBar(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: AppSearchBar(autoFocus: true),
              ),
              Expanded(
                child: query.isEmpty
                    ? _buildSearchPlaceholder()
                    : results.isEmpty
                    ? _buildNoResults()
                    : _buildSearchResults(results, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.search,
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              AppColors.textGrey.withOpacity(0.3),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Find your favorite music",
            style: AppTextStyles.bodyMain.copyWith(
              color: AppColors.textGrey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Text(
        "No results found",
        style: TextStyle(color: AppColors.textGrey),
      ),
    );
  }

  Widget _buildSearchResults(SearchResult results, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (results.songs.isNotEmpty) ...[
          _buildHeader("SONGS"),
          ...results.songs.map(
            (song) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSongListTile(
                title: song.title,
                artist: song.artist,
                duration: _formatDuration(song.duration),
                imageUrl: song.albumArt ?? "https://placeholder.com",
                onTap: () {
                  ref.read(playerProvider.notifier).play(song);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (results.albums.isNotEmpty) ...[
          _buildHeader("ALBUMS"),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final album = results.albums[index];
                return AppAlbumCard(
                  title: album.title,
                  artist: album.artist,
                  imageUrl: album.imageUrl,
                  size: 120,
                  onTap: () {},
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (results.artists.isNotEmpty) ...[
          _buildHeader("ARTISTS"),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final artist = results.artists[index];
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(artist.imageUrl),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        artist.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 100), // Bottom padding for player
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 2,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final d = Duration(milliseconds: ms);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 24, right: 24, top: 20),
                  child: AppTopBar(),
                ),
                const SizedBox(height: 10),
                const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.accentYellow,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(text: "Favorites"),
                    Tab(text: "Playlist"),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    children: [const _FavoritesTab(), const _PlaylistsTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppSongListTile(
            title: "Favorite Song ${index + 1}",
            artist: "Artist Name",
            duration: "3:45",
            imageUrl: "https://source.unsplash.com/random/100x100?sig=$index",
            onTap: () {},
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return AppAlbumCard(
          title: "Playlist ${index + 1}",
          artist: "${(index + 1) * 5} Songs",
          imageUrl:
              "https://source.unsplash.com/random/300x300?playlist=$index",
          onTap: () {},
          flexible: true,
        );
      },
    );
  }
}

class AppSongListTile extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final String imageUrl;
  final VoidCallback onTap;

  const AppSongListTile({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              duration,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.more_vert, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
