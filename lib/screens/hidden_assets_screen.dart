import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HiddenAssetsScreen extends ConsumerWidget {
  const HiddenAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.mainDark,
        appBar: AppBar(
          backgroundColor: AppColors.mainDark,
          title: Text("Visibility", style: AppTextStyles.titleMedium),
          leading: AppIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.accentBlue,
            labelColor: AppColors.accentBlue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Artists"),
              Tab(text: "Albums"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _VisibilityList(type: _VisibilityType.artist),
            _VisibilityList(type: _VisibilityType.album),
          ],
        ),
      ),
    );
  }
}

enum _VisibilityType { artist, album }

class _VisibilityList extends ConsumerWidget {
  final _VisibilityType type;

  const _VisibilityList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);

    if (type == _VisibilityType.artist) {
      final artists = libraryState.artists;
      // Separate lists? Or just one list with toggle?
      // User requested "toggle ... ability to list ... or not".
      // We list ALL artists, and the toggle shows current state.

      // Sort alphabetically for better UX
      final sortedArtists = List.of(artists)
        ..sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );

      return ListView.builder(
        itemCount: sortedArtists.length,
        itemBuilder: (context, index) {
          final artist = sortedArtists[index];
          final isHidden = libraryState.hiddenArtists.contains(artist.artist);

          return SwitchListTile(
            activeThumbColor: AppColors.accentBlue,
            title: Text(
              artist.artist,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "${artist.numberOfTracks} songs",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            // Logic: "Toggle ... to list ... or not"
            // If toggle is ON, it is Visible? Or Hidden?
            // Usually Toggle ON = Enabled/Visible.
            // If visible -> !isHidden.
            value: !isHidden,
            onChanged: (visible) {
              notifier.toggleArtistVisibility(artist.artist);
            },
          );
        },
      );
    } else {
      final albums = libraryState.albums;
      final sortedAlbums = List.of(
        albums,
      )..sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));

      return ListView.builder(
        itemCount: sortedAlbums.length,
        itemBuilder: (context, index) {
          final album = sortedAlbums[index];
          final key = "${album.album}_${album.artist}";
          final isHidden = libraryState.hiddenAlbums.contains(key);

          return SwitchListTile(
            activeThumbColor: AppColors.accentBlue,
            title: Text(
              album.album,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              album.artist,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            value: !isHidden,
            onChanged: (visible) {
              notifier.toggleAlbumVisibility(key);
            },
          );
        },
      );
    }
  }
}

