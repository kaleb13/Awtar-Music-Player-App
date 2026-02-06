import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:awtart_music_player/theme/app_theme.dart';
import 'package:awtart_music_player/widgets/app_widgets.dart';

class PlayerScreenContent extends ConsumerWidget {
  const PlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);

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
        const Spacer(),
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
                color: AppColors.primaryGreen,
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
        AppProgressBar(
          value: playerState.position.inSeconds.toDouble(),
          max: playerState.duration.inSeconds.toDouble(),
          onChanged: (v) => ref
              .read(playerProvider.notifier)
              .seek(Duration(seconds: v.toInt())),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(playerState.position),
              style: AppTextStyles.caption,
            ),
            Text(
              _formatDuration(playerState.duration),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const AppIconButton(icon: Icons.repeat, color: AppColors.textGrey),
            const AppIconButton(icon: Icons.skip_previous, size: 36),
            AppPlayButton(
              isPlaying: playerState.isPlaying,
              onTap: () {
                if (playerState.isPlaying) {
                  ref.read(playerProvider.notifier).pause();
                } else {
                  ref.read(playerProvider.notifier).play(song);
                }
              },
            ),
            const AppIconButton(icon: Icons.skip_next, size: 36),
            const AppIconButton(icon: Icons.shuffle, color: AppColors.textGrey),
          ],
        ),
        const SizedBox(height: 20),
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
    final song = ref.watch(sampleSongProvider);

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
              color: AppColors.primaryGreen,
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
  const LyricsScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);
    final progress = ref.watch(scrollProgressProvider);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 140),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: ListView.builder(
          physics: progress < 0.9
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
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
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(
                        Icons.play_arrow,
                        color: AppColors.accentYellow,
                        size: 20,
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
                            ? AppColors.textMain
                            : AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
