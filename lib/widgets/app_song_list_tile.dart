import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../services/media_menu_service.dart';
import 'app_widgets.dart';
import 'app_artwork.dart';

class AppSongListTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;
  final bool isActive;
  final Widget? trailing;

  const AppSongListTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onMenuTap,
    this.isActive = false,
    this.trailing,
  });

  String _formatDuration(int ms) {
    if (ms <= 0) return "0:00";
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => AppCenteredModal.show(
        context,
        title: song.title,
        items: MediaMenuService.buildSongActions(
          context: context,
          ref: ref,
          song: song,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: AppArtwork(
                  songId: song.id,
                  songPath: song.url,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isActive ? AppColors.accentBlue : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatDuration(song.duration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ] else ...[
              const SizedBox(width: 12),
              AppMenuButton(
                menuBuilder: (context) => MediaMenuService.buildSongMenuItems(
                  context: context,
                  ref: ref,
                  song: song,
                ),
                onSelected: (val) {
                  // Handled by MenuButton
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

