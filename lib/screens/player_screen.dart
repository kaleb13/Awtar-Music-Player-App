import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtart_music_player/providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerScreenContent extends ConsumerWidget {
  const PlayerScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back),
            Text(
              "Songs",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Icon(Icons.more_horiz),
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
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  song.artist,
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.favorite_border, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    "Saved",
                    style: TextStyle(
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            activeTrackColor: Colors.black,
            inactiveTrackColor: Colors.black.withOpacity(0.1),
            thumbColor: Colors.black,
          ),
          child: Slider(
            value: playerState.position.inSeconds.toDouble(),
            max: playerState.duration.inSeconds.toDouble().clamp(0.001, 10000),
            onChanged: (v) {
              ref
                  .read(playerProvider.notifier)
                  .seek(Duration(seconds: v.toInt()));
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(playerState.position),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              _formatDuration(playerState.duration),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.repeat, color: Colors.grey),
            const Icon(Icons.skip_previous, size: 36),
            GestureDetector(
              onTap: () {
                if (playerState.isPlaying) {
                  ref.read(playerProvider.notifier).pause();
                } else {
                  ref.read(playerProvider.notifier).play(song);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const Icon(Icons.skip_next, size: 36),
            const Icon(Icons.shuffle, color: Colors.grey),
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
        Row(
          children: [
            const SizedBox(width: 62),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    song.artist,
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Colors.grey, size: 24),
            const SizedBox(width: 16),
            const Icon(Icons.favorite, color: Color(0xFF1DB954), size: 22),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          ],
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
      color: Colors.black,
      padding: const EdgeInsets.only(top: 140), // Space for mini header
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: ListView.builder(
          physics: progress < 0.9
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
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
                        color: Color(0xFFEEE544),
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      lyric.text,
                      style: GoogleFonts.outfit(
                        fontSize: isCurrent ? 22 : 18,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrent
                            ? Colors.white
                            : Colors.grey.withOpacity(0.4),
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
