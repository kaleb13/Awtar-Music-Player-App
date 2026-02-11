import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/providers/library_provider.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/theme/app_theme.dart';
import 'package:awtar_music_player/widgets/app_widgets.dart';
import '../models/song.dart';

class PlayerScreenContent extends ConsumerWidget {
  const PlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.isPlaying;
    final Song? song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
                onTap: () =>
                    ref.read(screenProvider.notifier).state = AppScreen.home,
              ),
              Text(
                "Songs",
                style: AppTextStyles.caption.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const AppIconButton(icon: Icons.more_horiz),
            ],
          ),
          SizedBox(
            height:
                ((MediaQuery.of(context).size.width - 48)).clamp(0, 450) + 35,
          ), // Capped and reduced to prevent massive overflows on wide screens
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
                      song.artist,
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
                        color: song.isFavorite ? Colors.white : Colors.black54,
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
          const SizedBox(height: 20), // Reduced from 30
          Consumer(
            builder: (context, ref, child) {
              final position = ref.watch(
                playerProvider.select((s) => s.position),
              );
              final duration = ref.watch(
                playerProvider.select((s) => s.duration),
              );
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
          const SizedBox(height: 22), // Reduced from 28 to fix overflow
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
                size: 40, // Significantly increased from 32
                onTap: () => ref.read(playerProvider.notifier).next(),
              ),
              AppIconButton(
                icon: Icons.shuffle,
                size: 26, // Scaled up
                color: ref.watch(playerProvider).isShuffling
                    ? AppColors.primaryGreen
                    : AppColors.textGrey,
                onTap: () => ref.read(playerProvider.notifier).toggleShuffle(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${playerState.currentIndex + 1} / ${playerState.queue.length}",
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mainDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
        ],
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
              Expanded(
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
                      song.artist,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const AppIconButton(
                icon: Icons.more_horiz,
                color: AppColors.textGrey,
              ),
              const SizedBox(width: 8),
              const AppIconButton(
                icon: Icons.favorite,
                color: Colors.white24,
                size: 22,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class LyricsScreenContent extends ConsumerWidget {
  final void Function(double)? onDragUpdate;
  final void Function(double)? onDragEnd;

  const LyricsScreenContent({super.key, this.onDragUpdate, this.onDragEnd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider.select((s) => s.currentSong));
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        onDragUpdate?.call(details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        onDragEnd?.call(details.primaryVelocity ?? 0);
      },
      child: Container(
        color: AppColors.mainDark,
        padding: const EdgeInsets.only(top: 140),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels <= 0 &&
                  notification.dragDetails != null) {
                onDragUpdate?.call(notification.dragDetails!.delta.dy);
              }
            } else if (notification is ScrollEndNotification) {
              onDragEnd?.call(notification.dragDetails?.primaryVelocity ?? 0);
            }
            return false;
          },
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 160),
            itemCount: currentSong.lyrics.length,
            itemBuilder: (context, index) {
              return _LyricLineItem(index: index, lyrics: currentSong.lyrics);
            },
          ),
        ),
      ),
    );
  }
}

class _LyricLineItem extends ConsumerWidget {
  final int index;
  final List<LyricLine> lyrics;

  const _LyricLineItem({required this.index, required this.lyrics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((s) => s.position));
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
