import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_song_list_tile.dart';
import '../providers/search_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_artwork.dart';
import '../widgets/playlist_dialogs.dart';
import 'details/album_details_screen.dart';
import 'details/artist_details_screen.dart';
import 'details/playlist_details_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 20),
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
                song: song,
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
                final library = ref.watch(libraryProvider);

                // Get a representative song ID for this album
                final albumKey = '${album.album}_${album.artist}';
                final albumSongId = library.representativeAlbumSongs[albumKey];

                return AppAlbumCard(
                  title: album.album,
                  artist: album.artist,
                  imageUrl: "",
                  songId: albumSongId,
                  artwork: AspectRatio(
                    aspectRatio: 1.0,
                    child: AppArtwork(
                      songId: albumSongId,
                      borderRadius: 12,
                      size: 120,
                    ),
                  ),
                  size: 120,
                  onTap: () {
                    ref.read(bottomNavVisibleProvider.notifier).state = false;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailsScreen(
                          title: album.album,
                          artist: album.artist,
                          imageUrl: "",
                        ),
                      ),
                    ).then((_) {
                      ref.read(bottomNavVisibleProvider.notifier).state = true;
                    });
                  },
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
                final library = ref.watch(libraryProvider);

                // Get a representative song ID for this artist
                final artistSongId =
                    library.representativeArtistSongs[artist.artist];
                final fallbackSongId = library.songs.isNotEmpty
                    ? library.songs.first.id
                    : 0;
                final finalSongId = artistSongId ?? fallbackSongId;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(bottomNavVisibleProvider.notifier).state =
                            false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistDetailsScreen(
                              name: artist.artist,
                              imageUrl: "",
                            ),
                          ),
                        ).then((_) {
                          ref.read(bottomNavVisibleProvider.notifier).state =
                              true;
                        });
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: AppArtwork(
                            songId: finalSongId,
                            size: 80,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        artist.artist,
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
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, right: 8, top: 20),
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
                  physics: const ClampingScrollPhysics(),
                  children: [const _FavoritesTab(), const _PlaylistsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(
      libraryProvider.select(
        (s) => s.songs.where((song) => song.isFavorite).toList(),
      ),
    );

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              "No favorite songs yet",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppSongListTile(
            song: song,
            onTap: () {
              ref
                  .read(playerProvider.notifier)
                  .play(song, queue: favorites, index: index);
            },
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(libraryProvider.select((s) => s.playlists));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${playlists.length} Playlists",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    PlaylistDialogs.showCreatePlaylist(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Playlist"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: playlists.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final firstSongId = playlist.songIds.isNotEmpty
                        ? playlist.songIds.first
                        : null;

                    return AppAlbumCard(
                      title: playlist.name,
                      artist: "${playlist.songIds.length} Songs",
                      imageUrl: "",
                      songId: firstSongId,
                      onTap: () {
                        // Hide bottom nav for sub-screens
                        ref.read(bottomNavVisibleProvider.notifier).state =
                            false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaylistDetailsScreen(playlistId: playlist.id),
                          ),
                        ).then((_) {
                          ref.read(bottomNavVisibleProvider.notifier).state =
                              true;
                        });
                      },
                      artwork: AspectRatio(
                        aspectRatio: 1.0,
                        child: playlist.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(playlist.imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (firstSongId != null
                                  ? AppArtwork(
                                      songId: firstSongId,
                                      borderRadius: 12,
                                      size: 200,
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.playlist_play,
                                        color: Colors.white24,
                                        size: 40,
                                      ),
                                    )),
                      ),
                      flexible: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            "No playlists created yet",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
