import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/providers/library_provider.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/theme/app_theme.dart';
import 'package:awtar_music_player/widgets/app_widgets.dart';
import '../models/song.dart';
import 'package:awtar_music_player/widgets/media_edit_dialogs.dart';
import 'details/album_details_screen.dart';
import 'details/artist_details_screen.dart';
import 'package:awtar_music_player/widgets/app_song_list_tile.dart';
import '../models/artist.dart';
import 'dart:async';

class PlayerScreenContent extends ConsumerWidget {
  const PlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.isPlaying;
    final Song? song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 25,
            ), // Increased from 15 to push the top bar down slightly
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppIconButton(
                  icon: Icons.arrow_back,
                  color: AppColors.textLight,
                  onTap: () =>
                      ref.read(screenProvider.notifier).state = AppScreen.home,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailsScreen(
                            title: song.album ?? 'Single',
                            artist: song.artist,
                            imageUrl: '',
                          ),
                        ),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Text.rich(
                      TextSpan(
                        text: "FROM  ",
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.black.withOpacity(0.3),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(
                            text: (song.album ?? "Single").toUpperCase(),
                            style: AppTextStyles.bodyMain.copyWith(
                              color: Colors.black,
                              fontSize: 10,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textLight,
                  ),
                  onSelected: (value) {
                    if (value == 'Share') {
                      // Share implementation
                    } else if (value == 'View Artist') {
                      final artistObj = ref
                          .read(libraryProvider)
                          .artists
                          .firstWhere(
                            (a) => a.artist == song.artist,
                            orElse: () => Artist(
                              id: 0,
                              artist: song.artist,
                              numberOfTracks: 0,
                              numberOfAlbums: 0,
                            ),
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistDetailsScreen(
                            name: artistObj.artist,
                            imageUrl: artistObj.imagePath ?? '',
                          ),
                        ),
                      );
                    } else if (value == 'View Album') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailsScreen(
                            title: song.album ?? 'Single',
                            artist: song.artist,
                            imageUrl: '',
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Share',
                      child: AppMenuEntry(
                        icon: Icons.share_outlined,
                        label: "Share",
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'View Artist',
                      child: AppMenuEntry(
                        icon: Icons.person_outline,
                        label: "View Artist",
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'View Album',
                      child: AppMenuEntry(
                        icon: Icons.album_outlined,
                        label: "View Album",
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height:
                  ((MediaQuery.of(context).size.width - 48)).clamp(0, 450) + 20,
            ), // Reduced from 35 to save vertical space
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textLight,
                          fontSize: 24, // Slightly reduced from 26
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${song.artist}${song.year != null ? ' • ${song.year}' : ''}",
                        style: AppTextStyles.bodyMain.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 16, // Slightly reduced from 18
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      ref.read(libraryProvider.notifier).toggleFavorite(song),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: song.isFavorite
                          ? AppColors.primaryGreen
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: song.isFavorite
                          ? null
                          : Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          song.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: song.isFavorite
                              ? Colors.white
                              : Colors.black54,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Favorite",
                          style: AppTextStyles.bodySmall.copyWith(
                            color: song.isFavorite
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 20
            Consumer(
              builder: (context, ref, child) {
                final position =
                    ref.watch(playerPositionStreamProvider).value ??
                    Duration.zero;
                final duration =
                    ref.watch(playerDurationStreamProvider).value ??
                    Duration.zero;
                return Column(
                  children: [
                    AppProgressBar(
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble(),
                      onChanged: (v) => ref
                          .read(playerProvider.notifier)
                          .seek(Duration(seconds: v.toInt())),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 15), // Reduced from 22
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppIconButton(
                  icon: playerState.repeatMode == RepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  size: 26, // Scaled up
                  color: playerState.repeatMode != RepeatMode.off
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                  onTap: () => ref.read(playerProvider.notifier).toggleRepeat(),
                ),
                AppIconButton(
                  icon: Icons.skip_previous,
                  color: AppColors.textLight,
                  size: 40, // Significantly increased from 32
                  onTap: () => ref.read(playerProvider.notifier).previous(),
                ),
                AppPlayButton(
                  size: 68, // Increased from 56
                  isPlaying: isPlaying,
                  onTap: () =>
                      ref.read(playerProvider.notifier).togglePlayPause(song),
                ),
                AppIconButton(
                  icon: Icons.skip_next,
                  color: AppColors.textLight,
                  size: 40, // Significantly increased from 32
                  onTap: () => ref.read(playerProvider.notifier).next(),
                ),
                AppIconButton(
                  icon: Icons.shuffle,
                  size: 26, // Scaled up
                  color: ref.watch(playerProvider).isShuffling
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                  onTap: () =>
                      ref.read(playerProvider.notifier).toggleShuffle(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E2129),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Consumer(
                    builder: (context, ref, child) {
                      final pState = ref.watch(playerProvider);
                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.queue_music,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Current Queue (${pState.queue.length})",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: pState.queue.length,
                              itemBuilder: (context, index) {
                                final qSong = pState.queue[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppSongListTile(
                                    song: qSong,
                                    isActive: index == pState.currentIndex,
                                    onTap: () {
                                      ref
                                          .read(playerProvider.notifier)
                                          .play(
                                            qSong,
                                            queue: pState.queue,
                                            index: index,
                                          );
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  "${playerState.currentIndex + 1} / ${playerState.queue.length}",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mainDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class LyricsHeaderContent extends ConsumerWidget {
  const LyricsHeaderContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final song =
        playerState.currentSong ??
        (library.songs.isNotEmpty ? library.songs.first : null);
    if (song == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32), // Match the album art's top position
        SizedBox(
          height: 50, // Match the album art's height
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically center text with art
            children: [
              const SizedBox(width: 62), // 50px art + 12px gap
              // Tappable info section to go back
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(screenProvider.notifier).state = AppScreen.player;
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${song.artist}${song.year != null ? ' • ${song.year}' : ''}",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textGrey,
                    size: 26,
                  ),
                ),
                color: const Color(0xFF1C1C1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit_lyrics') {
                    MediaEditDialogs.showEditLyrics(context, ref, song);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit_lyrics',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "Edit Lyrics",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite
                    ? AppColors.primaryGreen
                    : Colors.white24,
                size: 22,
                onTap: () {
                  ref
                      .read(playerProvider.notifier)
                      .updateFavoriteStatus(song.id, !song.isFavorite);
                  ref.read(libraryProvider.notifier).toggleFavorite(song);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            ref.read(screenProvider.notifier).state = AppScreen.player;
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: 10,
              ), // Adding margin for better touch area
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LyricsScreenContent extends ConsumerStatefulWidget {
  final void Function(double)? onDragUpdate;
  final void Function(double)? onDragEnd;

  const LyricsScreenContent({super.key, this.onDragUpdate, this.onDragEnd});

  @override
  ConsumerState<LyricsScreenContent> createState() =>
      _LyricsScreenContentState();
}

class _LyricsScreenContentState extends ConsumerState<LyricsScreenContent> {
  final List<GlobalKey> _lyricKeys = [];
  int _prevIndex = -1;
  bool _isUserScrolling = false;
  Timer? _userScrollTimer;

  @override
  void dispose() {
    _userScrollTimer?.cancel();
    super.dispose();
  }

  void _onUserScroll() {
    _isUserScrolling = true;
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    final position =
        ref.watch(playerPositionStreamProvider).value ?? Duration.zero;

    if (currentSong == null) return const SizedBox.shrink();

    // Sync keys with lyrics length
    if (_lyricKeys.length != currentSong.lyrics.length) {
      _lyricKeys.clear();
      for (int i = 0; i < currentSong.lyrics.length; i++) {
        _lyricKeys.add(GlobalKey());
      }
    }

    // Determine active index
    int currentIndex = -1;
    if (currentSong.lyrics.isNotEmpty) {
      for (int i = 0; i < currentSong.lyrics.length; i++) {
        final lyric = currentSong.lyrics[i];
        final nextTime = (i + 1 < currentSong.lyrics.length)
            ? currentSong.lyrics[i + 1].time
            : const Duration(hours: 99);

        if (position >= lyric.time && position < nextTime) {
          currentIndex = i;
          break;
        }
      }
    }

    // Trigger Scroll Effect if index changed
    if (currentIndex != -1 && currentIndex != _prevIndex) {
      _prevIndex = currentIndex;
      if (!_isUserScrolling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              currentIndex < _lyricKeys.length &&
              _lyricKeys[currentIndex].currentContext != null) {
            Scrollable.ensureVisible(
              _lyricKeys[currentIndex].currentContext!,
              alignment:
                  0.4, // Position slightly above center for better visibility
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    }

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        widget.onDragUpdate?.call(details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        widget.onDragEnd?.call(details.primaryVelocity ?? 0);
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit_note, color: Colors.white),
                  title: const Text(
                    "Edit Lyrics",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    MediaEditDialogs.showEditLyrics(context, ref, currentSong);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white),
                  title: const Text(
                    "Edit Metadata",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    MediaEditDialogs.showEditSong(context, ref, currentSong);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Container(
        color: AppColors.mainDark,
        padding: const EdgeInsets.only(top: 140),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is UserScrollNotification) {
              _onUserScroll();
            }

            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels <= 0 &&
                  notification.dragDetails != null) {
                widget.onDragUpdate?.call(notification.dragDetails!.delta.dy);
              }
            } else if (notification is ScrollEndNotification) {
              widget.onDragEnd?.call(
                notification.dragDetails?.primaryVelocity ?? 0,
              );
            }
            return false;
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentSong.lyrics.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Text(
                        "No lyrics available",
                        style: AppTextStyles.bodyMain.copyWith(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                else
                  for (
                    int index = 0;
                    index < currentSong.lyrics.length;
                    index++
                  )
                    _LyricLineItem(
                      key: _lyricKeys[index],
                      index: index,
                      lyrics: currentSong.lyrics,
                      position: position,
                    ),
                // Extra space at bottom to allow scrolling last items to center
                SizedBox(height: MediaQuery.of(context).size.height * 0.4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricLineItem extends StatelessWidget {
  final int index;
  final List<LyricLine> lyrics;
  final Duration position;

  const _LyricLineItem({
    super.key,
    required this.index,
    required this.lyrics,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final lyric = lyrics[index];
    final isCurrent =
        position >= lyric.time &&
        (index == lyrics.length - 1 || position < lyrics[index + 1].time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Row(
        children: [
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SvgPicture.asset(
                "assets/icons/play_icon.svg",
                colorFilter: const ColorFilter.mode(
                  AppColors.accentYellow,
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
              ),
            ),
          Expanded(
            child: Text(
              lyric.text,
              style: AppTextStyles.outfit(
                fontSize: isCurrent ? 22 : 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? Colors.white : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
