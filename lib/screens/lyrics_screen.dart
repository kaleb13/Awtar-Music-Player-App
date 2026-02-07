import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/player_provider.dart';
import 'package:awtart_music_player/providers/navigation_provider.dart';

class LyricsScreen extends ConsumerWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);
    final progress = ref.watch(scrollProgressProvider);

    // Fade in lyrics as we slide up
    final opacity = progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          // New Top Info Card (Matches the new UI)
          GestureDetector(
            onTap: () {
              ref
                  .read(pageControllerProvider)
                  .animateToPage(
                    0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart,
                  );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song.albumArt,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                style: GoogleFonts.outfit(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz,
                          color: Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFF1DB954),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Page indicator dots
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
                ),
              ),
            ),
          ),
          // Lyrics Section
          Expanded(
            child: ListView.builder(
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
                        Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: SvgPicture.asset(
                            "assets/icons/play_icon.svg",
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFEEE544),
                              BlendMode.srcIn,
                            ),
                            width: 20,
                            height: 20,
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
          // Bottom Controls (Matches the new UI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(playerProvider.notifier).togglePlayPause(song);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: playerState.isPlaying
                          ? SvgPicture.asset(
                              "assets/icons/pause_icon.svg",
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            )
                          : SvgPicture.asset(
                              "assets/icons/play_icon.svg",
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                              width: 32,
                              height: 32,
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 4,
                        ),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: playerState.position.inSeconds.toDouble(),
                        max: playerState.duration.inSeconds.toDouble().clamp(
                          0.001,
                          double.infinity,
                        ),
                        onChanged: (value) {
                          ref
                              .read(playerProvider.notifier)
                              .seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.queue_music,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
