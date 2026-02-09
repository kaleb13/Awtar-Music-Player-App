import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/color_aware_album_card.dart';
import 'album_details_screen.dart'; // Import this for navigation

class ArtistDetailsScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ArtistDetailsScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<ArtistDetailsScreen> createState() => _ArtistDetailsScreenState();
}

class _ArtistDetailsScreenState extends State<ArtistDetailsScreen> {
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
          // Gradient Fade at Bottom of Screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor.withOpacity(0.0),
                  backgroundColor.withOpacity(0.5),
                  backgroundColor,
                ],
                stops: const [0.0, 0.5, 1.0],
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
                    widget.name,
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

              // Content Top Fade (Gradient)
              SliverToBoxAdapter(
                child: Container(
                  height: 100, // Taller fade for smoother transition
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

              // Artist Info Section (Name, Stats, Button, Bio)
              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "5 albums • 60 tracks • 6h 31 min", // Mock data
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMain.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1E1E2C,
                          ).withOpacity(0.6), // Dark button
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        child: const Text("SHUFFLE PLAY"),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No biography found for the artist.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Albums List Horizontal
              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    height: 185, // Increased from 170 to fix overflow
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: 4, // Mock
                      separatorBuilder: (c, i) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        // Mock album data
                        final albums = [
                          {
                            "title": "Memihiru",
                            "year": "2023",
                            "img":
                                "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300",
                          },
                          {
                            "title": "Tayilign",
                            "year": "2016",
                            "img":
                                "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=300",
                          },
                          {
                            "title": "Liqe Kahenie",
                            "year": "2000",
                            "img":
                                "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=300",
                          },
                          {
                            "title": "Bereket",
                            "year": "2024",
                            "img":
                                "https://images.unsplash.com/photo-1514525253440-b393452e8d2e?q=80&w=300",
                          },
                        ];
                        final album = albums[index];
                        return ColorAwareAlbumCard(
                          title: album['title']!,
                          artist: "${album['year']!} • ${widget.name}",
                          imageUrl: album['img']!,
                          size: 100, // Slightly smaller to fit better
                          showThreeDotsMenu: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlbumDetailsScreen(
                                  title: album["title"]!,
                                  artist: widget.name,
                                  imageUrl: album["img"]!,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Center(
                    child: Text(
                      "TOP TRACKS",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Top Tracks List
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Container(
                    color: backgroundColor,
                    child: _buildSongItem(index + 1),
                  );
                }, childCount: 5), // Limit to 5
              ),

              SliverToBoxAdapter(
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Center(
                    child: Text(
                      "TRACKS",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // All Tracks from Albums
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Mock logic to group by album
                  String albumName = "Album";
                  String imgUrl = "";

                  if (index < 4) {
                    albumName = "Memihiru";
                    imgUrl =
                        "https://plus.unsplash.com/premium_photo-1664303847960-586318f59035?q=80&w=300";
                  } else if (index < 8) {
                    albumName = "Tayilign";
                    imgUrl =
                        "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=300";
                  } else if (index < 12) {
                    albumName = "Liqe Kahenie";
                    imgUrl =
                        "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=300";
                  } else {
                    albumName = "Bereket";
                    imgUrl =
                        "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=300";
                  }

                  return Container(
                    color: backgroundColor,
                    child: _buildAllTracksItem(index + 1, albumName, imgUrl),
                  );
                }, childCount: 16),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(int index) {
    // Mock songs
    final songs = [
      "Ssemaw",
      "Satnekagn Alwta",
      "Menfes'hn",
      "Mezmure ante neh",
      "Semay chewa new",
      "Kiber Yihunilish",
      "Yemigeba",
      "Eyesus",
      "Beresu Kena",
      "Wodaje",
    ];
    final title = index <= songs.length ? songs[index - 1] : "Track $index";
    // Mock play counts descending
    final playCount = (60 - index * 4);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text(
        "$index",
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: NetworkImage(widget.imageUrl), // In real app, song cover
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Text(
        "$playCount", // Play count mock
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      onTap: () {},
    );
  }

  Widget _buildAllTracksItem(int index, String albumName, String imageUrl) {
    // Mock track titles for variety
    final titles = [
      "Track A $index",
      "Track B $index",
      "Track C $index",
      "Track D $index",
    ];
    final title = titles[index % titles.length];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        albumName, // Showing album name as subtitle
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
