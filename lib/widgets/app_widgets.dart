import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class AppPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final Color iconColor;

  const AppPlayButton({
    super.key,
    required this.isPlaying,
    required this.onTap,
    this.size = 64,
    this.color = Colors.black,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;
  final bool isCircle;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.size = 24,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, color: color ?? Colors.black, size: size);

    if (isCircle) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      );
    }

    return GestureDetector(onTap: onTap, child: child);
  }
}

class AppProgressBar extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const AppProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.activeColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: activeColor,
        inactiveTrackColor: activeColor.withOpacity(0.1),
        thumbColor: activeColor,
      ),
      child: Slider(
        value: value,
        max: max.clamp(0.001, double.infinity),
        onChanged: onChanged,
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const AppSectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    if (onSeeAll == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              "See all",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
      ],
    );
  }
}

class AppArtistCircle extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback? onTap;

  const AppArtistCircle({
    super.key,
    required this.name,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }
}

class AppAlbumCard extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final double size;
  final bool isMini;
  final bool flexible;
  final VoidCallback? onTap;

  const AppAlbumCard({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.size = 140,
    this.isMini = false,
    this.flexible = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: flexible
                ? AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
          ),
          if (!isMini) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: flexible ? double.infinity : size,
              child: Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: flexible ? double.infinity : size,
              child: Text(
                artist,
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppSummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const AppSummaryItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.accentYellow,
          ),
        ),
      ],
    );
  }
}

class AppMiniPlayer extends ConsumerWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;

  const AppMiniPlayer({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Mini Progress Bar at the bottom
              Align(
                alignment: Alignment.bottomLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(height: 3, color: AppColors.accentYellow),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artist,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const AppIconButton(
                      icon: Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    AppPlayButton(
                      size: 40,
                      color: Colors.white,
                      iconColor: Colors.black,
                      isPlaying: isPlaying,
                      onTap: onPlayPause,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accentYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Awtar",
                style: AppTextStyles.titleMedium.copyWith(
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              AppIconButton(icon: Icons.search, color: Colors.white),
              SizedBox(width: 16),
              AppIconButton(
                icon: Icons.more_vert, // Vertical Menu
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
