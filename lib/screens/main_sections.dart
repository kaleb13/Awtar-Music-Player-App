import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/app_song_list_tile.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_artwork.dart';
import '../widgets/playlist_dialogs.dart';
import 'details/playlist_details_screen.dart';
import 'discovery_tabs.dart';
import '../providers/search_provider.dart';
import '../widgets/search_results_view.dart';
import '../models/song.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return DefaultTabController(
      length: 3,
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(),
              ),
              const SizedBox(height: 10),
              if (!isSearching) ...[
                const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.accentBlue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(text: "Random Remix"),
                    Tab(text: "Upcoming Musics"),
                    Tab(text: "Tickets"),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: isSearching
                    ? const SearchResultsView()
                    : const TabBarView(
                        physics: ClampingScrollPhysics(),
                        children: [
                          RemixTab(),
                          UpcomingMusicTab(),
                          TicketsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(),
              ),
              const SizedBox(height: 10),
              if (!isSearching) ...[
                const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.accentBlue,
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
              ],
              Expanded(
                child: isSearching
                    ? const SearchResultsView()
                    : const TabBarView(
                        physics: ClampingScrollPhysics(),
                        children: [_FavoritesTab(), _PlaylistsTab()],
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
            const Icon(Icons.favorite_border, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
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
            trailing: IconButton(
              icon: const Icon(
                Icons.favorite,
                color: AppColors.accentBlue,
                size: 20,
              ),
              onPressed: () {
                ref.read(libraryProvider.notifier).toggleFavorite(song);
              },
            ),
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
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    PlaylistDialogs.showCreatePlaylist(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Playlist"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
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
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF161618),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Play",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (playlist.songIds.isEmpty) return;

                                    final songs = ref
                                        .read(libraryProvider)
                                        .songs;
                                    final songMap = {
                                      for (var s in songs) s.id: s,
                                    };
                                    final playlistSongs = playlist.songIds
                                        .map((id) => songMap[id])
                                        .where((s) => s != null)
                                        .cast<Song>()
                                        .toList();

                                    if (playlistSongs.isNotEmpty) {
                                      ref
                                          .read(playerProvider.notifier)
                                          .play(
                                            playlistSongs.first,
                                            queue: playlistSongs,
                                          );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.shuffle,
                                    color: Colors.white,
                                  ),
                                  title: const Text(
                                    "Shuffle Play",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    if (playlist.songIds.isEmpty) return;

                                    final songs = ref
                                        .read(libraryProvider)
                                        .songs;
                                    final songMap = {
                                      for (var s in songs) s.id: s,
                                    };
                                    final playlistSongs = playlist.songIds
                                        .map((id) => songMap[id])
                                        .where((s) => s != null)
                                        .cast<Song>()
                                        .toList();

                                    if (playlistSongs.isNotEmpty) {
                                      playlistSongs.shuffle();
                                      ref
                                          .read(playerProvider.notifier)
                                          .play(
                                            playlistSongs.first,
                                            queue: playlistSongs,
                                          );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  title: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    PlaylistDialogs.showDeleteConfirmation(
                                      context,
                                      ref,
                                      playlist,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
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
          const Icon(Icons.playlist_add, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            "No playlists created yet",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

