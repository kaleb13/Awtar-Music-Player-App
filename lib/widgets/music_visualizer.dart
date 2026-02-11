import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awtar_music_player/providers/player_provider.dart';
import 'package:awtar_music_player/theme/app_theme.dart';

class MusicVisualizer extends ConsumerStatefulWidget {
  const MusicVisualizer({super.key});

  @override
  ConsumerState<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends ConsumerState<MusicVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create 9 staggered animations
    for (int i = 0; i < 9; i++) {
      final start = i * 0.08; // Tighter stagger for more bars
      final end = start + 0.5;
      _animations.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 4, end: 18), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 18, end: 4), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start,
              end > 1.0 ? 1.0 : end,
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    if (isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }

    // If stopped, show a static mid-height
    final bool showStatic = !isPlaying;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(9, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double height = showStatic
                ? (index % 2 == 0 ? 10 : 6).toDouble()
                : _animations[index].value;

            return Container(
              width: 2.5,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
