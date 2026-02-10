import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// PaletteGenerator removed
import '../theme/app_theme.dart';
import '../models/song.dart';
import '../providers/search_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/palette_service.dart';
import 'app_artwork.dart';
import '../screens/settings_screen.dart';

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
        child: Center(
          child: isPlaying
              ? SvgPicture.asset(
                  AppAssets.pause,
                  width: size * 0.5,
                  height: size * 0.5,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                )
              : SvgPicture.asset(
                  AppAssets.play,
                  width: size * 0.5,
                  height: size * 0.5,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
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

class AppPremiumCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? badgeText;
  final bool showMenu;
  final double size;
  final VoidCallback? onTap;
  final bool isCircular;
  final bool isPortrait;
  final bool flexible;
  final Widget? artwork;
  final int? songId;

  const AppPremiumCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl = "",
    this.badgeText,
    this.showMenu = false,
    this.size = 90,
    this.onTap,
    this.isCircular = false,
    this.isPortrait = false,
    this.flexible = false,
    this.artwork,
    this.songId,
  });

  @override
  State<AppPremiumCard> createState() => _AppPremiumCardState();
}

class _AppPremiumCardState extends State<AppPremiumCard> {
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant AppPremiumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.songId != widget.songId) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    final color = await PaletteService.getColor(
      widget.imageUrl,
      songId: widget.songId,
    );
    if (mounted) {
      setState(() {
        _dominantColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _dominantColor ?? AppColors.accentYellow;
    final double borderRadiusInner = widget.isCircular
        ? (widget.flexible ? 1000 : widget.size)
        : 24;
    final double borderRadiusOuter = widget.isCircular
        ? (widget.flexible ? 1000 : widget.size)
        : 28;

    Widget imageContainer = Container(
      width: widget.flexible ? double.infinity : widget.size,
      height: widget.flexible
          ? null
          : (widget.isPortrait ? widget.size * 1.3 : widget.size),
      decoration: BoxDecoration(
        shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircular
            ? null
            : BorderRadius.circular(borderRadiusOuter),
        border: Border.all(color: borderColor.withOpacity(0.9), width: 2.2),
      ),
      padding: const EdgeInsets.all(5),
      child: ClipRRect(
        borderRadius: widget.isCircular
            ? BorderRadius.circular(borderRadiusOuter)
            : BorderRadius.circular(borderRadiusInner),
        child:
            widget.artwork ??
            (widget.songId != null
                ? AppArtwork(
                    songId: widget.songId!,
                    size: widget.size,
                    fit: widget.isPortrait ? BoxFit.cover : BoxFit.cover,
                  )
                : (widget.imageUrl.isNotEmpty
                      ? (widget.flexible
                            ? AspectRatio(
                                aspectRatio: widget.isPortrait
                                    ? 1.0 / 1.3
                                    : 1.0,
                                child: Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                width: widget.size,
                                height: widget.isPortrait
                                    ? widget.size * 1.3
                                    : widget.size,
                              ))
                      : Container(
                          color: AppColors.surfaceDark,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white24,
                          ),
                        ))),
      ),
    );

    if (widget.flexible) {
      imageContainer = AspectRatio(
        aspectRatio: widget.isPortrait ? 1.0 / 1.3 : 1.0,
        child: imageContainer,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              imageContainer,
              // Badge (Play Time or Menu)
              if (widget.badgeText != null || widget.showMenu)
                Positioned(
                  top: 4,
                  right: -4,
                  child: Container(
                    padding: widget.showMenu
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                        : const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0F),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.showMenu
                        ? const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            size: 14,
                          )
                        : Text(
                            widget.badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: widget.flexible ? null : widget.size + 20,
            child: Column(
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMain.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppPopularArtistCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String imageUrl;
  final String playTime;
  final VoidCallback onTap;
  final Widget? artwork;
  final int? songId;

  const AppPopularArtistCard({
    super.key,
    required this.name,
    this.subtitle,
    required this.imageUrl,
    required this.playTime,
    required this.onTap,
    this.artwork,
    this.songId,
  });

  @override
  Widget build(BuildContext context) {
    return AppPremiumCard(
      title: name,
      subtitle: subtitle,
      imageUrl: imageUrl,
      badgeText: playTime,
      onTap: onTap,
      isCircular: true,
      artwork: artwork,
      songId: songId,
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
  final Widget? artwork;
  final int? songId;

  const AppAlbumCard({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.size = 140,
    this.isMini = false,
    this.flexible = false,
    this.onTap,
    this.artwork,
    this.songId,
  });

  @override
  Widget build(BuildContext context) {
    return AppPremiumCard(
      title: title,
      subtitle: artist,
      imageUrl: imageUrl,
      size: size,
      flexible: flexible,
      onTap: onTap,
      artwork: artwork,
      songId: songId,
    );
  }
}

class AppSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final bool isTrendPositive;

  const AppSummaryItem({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.isTrendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.2,
              fontSize: 10,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isTrendPositive
                                ? AppColors.primaryGreen
                                : Colors.redAccent)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrendPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color: isTrendPositive
                            ? AppColors.primaryGreen
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTrendPositive
                              ? AppColors.primaryGreen
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppMiniPlayer extends StatefulWidget {
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
  State<AppMiniPlayer> createState() => _AppMiniPlayerState();
}

class _AppMiniPlayerState extends State<AppMiniPlayer> {
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _updatePalette();
  }

  @override
  void didUpdateWidget(covariant AppMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    final color = await PaletteService.getColor(widget.imageUrl);
    if (mounted) {
      setState(() {
        _dominantColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _dominantColor ?? AppColors.accentYellow;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
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
                  widthFactor: widget.progress.clamp(0.0, 1.0),
                  child: Container(height: 3, color: AppColors.primaryGreen),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Stroke Effect Cover Image
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor.withOpacity(0.9),
                          width: 2.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.5),
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.artist,
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
                      isPlaying: widget.isPlaying,
                      onTap: widget.onPlayPause,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                AppAssets.logo,
                height: 28,
                width: 35,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12), // Adjusted gap
              Text(
                "Awtar",
                style: AppTextStyles.titleMedium.copyWith(
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppSearchBar extends ConsumerWidget {
  final bool autoFocus;
  const AppSearchBar({super.key, this.autoFocus = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: TextField(
            autofocus: autoFocus,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
              if (ref.read(mainTabProvider) != MainTab.discover) {
                ref.read(mainTabProvider.notifier).state = MainTab.discover;
              }
            },
            onTap: () {
              if (ref.read(mainTabProvider) != MainTab.discover) {
                ref.read(mainTabProvider.notifier).state = MainTab.discover;
              }
            },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search songs, artists, albums...",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  AppAssets.search,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class AppPromoBanner extends ConsumerStatefulWidget {
  const AppPromoBanner({super.key});

  @override
  ConsumerState<AppPromoBanner> createState() => _AppPromoBannerState();
}

class _AppPromoBannerState extends ConsumerState<AppPromoBanner> {
  Color? _dominantColor;

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final bannerSong = libraryState.bannerSong;
    ref.listen<Song?>(libraryProvider.select((s) => s.bannerSong), (
      prev,
      next,
    ) {
      if (next != null) {
        final url =
            next.albumArt ??
            "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=800";
        _updatePalette(url, songId: next.id);
      }
    });

    if (bannerSong == null) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.mainDarkLight,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accentYellow),
        ),
      );
    }

    final imageUrl =
        bannerSong.albumArt ??
        "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=800";

    // Initial call if _dominantColor is null
    if (_dominantColor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePalette(imageUrl, songId: bannerSong.id);
      });
    }

    final borderColor = _dominantColor ?? AppColors.accentYellow;

    return GestureDetector(
      onTap: () => ref.read(playerProvider.notifier).play(bannerSong),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: borderColor.withOpacity(0.9), width: 2.5),
        ),
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: bannerSong.albumArt != null
                    ? AppArtwork(songId: bannerSong.id, fit: BoxFit.cover)
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.mainDarkLight,
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bannerSong.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${bannerSong.artist} • ${bannerSong.album ?? 'Single'}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePalette(String imageUrl, {int? songId}) async {
    final color = await PaletteService.getColor(imageUrl, songId: songId);
    if (mounted) {
      setState(() {
        _dominantColor = color;
      });
    }
  }
}
