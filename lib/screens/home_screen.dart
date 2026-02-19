import 'dart:io';
import 'dart:ui';
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
import '../providers/search_provider.dart';
import '../widgets/search_results_view.dart';
import '../services/artwork_cache_service.dart';

import 'tabs/folders_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/albums_tab.dart';

import 'details/artist_details_screen.dart';

import 'details/album_details_screen.dart';
import '../widgets/color_aware_album_card.dart';
import '../services/media_menu_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final HomeTab newTab;
        switch (_tabController.index) {
          case 0:
            newTab = HomeTab.home;
            break;
          case 1:
            newTab = HomeTab.folders;
            break;
          case 2:
            newTab = HomeTab.artists;
            break;
          case 3:
            newTab = HomeTab.albums;
            break;
          default:
            newTab = HomeTab.home;
        }
        ref.read(homeTabProvider.notifier).state = newTab;
      }
    });

    // Sync initial state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentTab = ref.read(homeTabProvider);
      _tabController.index = currentTab.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 20),
              child: AppTopBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppSearchBar(),
            ),
            const SizedBox(height: 12),
            if (ref.watch(searchQueryProvider).isEmpty)
              TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorColor: AppColors.accentBlue,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2.0,
                    color: AppColors.accentBlue,
                  ),
                  insets: EdgeInsets.only(top: 40),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: "LIBRARY"),
                  Tab(text: "FOLDERS"),
                  Tab(text: "ARTISTS"),
                  Tab(text: "ALBUMS"),
                ],
              ),
            Expanded(
              child: ref.watch(searchQueryProvider).isEmpty
                  ? TabBarView(
                      controller: _tabController,
                      physics: const ClampingScrollPhysics(),
                      children: const [
                        HomeOverviewContent(),
                        FoldersTab(),
                        ArtistsTab(),
                        AlbumsTab(),
                      ],
                    )
                  : const SearchResultsView(),
            ),
          ],
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
          child: CircularProgressIndicator(color: AppColors.accentBlue),
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
                backgroundColor: AppColors.accentBlue,
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

    // Background warming for home screen items
    ref.listen(
      libraryProvider.select((s) => (s.isLoading, s.songs.isNotEmpty)),
      (prev, next) {
        if (prev?.$1 == true && next.$1 == false && next.$2) {
          final state = ref.read(libraryProvider);
          // Warm up some top artists and albums
          for (final artist in state.artists.take(5)) {
            final songId = state.representativeArtistSongs[artist.artist];
            if (songId != null) {
              final song = state.songMap[songId] ?? state.songs.first;
              ArtworkCacheService.warmUp(song.url, song.id);
            }
          }
          for (final album in state.albums.take(5)) {
            final key = '${album.album}_${album.artist}';
            final songId = state.representativeAlbumSongs[key];
            if (songId != null) {
              final song = state.songMap[songId] ?? state.songs.first;
              ArtworkCacheService.warmUp(song.url, song.id);
            }
          }
        }
      },
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (libraryState.isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(AppColors.accentBlue),
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
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(title: "Popular Artists"),
          ),
          const SizedBox(height: 20),
          _buildArtistsSection(context, ref, libraryState, stats),
          const SizedBox(height: 40),

          // 2nd Section: Popular Albums
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(title: "Popular Albums"),
          ),
          const SizedBox(height: 20),
          _buildAlbumsSection(context, ref, libraryState, stats),
          const SizedBox(height: 40),

          // 3rd Section: Most Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(title: "Most Played"),
          ),
          const SizedBox(height: 20),
          _buildMostPlayedSection(context, ref, libraryState, stats),
          const SizedBox(height: 40),

          // 4th Section: Recently Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(title: "Recently Played"),
          ),
          const SizedBox(height: 20),
          _buildRecentSection(context, ref, libraryState, stats),
          const SizedBox(height: 40),

          // 5th Section: Summary
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(title: "Your Stats"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummarySection(stats, libraryState),
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

    final sortedArtists =
        stats.artistPlayDuration.entries
            .where((e) => !libraryState.hiddenArtists.contains(e.key))
            .toList()
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: topArtists.map((artist) {
          final name = artist.artist;
          final duration = stats.artistPlayDuration[name] ?? 0;

          String durationStr;
          if (duration >= 3600) {
            durationStr = "${(duration / 3600).toStringAsFixed(1)}h";
          } else {
            durationStr = "${(duration / 60).toInt()}m";
          }

          final artistSongId = libraryState.representativeArtistSongs[name];
          final artistSong =
              libraryState.songMap[artistSongId] ?? libraryState.songs.first;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppPopularArtistCard(
                name: name,
                imageUrl: "",
                songId: artistSong.id,
                songPath: artistSong.url,
                borderColor: libraryState.artistColors[name],
                artwork: AspectRatio(
                  aspectRatio: 1.0,
                  child: artist.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            File(artist.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : AppArtwork(
                          songId: artistSong.id,
                          songPath: artistSong.url,
                          size: 100,
                          borderRadius: 50,
                        ),
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
                onLongPress: () => AppCenteredModal.show(
                  context,
                  title: name,
                  items: MediaMenuService.buildArtistActions(
                    context: context,
                    ref: ref,
                    artist: artist,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

    final sortedAlbums =
        stats.albumPlayDuration.entries
            .where((e) => !libraryState.hiddenAlbums.contains(e.key))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 2 as requested
    final topAlbums = sortedAlbums.take(2).map((e) {
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
      child: Row(
        children: topAlbums.map((album) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildResponsiveAlbumCard(
                album,
                libraryState,
                context,
                ref,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResponsiveAlbumCard(
    Album album,
    LibraryState libraryState,
    BuildContext context,
    WidgetRef ref,
  ) {
    final albumKey = '${album.album}_${album.artist}';
    final albumSongId = libraryState.representativeAlbumSongs[albumKey];
    final albumSong =
        libraryState.songMap[albumSongId] ?? libraryState.songs.first;

    return AppAlbumCard(
      title: album.album,
      artist: album.artist,
      imageUrl: "",
      songId: albumSong.id,
      songPath: albumSong.url,
      artwork: AspectRatio(
        aspectRatio: 1.0,
        child: AppArtwork(
          songId: albumSong.id,
          songPath: albumSong.url,
          borderRadius: 12,
          size: 200,
        ),
      ),
      flexible: true,
      size: 100,
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
      onLongPress: () => AppCenteredModal.show(
        context,
        title: album.album,
        items: MediaMenuService.buildAlbumActions(
          context: context,
          ref: ref,
          album: album,
        ),
      ),
    );
  }

  Widget _buildMostPlayedSection(
    BuildContext context,
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.songPlayCounts.isEmpty) {
      return _buildEmptyState("Play music to see your top songs");
    }

    final sortedSongs = stats.songPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final fullQueue = <Song>[];
    for (var entry in sortedSongs.take(100)) {
      final song = libraryState.songMap[entry.key];
      if (song != null) {
        // Filter out if artist or album is hidden
        final isHidden =
            libraryState.hiddenArtists.contains(song.artist) ||
            (song.album != null &&
                libraryState.hiddenAlbums.contains(
                  "${song.album}_${song.artist}",
                ));
        if (!isHidden) fullQueue.add(song);
      }
    }

    if (fullQueue.isEmpty) {
      return _buildEmptyState("Play music to see your top songs");
    }

    final limitedQueue = fullQueue.take(100).toList();
    final displaySongs = limitedQueue.take(3).toList();

    return _buildSongRow(context, ref, displaySongs, limitedQueue);
  }

  Widget _buildRecentSection(
    BuildContext context,
    WidgetRef ref,
    LibraryState libraryState,
    PlayStats stats,
  ) {
    if (stats.recentPlayedIds.isEmpty) {
      return _buildEmptyState("History is currently empty");
    }

    final fullQueue = <Song>[];
    for (var id in stats.recentPlayedIds.take(100)) {
      final song = libraryState.songMap[id];
      if (song != null) {
        // Filter out if artist or album is hidden
        final isHidden =
            libraryState.hiddenArtists.contains(song.artist) ||
            (song.album != null &&
                libraryState.hiddenAlbums.contains(
                  "${song.album}_${song.artist}",
                ));
        if (!isHidden) fullQueue.add(song);
      }
    }

    if (fullQueue.isEmpty) {
      return _buildEmptyState("History is currently empty");
    }

    final limitedQueue = fullQueue.take(100).toList();
    final displaySongs = limitedQueue.take(3).toList();

    return _buildSongRow(context, ref, displaySongs, limitedQueue);
  }

  /// Formats a large integer with K/M suffix to prevent overflow.
  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  /// Formats seconds into a compact human-readable duration.
  String _fmtDuration(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h >= 100) return '${h}h'; // e.g. "342h" — no minutes needed
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Widget _buildSummarySection(PlayStats stats, LibraryState library) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthlyPlays = stats.monthlyPlays[monthKey] ?? 0;

    final totalDurationSec = stats.songPlayDuration.values.fold(
      0,
      (a, b) => a + b,
    );
    final lifetimePlays = stats.songPlayCounts.values.fold(0, (a, b) => a + b);

    final totalTracks = library.songs.length;
    final playedIds = stats.songPlayCounts.keys.toSet();
    final neverPlayed = library.songs
        .where((s) => !playedIds.contains(s.id))
        .length;
    final totalArtists = library.artists.length;
    final totalAlbums = library.albums.length;

    // ── helper to build one stat tile ──────────────────────────────────────
    Widget tile({
      required IconData icon,
      required String label,
      required String value,
      Color? accent,
      bool wide = false,
    }) {
      final color = accent ?? AppColors.accentBlue;
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          ),
          child: wide
              // Wide tile: icon + label on left, value on right
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                )
              // Square tile: icon top, value middle, label bottom
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 13, color: color),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
        ),
      );
    }

    // ── layout ─────────────────────────────────────────────────────────────
    const gap = SizedBox(width: 10);
    const vgap = SizedBox(height: 10);

    return Column(
      children: [
        // Row 1: Tracks | Never Played | Lifetime Plays
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: tile(
                  icon: Icons.library_music_outlined,
                  label: 'Tracks',
                  value: _fmtCount(totalTracks),
                  accent: AppColors.accentBlue,
                ),
              ),
              gap,
              Expanded(
                child: tile(
                  icon: Icons.music_off_outlined,
                  label: 'Never Played',
                  value: _fmtCount(neverPlayed),
                  accent: const Color(0xFFFF6B6B),
                ),
              ),
              gap,
              Expanded(
                child: tile(
                  icon: Icons.play_circle_outline,
                  label: 'Lifetime Plays',
                  value: _fmtCount(lifetimePlays),
                  accent: const Color(0xFF6BCB77),
                ),
              ),
            ],
          ),
        ),
        vgap,
        // Row 2: Artists | Albums | This Month
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: tile(
                  icon: Icons.person_outline,
                  label: 'Artists',
                  value: _fmtCount(totalArtists),
                  accent: const Color(0xFFFFD93D),
                ),
              ),
              gap,
              Expanded(
                child: tile(
                  icon: Icons.album_outlined,
                  label: 'Albums',
                  value: _fmtCount(totalAlbums),
                  accent: const Color(0xFFFF922B),
                ),
              ),
              gap,
              Expanded(
                child: tile(
                  icon: Icons.calendar_month_outlined,
                  label: 'This Month',
                  value: _fmtCount(monthlyPlays),
                  accent: const Color(0xFFCC5DE8),
                ),
              ),
            ],
          ),
        ),
        vgap,
        // Row 3: Total Playtime — full-width wide tile
        tile(
          icon: Icons.timer_outlined,
          label: 'Total Playtime',
          value: _fmtDuration(totalDurationSec),
          accent: AppColors.accentBlue,
          wide: true,
        ),
      ],
    );
  }

  Widget _buildSongRow(
    BuildContext context,
    WidgetRef ref,
    List<Song> displaySongs,
    List<Song> fullQueue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: displaySongs.map((song) {
          final indexInQueue = fullQueue.indexOf(song);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ColorAwareAlbumCard(
                onTap: () {
                  if (indexInQueue != -1) {
                    ref
                        .read(playerProvider.notifier)
                        .playPlaylist(fullQueue, indexInQueue);
                  } else {
                    ref.read(playerProvider.notifier).play(song);
                  }
                },
                title: song.title,
                artist: song.artist,
                imageUrl: "",
                songId: song.id,
                songPath: song.url,
                artwork: AspectRatio(
                  aspectRatio: 1.0,
                  child: AppArtwork(
                    songId: song.id,
                    size: 100,
                    borderRadius: 12,
                  ),
                ),
                flexible: true,
                onLongPress: () => AppCenteredModal.show(
                  context,
                  title: song.title,
                  items: MediaMenuService.buildSongActions(
                    context: context,
                    ref: ref,
                    song: song,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // _buildArtistItem removed as it's no longer used
}
