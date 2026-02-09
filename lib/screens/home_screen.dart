import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../providers/navigation_provider.dart';

import 'tabs/folders_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/albums_tab.dart';

import 'details/artist_details_screen.dart';

import 'details/album_details_screen.dart';
import '../widgets/color_aware_album_card.dart'; // Add import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 20,
                ), // Reduced from 24
                child: AppTopBar(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AppSearchBar(),
              ),
              const SizedBox(height: 20),
              const TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: AppColors.accentYellow,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelPadding: EdgeInsets.symmetric(horizontal: 4),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: "LIBRARY"), // Changed content
                  Tab(text: "FOLDERS"),
                  Tab(text: "ARTISTS"),
                  Tab(text: "ALBUMS"),
                ],
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: TabBarView(
                  children: [
                    HomeOverviewContent(),
                    FoldersTab(),
                    ArtistsTab(),
                    AlbumsTab(),
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

class HomeOverviewContent extends ConsumerWidget {
  const HomeOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      // Removed global padding to allow full-width scrolling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppPromoBanner(),
          ),
          const SizedBox(height: 30),
          // 1st Section: Popular Artists
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Popular Artists"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildArtistItem(
                  context,
                  ref,
                  "The Weekend",
                  "https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=300",
                ),
                _buildArtistItem(
                  context,
                  ref,
                  "Drake",
                  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300",
                ),
                _buildArtistItem(
                  context,
                  ref,
                  "Post Malone",
                  "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=200&auto=format&fit=crop",
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 2nd Section: Popular Albums
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Popular Albums"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildAlbumGrid(context, ref),
          ),
          const SizedBox(height: 40),

          // 3rd Section: Most Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Most Played"),
          ),
          const SizedBox(height: 20),
          _buildSongRow(ref),
          const SizedBox(height: 40),

          // 4th Section: Recently Played
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Recently Played"),
          ),
          const SizedBox(height: 20),
          _buildSongRow(ref),
          const SizedBox(height: 40),

          // 5th Section: Summary
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: AppSectionHeader(title: "Monthly Summary"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
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
                  AppSummaryItem(label: "Total time played", value: "156h 40m"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 180), // Room for shrunken player + nav bar
        ],
      ),
    );
  }

  Widget _buildArtistItem(
    BuildContext context,
    WidgetRef ref,
    String name,
    String url,
  ) {
    return ColorAwareAlbumCard(
      title: name,
      artist: "",
      imageUrl: url,
      size: 100,
      onTap: () {
        ref.read(bottomNavVisibleProvider.notifier).state = false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ArtistDetailsScreen(name: name, imageUrl: url),
          ),
        ).then((_) {
          ref.read(bottomNavVisibleProvider.notifier).state = true;
        });
      },
    );
  }

  Widget _buildAlbumGrid(BuildContext context, WidgetRef ref) {
    void openAlbum(String title, String artist, String img) {
      ref.read(bottomNavVisibleProvider.notifier).state = false;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AlbumDetailsScreen(title: title, artist: artist, imageUrl: img),
        ),
      ).then((_) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      });
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Stretch to match heights
        children: [
          // Large Featured Album
          Expanded(
            flex: 5,
            child: ColorAwareAlbumCard(
              onTap: () => openAlbum(
                "After Hours",
                "The Weekend",
                "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400&auto=format&fit=crop",
              ),
              title: "After Hours",
              artist: "The Weekend",
              imageUrl:
                  "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=400&auto=format&fit=crop",
              flexible: true,
            ),
          ),
          const SizedBox(width: 12),
          // 2x2 Grid of Smaller Albums
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ColorAwareAlbumCard(
                        onTap: () => openAlbum(
                          "Scorpion",
                          "Drake",
                          "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200&auto=format&fit=crop",
                        ),
                        title: "Scorpion",
                        artist: "Drake",
                        imageUrl:
                            "https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=200&auto=format&fit=crop",
                        isMini: true,
                        flexible: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ColorAwareAlbumCard(
                        onTap: () => openAlbum(
                          "Hollywood's Bleeding",
                          "Post Malone",
                          "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200&auto=format&fit=crop",
                        ),
                        title: "Hollywood's",
                        artist: "Post Malone",
                        imageUrl:
                            "https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=200&auto=format&fit=crop",
                        isMini: true,
                        flexible: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ColorAwareAlbumCard(
                        onTap: () => openAlbum(
                          "Anti",
                          "Rihanna",
                          "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop",
                        ),
                        title: "Anti",
                        artist: "Rihanna",
                        imageUrl:
                            "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop",
                        isMini: true,
                        flexible: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ColorAwareAlbumCard(
                        onTap: () => openAlbum(
                          "Astroworld",
                          "Travis Scott",
                          "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=200&auto=format&fit=crop",
                        ),
                        title: "Astroworld",
                        artist: "Travis Scott",
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
      ),
    );
  }

  Widget _buildSongRow(WidgetRef ref) {
    AppScreen openPlayer() =>
        ref.read(screenProvider.notifier).state = AppScreen.player;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          ColorAwareAlbumCard(
            onTap: openPlayer,
            title: "God's Plan",
            artist: "Drake",
            imageUrl:
                "https://images.unsplash.com/photo-1621112904887-419379ce6824?q=80&w=200&auto=format&fit=crop",
            size: 100, // Matched with Popular Artists
          ),
          const SizedBox(width: 16),
          ColorAwareAlbumCard(
            onTap: openPlayer,
            title: "Blinding Lights",
            artist: "The Weekend",
            imageUrl:
                "https://images.unsplash.com/photo-1549830729-197e88c03732?q=80&w=300",
            size: 100,
          ),
          const SizedBox(width: 16),
          ColorAwareAlbumCard(
            onTap: openPlayer,
            title: "Circles",
            artist: "Post Malone",
            imageUrl:
                "https://images.unsplash.com/photo-1514525253361-bee8a187449b?q=80&w=300",
            size: 100,
          ),
          const SizedBox(width: 16),
          ColorAwareAlbumCard(
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
