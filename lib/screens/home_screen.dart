import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/player_provider.dart';
import '../providers/navigation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = ref.watch(sampleSongProvider);

    // Calculate progress for mini bar
    final progress = playerState.duration.inSeconds > 0
        ? playerState.position.inSeconds / playerState.duration.inSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Top Nav Bar
                  Row(
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
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          AppIconButton(
                            icon: Icons.search,
                            color: Colors.white,
                          ),
                          SizedBox(width: 16),
                          AppIconButton(
                            icon: Icons.more_horiz,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Second Navbar (Tabs)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTabItem("Home", true),
                      _buildTabItem("Folders", false),
                      _buildTabItem("Artists", false),
                      _buildTabItem("Albums", false),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 1st Section: Popular Artists
                  const AppSectionHeader(title: "Popular Artists"),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildArtistItem(
                          ref,
                          "The Weekend",
                          "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200&auto=format&fit=crop",
                        ),
                        const SizedBox(width: 20),
                        _buildArtistItem(
                          ref,
                          "Drake",
                          "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop",
                        ),
                        const SizedBox(width: 20),
                        _buildArtistItem(
                          ref,
                          "Post Malone",
                          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=200&auto=format&fit=crop",
                        ),
                        const SizedBox(width: 20),
                        _buildArtistItem(
                          ref,
                          "Rihanna",
                          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 2nd Section: Popular Albums
                  const AppSectionHeader(title: "Popular Albums"),
                  const SizedBox(height: 20),
                  _buildAlbumGrid(ref),
                  const SizedBox(height: 40),

                  // 3rd Section: Most Played
                  const AppSectionHeader(title: "Most Played"),
                  const SizedBox(height: 20),
                  _buildSongRow(ref),
                  const SizedBox(height: 40),

                  // 4th Section: Recently Played
                  const AppSectionHeader(title: "Recently Played"),
                  const SizedBox(height: 20),
                  _buildSongRow(ref),
                  const SizedBox(height: 40),

                  // 5th Section: Summary
                  const AppSectionHeader(title: "Monthly Summary"),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Column(
                      children: [
                        AppSummaryItem(
                          label: "Time played this month",
                          value: "24h 15m",
                        ),
                        SizedBox(height: 20),
                        AppSummaryItem(
                          label: "Total time played",
                          value: "156h 40m",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Room for mini player
                ],
              ),
            ),

            // Floating Mini Player pinned at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: AppMiniPlayer(
                title: song.title,
                artist: song.artist,
                imageUrl: song.albumArt,
                isPlaying: playerState.isPlaying,
                progress: progress,
                onTap: () =>
                    ref.read(screenProvider.notifier).state = AppScreen.player,
                onPlayPause: () {
                  if (playerState.isPlaying) {
                    ref.read(playerProvider.notifier).pause();
                  } else {
                    ref.read(playerProvider.notifier).play(song);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMain.copyWith(
            color: isActive ? AppColors.accentYellow : AppColors.textGrey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArtistItem(WidgetRef ref, String name, String url) {
    return AppArtistCircle(
      name: name,
      imageUrl: url,
      onTap: () => ref.read(screenProvider.notifier).state = AppScreen.player,
    );
  }

  Widget _buildAlbumGrid(WidgetRef ref) {
    final openPlayer = () =>
        ref.read(screenProvider.notifier).state = AppScreen.player;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured big album
        Expanded(
          flex: 1,
          child: AppAlbumCard(
            onTap: openPlayer,
            title: "After Hours",
            artist: "The Weekend",
            imageUrl:
                "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400&auto=format&fit=crop",
            size: 160,
          ),
        ),
        const SizedBox(width: 16),
        // 2x2 grid of small albums
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 200,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                AppAlbumCard(
                  onTap: openPlayer,
                  title: "",
                  artist: "",
                  imageUrl:
                      "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200&auto=format&fit=crop",
                  isMini: true,
                ),
                AppAlbumCard(
                  onTap: openPlayer,
                  title: "",
                  artist: "",
                  imageUrl:
                      "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200&auto=format&fit=crop",
                  isMini: true,
                ),
                AppAlbumCard(
                  onTap: openPlayer,
                  title: "",
                  artist: "",
                  imageUrl:
                      "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop",
                  isMini: true,
                ),
                AppAlbumCard(
                  onTap: openPlayer,
                  title: "",
                  artist: "",
                  imageUrl:
                      "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=200&auto=format&fit=crop",
                  isMini: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongRow(WidgetRef ref) {
    final openPlayer = () =>
        ref.read(screenProvider.notifier).state = AppScreen.player;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppAlbumCard(
            onTap: openPlayer,
            title: "God's Plan",
            artist: "Drake",
            imageUrl:
                "https://images.unsplash.com/photo-1621112904887-419379ce6824?q=80&w=200&auto=format&fit=crop",
            size: 100,
          ),
          const SizedBox(width: 16),
          AppAlbumCard(
            onTap: openPlayer,
            title: "Blinding Lights",
            artist: "The Weekend",
            imageUrl:
                "https://images.unsplash.com/photo-1514525253361-bee8a187449b?q=80&w=200&auto=format&fit=crop",
            size: 100,
          ),
          const SizedBox(width: 16),
          AppAlbumCard(
            onTap: openPlayer,
            title: "Circles",
            artist: "Post Malone",
            imageUrl:
                "https://images.unsplash.com/photo-1420161907993-955a19bb32d1?q=80&w=200&auto=format&fit=crop",
            size: 100,
          ),
          const SizedBox(width: 16),
          AppAlbumCard(
            onTap: openPlayer,
            title: "Diamonds",
            artist: "Rihanna",
            imageUrl:
                "https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=200&auto=format&fit=crop",
            size: 100,
          ),
        ],
      ),
    );
  }
}
