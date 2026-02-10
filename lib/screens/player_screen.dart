import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/library_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:awtart_music_player/theme/app_theme.dart';
import 'package:awtart_music_player/widgets/app_widgets.dart';
import '../models/song.dart';

class PlayerScreenContent extends ConsumerWidget {
  const PlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.isPlaying;
    final Song? song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 15),
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
        SizedBox(height: (MediaQuery.of(context).size.width - 48) + 70),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  song.artist,
                  style: AppTextStyles.bodyMain.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Saved",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      _formatDuration(duration),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppIconButton(
              icon: playerState.repeatMode == RepeatMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
              color: playerState.repeatMode != RepeatMode.off
                  ? AppColors.primaryGreen
                  : AppColors.textGrey,
              onTap: () => ref.read(playerProvider.notifier).toggleRepeat(),
            ),
            AppIconButton(
              icon: Icons.skip_previous,
              size: 36,
              onTap: () => ref.read(playerProvider.notifier).previous(),
            ),
            AppPlayButton(
              isPlaying: isPlaying,
              onTap: () =>
                  ref.read(playerProvider.notifier).togglePlayPause(song),
            ),
            AppIconButton(
              icon: Icons.skip_next,
              size: 36,
              onTap: () => ref.read(playerProvider.notifier).next(),
            ),
            AppIconButton(
              icon: Icons.shuffle,
              color: ref.watch(playerProvider).isShuffling
                  ? AppColors.primaryGreen
                  : AppColors.textGrey,
              onTap: () => ref.read(playerProvider.notifier).toggleShuffle(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  song.artist.split(' ').first,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const AppIconButton(
              icon: Icons.queue_music,
              color: Colors.white70,
              size: 24,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 62),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                  Text(song.artist, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const AppIconButton(
              icon: Icons.more_horiz,
              color: AppColors.textGrey,
            ),
            const SizedBox(width: 16),
            const AppIconButton(
              icon: Icons.favorite,
              color: Colors.white24,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
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
    final playerState = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final song =
        playerState.currentSong ??
        (library.songs.isNotEmpty ? library.songs.first : null);
    if (song == null) return const SizedBox.shrink();

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
        child: Opacity(
          opacity: 1.0,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels <= 0 &&
                    notification.dragDetails != null) {
                  onDragUpdate?.call(notification.dragDetails!.delta.dy);
                }
              } else if (notification is ScrollEndNotification) {
                // We only care if we were potentially dragging
                onDragEnd?.call(notification.dragDetails?.primaryVelocity ?? 0);
              }
              return false;
            },
            child: ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 160),
              itemCount: song.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = song.lyrics[index];
                final isCurrent =
                    playerState.position >= lyric.time &&
                    (index == song.lyrics.length - 1 ||
                        playerState.position < song.lyrics[index + 1].time);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 28.0),
                  child: Row(
                    children: [
                      if (isCurrent)
                        Padding(
                          padding: EdgeInsets.only(right: 12.0),
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
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCurrent
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
