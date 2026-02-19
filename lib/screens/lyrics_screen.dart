import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import 'package:awtar_music_player/providers/navigation_provider.dart';
import 'package:awtar_music_player/widgets/app_artwork.dart';
import 'package:awtar_music_player/widgets/media_edit_dialogs.dart';

import 'package:awtar_music_player/widgets/app_widgets.dart';
import 'player_screen.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final List<GlobalKey> _lyricKeys = [];
  int _prevIndex = -1;
  final bool _isUserScrolling = false;
  Timer? _seekTimer;

  void _startSeeking(bool forward) {
    _seekTimer?.cancel();
    _seekTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      ref
          .read(playerProvider.notifier)
          .seekRelative(
            forward ? const Duration(seconds: 5) : const Duration(seconds: -5),
          );
    });
  }

  void _stopSeeking() {
    _seekTimer?.cancel();
    _seekTimer = null;
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final library = ref.watch(libraryProvider);
    final song =
        playerState.currentSong ??
        (library.songs.isNotEmpty ? library.songs.first : null);
    final progress = ref.watch(scrollProgressProvider);

    // Sync keys with lyrics length
    if (song != null) {
      if (_lyricKeys.length != song.lyrics.length) {
        _lyricKeys.clear();
        for (int i = 0; i < song.lyrics.length; i++) {
          _lyricKeys.add(GlobalKey());
        }
      }
    }

    // Determine active index
    int currentIndex = -1;
    if (song != null && song.isSynced && song.lyrics.isNotEmpty) {
      for (int i = 0; i < song.lyrics.length; i++) {
        final lyric = song.lyrics[i];
        final nextTime = (i + 1 < song.lyrics.length)
            ? song.lyrics[i + 1].time
            : const Duration(hours: 99); // arbitrarily large

        if (playerState.position >= lyric.time &&
            playerState.position < nextTime) {
          currentIndex = i;
          break;
        }
      }
    }

    // Trigger Scroll Effect if index changed
    if (currentIndex != -1 && currentIndex != _prevIndex) {
      _prevIndex = currentIndex;
      // Schedule scroll after build
      if (!_isUserScrolling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              currentIndex < _lyricKeys.length &&
              _lyricKeys[currentIndex].currentContext != null) {
            Scrollable.ensureVisible(
              _lyricKeys[currentIndex].currentContext!,
              alignment: 0.5, // Center the item
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No song available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final opacity = progress.clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          // Header section
          Container(
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
                      // Tappable info section to go back
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(pageControllerProvider)
                                .animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutQuart,
                                );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppArtwork(
                                  songId: song.id,
                                  size: 50,
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
                                        color: Colors.black,
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
                            ],
                          ),
                        ),
                      ),

                      // Interactive Icons
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'edit_lyrics') {
                            MediaEditDialogs.showEditLyrics(context, ref, song);
                          } else if (value == 'open_queue') {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const QueueSheet(),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit_lyrics',
                            child: AppMenuEntry(
                              icon: Icons.edit_note,
                              label: "Edit Lyrics",
                            ),
                          ),
                          PopupMenuItem(
                            value: 'open_queue',
                            child: AppMenuEntry(
                              icon: Icons.queue_music,
                              label: "Queue",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      AppIconButton(
                        icon: Icons.skip_previous,
                        color: Colors.black54,
                        size: 26,
                        onTap: () =>
                            ref.read(playerProvider.notifier).previous(),
                        onLongPressStart: () => _startSeeking(false),
                        onLongPressEnd: _stopSeeking,
                      ),
                      const SizedBox(width: 8),
                      AppIconButton(
                        icon: Icons.skip_next,
                        color: Colors.black54,
                        size: 26,
                        onTap: () => ref.read(playerProvider.notifier).next(),
                        onLongPressStart: () => _startSeeking(true),
                        onLongPressEnd: _stopSeeking,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Drag handle also triggers the back animation
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
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                ],
              ),
            ),
          ),

          // Lyrics content
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                            leading: const Icon(
                              Icons.edit_note,
                              color: Colors.white,
                            ),
                            title: const Text(
                              "Edit Lyrics",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              MediaEditDialogs.showEditLyrics(
                                context,
                                ref,
                                song,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
                child: song.lyrics.isEmpty
                    ? Center(
                        child: Text(
                          "No lyrics available",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.grey.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollNotification) {
                          if (scrollNotification is UserScrollNotification) {
                            // User started scrolling, pause auto-scroll
                            // _isUserScrolling = true;
                            // Optionally set a timer to re-enable
                          }
                          return false;
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 40,
                          ),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (
                                int index = 0;
                                index < song.lyrics.length;
                                index++
                              )
                                GestureDetector(
                                  key: _lyricKeys[index],
                                  onTap: () {
                                    if (song.isSynced) {
                                      ref
                                          .read(playerProvider.notifier)
                                          .seek(song.lyrics[index].time);
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 28.0,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final lyric = song.lyrics[index];
                                        final isActuallySynced = song.isSynced;
                                        final isCurrent =
                                            isActuallySynced &&
                                            index == currentIndex;

                                        return Row(
                                          children: [
                                            if (isCurrent)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 12.0,
                                                ),
                                                child: SvgPicture.asset(
                                                  "assets/icons/play_icon.svg",
                                                  colorFilter:
                                                      const ColorFilter.mode(
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
                                                  color:
                                                      !isActuallySynced ||
                                                          isCurrent
                                                      ? Colors.white
                                                      : Colors.white
                                                            .withValues(alpha: 0.35),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              // Add padding at the bottom so the last line can be centered
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Bottom controls
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
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.1),
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

