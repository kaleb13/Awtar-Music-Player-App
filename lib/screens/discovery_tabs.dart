import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_song_list_tile.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../widgets/app_artwork.dart';

class RemixTab extends ConsumerWidget {
  const RemixTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final songs = library.songs;

    if (songs.isEmpty) {
      return const Center(child: Text("No songs available for remix"));
    }

    final seed = DateTime.now().hour + DateTime.now().day;
    final random = Random(seed);

    final artistGroups = <String, List<Song>>{};
    for (var song in songs) {
      artistGroups.putIfAbsent(song.artist, () => []).add(song);
    }

    final allArtists = library.artists.toList()..shuffle(random);
    final remixGroups = <_RemixGroupData>[];

    // Generate 2 remix groups: one with 2 and one with 3 artists
    int artistIdx = 0;
    final sizes = [2, 3]..shuffle(random);
    for (final groupSize in sizes) {
      final List<Artist> groupArtists = [];
      final List<Song> groupSongs = [];
      final Map<String, int> groupArtistSongIds = {};

      for (int j = 0; j < groupSize; j++) {
        if (artistIdx < allArtists.length) {
          final artist = allArtists[artistIdx++];
          groupArtists.add(artist);
          final songs = artistGroups[artist.artist] ?? [];
          groupSongs.addAll(songs);
          if (songs.isNotEmpty) {
            groupArtistSongIds[artist.artist] = songs.first.id;
          }
        }
      }

      if (groupArtists.length >= 2) {
        remixGroups.add(
          _RemixGroupData(groupArtists, groupSongs, groupArtistSongIds),
        );
      }
    }

    final remixQueue = songs.toList()..shuffle(random);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < remixGroups.length; i++) ...[
                  _RemixCapsule(
                    artists: remixGroups[i].artists,
                    artistSongIds: remixGroups[i].artistSongIds,
                    totalTracks: remixGroups[i].allSongs.length,
                    onTap: () {
                      final shuffledQueue = remixGroups[i].allSongs.toList()
                        ..shuffle();
                      if (shuffledQueue.isNotEmpty) {
                        ref
                            .read(playerProvider.notifier)
                            .playPlaylist(shuffledQueue, 0);
                      }
                    },
                  ),
                  if (i < remixGroups.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = remixQueue[index % remixQueue.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSongListTile(
                  song: song,
                  onTap: () {
                    ref
                        .read(playerProvider.notifier)
                        .play(song, queue: remixQueue, index: index);
                  },
                ),
              );
            }, childCount: min(remixQueue.length, 50)),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 150)),
      ],
    );
  }
}

class _RemixGroupData {
  final List<Artist> artists;
  final List<Song> allSongs;
  final Map<String, int> artistSongIds;
  _RemixGroupData(this.artists, this.allSongs, this.artistSongIds);
}

class _RemixCapsule extends ConsumerWidget {
  final List<Artist> artists;
  final Map<String, int> artistSongIds;
  final int totalTracks;
  final VoidCallback onTap;

  const _RemixCapsule({
    required this.artists,
    required this.artistSongIds,
    required this.totalTracks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.accentYellow.withOpacity(0.8),
                width: 2,
              ),
              color: Colors.white.withOpacity(0.03),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: artists.map((artist) {
                final color =
                    libraryState.artistColors[artist.artist] ?? Colors.white24;
                return Container(
                  width: 56, // Increased from 42
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: artist.imagePath != null
                        ? Image.file(
                            File(artist.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                _buildFallbackArtist(artist),
                          )
                        : (artistSongIds[artist.artist] != null
                              ? AppArtwork(
                                  songId: artistSongIds[artist.artist],
                                  size: 56,
                                  borderRadius: 100,
                                )
                              : _buildFallbackArtist(artist)),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            top: -12,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0F),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "$totalTracks Tracks",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackArtist(Artist artist) {
    return Container(
      color: Colors.white10,
      child: Center(
        child: Text(
          artist.artist[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class UpcomingMusicTab extends StatelessWidget {
  const UpcomingMusicTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildComingSoonState(
      icon: Icons.movie_filter_outlined,
      title: "Album Trailers & Teasers",
      description:
          "Get ready for a visual musical journey. This section will soon feature exclusive trailers and high-definition teasers for upcoming albums from your favorite artists, giving you a front-row seat to the creative process before the full release.",
    );
  }
}

class TicketsTab extends StatelessWidget {
  const TicketsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildComingSoonState(
      icon: Icons.confirmation_number_outlined,
      title: "Exclusive Concert Tickets",
      description:
          "Your passport to live music. We are working on a dedicated platform where you can discover upcoming concerts, tours, and live events. Soon, you'll be able to purchase tickets directly within AwtarPlayer, bridging the gap between digital listening and live performance.",
    );
  }
}

Widget _buildComingSoonState({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Align(
    alignment: Alignment.topCenter,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40.0, 60.0, 40.0, 40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 64),
            ),
            const SizedBox(height: 32),
            Text(
              "Coming Soon",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentYellow,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
