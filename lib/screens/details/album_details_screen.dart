import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String imageUrl;

  const AlbumDetailsScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  Color? _dominantColor;
  bool _isLoadingColor = true;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.offset;
          });
        }
      });
    _updatePalette();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _updatePalette() async {
    try {
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
            NetworkImage(widget.imageUrl),
            size: const Size(200, 200),
            maximumColorCount: 20,
          );
      if (mounted) {
        setState(() {
          // Robust color selection: Try specific ones first, then any from palette
          final palette = generator.paletteColors.toList();
          palette.sort((a, b) => b.population.compareTo(a.population));

          _dominantColor =
              generator.vibrantColor?.color ??
              generator.darkVibrantColor?.color ??
              generator.dominantColor?.color ??
              generator.mutedColor?.color ??
              (palette.isNotEmpty ? palette.first.color : null) ??
              AppColors.surfaceDark;
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = AppColors.surfaceDark;
          _isLoadingColor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _dominantColor ?? AppColors.surfaceDark;

    // Calculate opacity based on scroll offset
    // 0.0 when at top, 1.0 when collapsed
    final double expandedHeight = MediaQuery.of(context).size.width * 0.66;
    final double threshold = expandedHeight - kToolbarHeight;
    final double opacity = (threshold > 0)
        ? (_scrollOffset / threshold).clamp(0.0, 1.0)
        : 0.0;

    // Use the same background color for AppBar to maintain consistency as requested
    Color darkerColor = backgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Fixed Background Image with Parallax & Zoom
          Positioned(
            top: -_scrollOffset * 0.4, // Move up at 40% speed of scroll
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.width,
            child: Transform.scale(
              scale:
                  1 +
                  (_scrollOffset * 0.0005).clamp(
                    0.0,
                    0.3,
                  ), // Zoom in slightly as we scroll
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      backgroundColor.withOpacity(0.6),
                      backgroundColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcOver,
                child: Image.network(widget.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                backgroundColor: darkerColor.withOpacity(opacity),
                title: Opacity(
                  opacity: opacity,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                centerTitle: false,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              // Spacer to push content down to overlap the image
              SliverToBoxAdapter(
                child: SizedBox(height: expandedHeight - kToolbarHeight),
              ),

              // Content Top Fade
              SliverToBoxAdapter(
                child: Container(
                  height: 100, // Taller fade for consistent transition
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        backgroundColor.withOpacity(0.0),
                        backgroundColor,
                      ],
                    ),
                  ),
                ),
              ),

              // Album Info Section (Play button moved to main Stack)
              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "16 tracks • 2h 16 min", // Mock data as per UI
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMain.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Song List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      color: backgroundColor,
                      child: _buildSongTile(index + 1),
                    );
                  },
                  childCount: 16, // Mock 16 tracks
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),

          // Floating Play Button - Moved to main Stack to ensure it's on top
          // It follows the scroll position to stay correctly aligned
          Positioned(
            top: (expandedHeight - kToolbarHeight + 130 - _scrollOffset - 28)
                .clamp(
                  kToolbarHeight - 28, // Stop it from going too high
                  MediaQuery.of(context).size.height,
                ),
            right: 40,
            child: Opacity(
              // Hide when it goes under the app bar if needed, or keep it
              opacity: (_scrollOffset > (expandedHeight - kToolbarHeight + 60))
                  ? 0.0
                  : 1.0,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: HSLColor.fromColor(backgroundColor)
                    .withLightness(
                      (HSLColor.fromColor(backgroundColor).lightness - 0.15)
                          .clamp(0.0, 1.0),
                    )
                    .toColor(),
                shape: const CircleBorder(),
                child: SvgPicture.asset(
                  "assets/icons/play_icon.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  width: 22,
                  height: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int index) {
    // Mock data for variation
    final songTitles = [
      "Menfes'hn",
      "Mezmure ante neh",
      "Semay chewa new",
      "Satnekagn Alwta",
      "Smu yetsena gnb nw",
      "Ssemaw",
      "Kiber Yihunilish",
      "Yemigeba",
      "Eyesus",
      "Beresu Kena",
      "Wodaje",
      "Yene Wub",
      "Fikri",
      "Selam",
      "Tesfa",
      "Hiwot",
    ];
    final title = index <= songTitles.length
        ? songTitles[index - 1]
        : "Track $index";

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Text(
        index.toString(),
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        widget.artist,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      trailing: Icon(
        Icons.more_vert,
        color: Colors.white.withOpacity(0.5),
        size: 20,
      ),
      onTap: () {},
    );
  }
}
