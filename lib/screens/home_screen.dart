import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/player_provider.dart';
import '../providers/navigation_provider.dart';

import 'tabs/folders_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/albums_tab.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(homeTabProvider);
    switch (tab) {
      case HomeTab.folders:
        return const FoldersTab();
      case HomeTab.artists:
        return const ArtistsTab();
      case HomeTab.albums:
        return const AlbumsTab();
      default:
        return const HomeOverview();
    }
  }
}

class HomeOverview extends ConsumerWidget {
  const HomeOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Top Nav Bar
              const SizedBox(height: 20),
              // Top Nav Bar
              const AppTopBar(),
              const SizedBox(height: 10),
              const SizedBox(height: 30),

              // 1st Section: Popular Artists
              const AppSectionHeader(title: "Popular Artists"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                ],
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
              const SizedBox(height: 180), // Room for shrunken player + nav bar
            ],
          ),
        ),
      ),
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
    AppScreen openPlayer() =>
        ref.read(screenProvider.notifier).state = AppScreen.player;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: AppAlbumCard(
            onTap: openPlayer,
            title: "After Hours",
            artist: "The Weekend",
            imageUrl:
                "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400&auto=format&fit=crop",
            flexible: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppAlbumCard(
                      onTap: openPlayer,
                      title: "",
                      artist: "",
                      imageUrl:
                          "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200&auto=format&fit=crop",
                      isMini: true,
                      flexible: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppAlbumCard(
                      onTap: openPlayer,
                      title: "",
                      artist: "",
                      imageUrl:
                          "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200&auto=format&fit=crop",
                      isMini: true,
                      flexible: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppAlbumCard(
                      onTap: openPlayer,
                      title: "",
                      artist: "",
                      imageUrl:
                          "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop",
                      isMini: true,
                      flexible: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppAlbumCard(
                      onTap: openPlayer,
                      title: "",
                      artist: "",
                      imageUrl:
                          "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=200&auto=format&fit=crop",
                      isMini: true,
                      flexible: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSongRow(WidgetRef ref) {
    AppScreen openPlayer() =>
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
