import 'package:flutter/material.dart';
import '../models/artist.dart';
import '../models/album.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/navigation_provider.dart';
import '../providers/library_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../widgets/app_artwork.dart';

import 'tabs/folders_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/albums_tab.dart';

import 'details/artist_details_screen.dart';

import 'details/album_details_screen.dart';
import '../widgets/color_aware_album_card.dart'; // Add import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 20,
                  ), // Reduced from 24
                  child: AppTopBar(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppSearchBar(),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.accentYellow,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: AppColors.accentYellow,
                    ),
                    insets: EdgeInsets.only(top: 40), // Push indicator down
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelPadding: EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: "LIBRARY"), // Changed content
                    Tab(text: "FOLDERS"),
                    Tab(text: "ARTISTS"),
                    Tab(text: "ALBUMS"),
                  ],
                ),
                const SizedBox(height: 0),
                const Expanded(
                  child: TabBarView(
                    children: [
                      HomeOverviewContent(),
                      FoldersTab(),
                      ArtistsTab(),
                      AlbumsTab(),
                    ],
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

class HomeOverviewContent extends ConsumerWidget {
  const HomeOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final stats = ref.watch(statsProvider);

    if (libraryState.permissionStatus != LibraryPermissionStatus.granted) {
      if (libraryState.permissionStatus == LibraryPermissionStatus.requesting) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accentYellow),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            const Icon(
              Icons.library_music_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            Text("Your Music Library", style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "To see your artists, albums, and folders, Awtar needs access to your device's audio files.",
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  ref.read(libraryProvider.notifier).requestPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Grant Storage Access",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (libraryState.isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(AppColors.accentYellow),
              minHeight: 2,
            ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppPromoBanner(),
          ),
          const SizedBox(height: 30),

          // 1st Section: Popular Artists
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Popular Artists"),
          ),
          const SizedBox(height: 20),
          _buildArtistsSection(context, ref, libraryState, stats),
          const SizedBox(height: 40),

          // 2nd Section: Popular Albums
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Popular Albums"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildAlbumsSection(context, ref, libraryState, stats),
          ),
          const SizedBox(height: 40),

          // 3rd Section: Most Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Most Played"),
          ),
          const SizedBox(height: 20),
          _buildMostPlayedSection(ref, libraryState, stats),
          const SizedBox(height: 40),

          // 4th Section: Recently Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Recently Played"),
          ),
          const SizedBox(height: 20),
          _buildRecentSection(ref, libraryState, stats),
          const SizedBox(height: 40),

          // 5th Section: Summary
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Monthly Summary"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSummarySection(stats),
          ),
          const SizedBox(height: 180),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: AppTextStyles.caption.copyWith(color: Colors.white30),
        ),
      ),
    );
  }

  Widget _buildArtistsSection(
    BuildContext context,
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.artistPlayDuration.isEmpty) {
      return _buildEmptyState("No artists played yet");
    }

    final sortedArtists = stats.artistPlayDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 3 artists as requested
    final topArtists = sortedArtists.take(3).map((e) {
      final name = e.key;
      return libraryState.artists.firstWhere(
        (a) => a.artist == name,
        orElse: () =>
            Artist(id: 0, artist: name, numberOfTracks: 0, numberOfAlbums: 0),
      );
    }).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: topArtists.map((artist) {
            final name = artist.artist;
            final duration = stats.artistPlayDuration[name] ?? 0;

            String durationStr;
            if (duration >= 3600) {
              durationStr = "${(duration / 3600).toStringAsFixed(1)}h";
            } else {
              durationStr = "${(duration / 60).toInt()}m";
            }

            final artistSong = libraryState.songs.firstWhere(
              (s) => s.artist == name,
              orElse: () => libraryState.songs.first,
            );

            // Use Expanded or Flexible if needed, but with reduced size fixed width might work.
            // Using a slightly smaller fixed size to ensure 3 fit.
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppPopularArtistCard(
                name: name,
                imageUrl: "",
                songId: artistSong.id,
                artwork: AppArtwork(
                  songId: artistSong.id,
                  size: 100,
                  borderRadius: 50,
                ),
                playTime: durationStr,
                subtitle: "${artist.numberOfTracks} Tracks",
                onTap: () {
                  ref.read(bottomNavVisibleProvider.notifier).state = false;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ArtistDetailsScreen(name: name, imageUrl: ""),
                    ),
                  ).then((_) {
                    ref.read(bottomNavVisibleProvider.notifier).state = true;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlbumsSection(
    BuildContext context,
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.albumPlayDuration.isEmpty) {
      return _buildEmptyState("No albums played yet");
    }

    final sortedAlbums = stats.albumPlayDuration.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 as requested
    final topAlbums = sortedAlbums.take(5).map((e) {
      final title = e.key;
      return libraryState.albums.firstWhere(
        (a) => a.album == title,
        orElse: () =>
            Album(id: 0, album: title, artist: "Unknown", numberOfSongs: 0),
      );
    }).toList();

    if (topAlbums.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 340, // Fixed height for the layout
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Top 1 Album (Big)
            Expanded(
              flex: 4,
              child: _buildResponsiveAlbumCard(
                topAlbums[0],
                libraryState,
                context,
                ref,
                isBig: true,
              ),
            ),
            const SizedBox(width: 12),
            // Right: Grid of 4 Albums (Smaller)
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (topAlbums.length > 1)
                          Expanded(
                            child: _buildResponsiveAlbumCard(
                              topAlbums[1],
                              libraryState,
                              context,
                              ref,
                            ),
                          ),
                        const SizedBox(width: 6), // Minimal gap
                        if (topAlbums.length > 2)
                          Expanded(
                            child: _buildResponsiveAlbumCard(
                              topAlbums[2],
                              libraryState,
                              context,
                              ref,
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6), // Minimal gap
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (topAlbums.length > 3)
                          Expanded(
                            child: _buildResponsiveAlbumCard(
                              topAlbums[3],
                              libraryState,
                              context,
                              ref,
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 6), // Minimal gap
                        if (topAlbums.length > 4)
                          Expanded(
                            child: _buildResponsiveAlbumCard(
                              topAlbums[4],
                              libraryState,
                              context,
                              ref,
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveAlbumCard(
    Album album,
    LibraryState libraryState,
    BuildContext context,
    WidgetRef ref, {
    bool isBig = false,
  }) {
    final albumSong = libraryState.songs.firstWhere(
      (s) => s.album == album.album,
      orElse: () => libraryState.songs.first,
    );

    return AppAlbumCard(
      title: album.album,
      artist: album.artist,
      imageUrl: "",
      songId: albumSong.id,
      artwork: AppArtwork(
        songId: albumSong.id,
        borderRadius: 12,
        size: isBig ? 300 : 100,
      ),
      flexible: true,
      size: isBig ? 180 : 100,
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
  }

  Widget _buildMostPlayedSection(
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.songPlayCounts.isEmpty) {
      return _buildEmptyState("Play music to see your top songs");
    }

    final sortedSongs = stats.songPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topSongIds = sortedSongs.take(8).map((e) => e.key).toList();
    final displaySongs = topSongIds
        .map(
          (id) => libraryState.songs.firstWhere(
            (s) => s.id == id,
            orElse: () => libraryState.songs.first,
          ),
        )
        .toList();

    return _buildSongScroll(ref, displaySongs);
  }

  Widget _buildRecentSection(
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.recentPlayedIds.isEmpty) {
      return _buildEmptyState("History is currently empty");
    }

    final displaySongs = stats.recentPlayedIds
        .map(
          (id) => libraryState.songs.firstWhere(
            (s) => s.id == id,
            orElse: () => libraryState.songs.first,
          ),
        )
        .toList();

    return _buildSongScroll(ref, displaySongs);
  }

  Widget _buildSummarySection(PlayStats stats) {
    final now = DateTime.now();
    final weekNumber =
        ((now.difference(DateTime(now.year, 1, 1)).inDays +
                    DateTime(now.year, 1, 1).weekday) /
                7)
            .ceil();
    final weekKey = "${now.year}-W${weekNumber.toString().padLeft(2, '0')}";
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final weeklyPlays = stats.weeklyPlays[weekKey] ?? 0;
    final monthlyPlays = stats.monthlyPlays[monthKey] ?? 0;
    final totalDuration = stats.songPlayDuration.values.fold(
      0,
      (a, b) => a + b,
    );
    final totalHours = (totalDuration / 3600).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: AppSummaryItem(
            label: "Monthly Plays",
            value: monthlyPlays.toString(),
            trend: "+$weeklyPlays", // Weekly as trend label
            isTrendPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppSummaryItem(
            label: "Total Playtime",
            value: "${totalHours}h",
            trend: "${(totalDuration / 60).toInt()}m", // Total minutes as trend
            isTrendPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSongScroll(WidgetRef ref, List<Song> songs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: songs
            .map(
              (song) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ColorAwareAlbumCard(
                  onTap: () => ref.read(playerProvider.notifier).play(song),
                  title: song.title,
                  artist: song.artist,
                  imageUrl: "",
                  artwork: AppArtwork(
                    songId: song.id,
                    size: 100,
                    borderRadius: 12,
                  ),
                  size: 100,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // _buildArtistItem removed as it's no longer used
}
