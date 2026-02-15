import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../screens/details/album_details_screen.dart';
import '../screens/details/artist_details_screen.dart';
import '../services/media_menu_service.dart';
import 'app_artwork.dart';

class SearchResultsView extends ConsumerWidget {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    if (query.isEmpty) return const SizedBox.shrink();

    if (results.songs.isEmpty &&
        results.albums.isEmpty &&
        results.artists.isEmpty) {
      return const Center(
        child: Text(
          "No results found",
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (results.songs.isNotEmpty) ...[
          _buildHeader("SONGS"),
          ...results.songs.map(
            (song) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSongTile(
                song: song,
                playlist: results.songs,
                index: results.songs.indexOf(song),
                showArtwork: true,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (results.albums.isNotEmpty) ...[
          _buildHeader("ALBUMS"),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.albums.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final album = results.albums[index];
                final repAlbums = ref.watch(
                  libraryProvider.select((s) => s.representativeAlbumSongs),
                );

                final albumKey = '${album.album}_${album.artist}';
                final albumSongId = repAlbums[albumKey];

                return AppAlbumCard(
                  title: album.album,
                  artist: album.artist,
                  imageUrl: "",
                  songId: albumSongId,
                  artwork: AspectRatio(
                    aspectRatio: 1.0,
                    child: AppArtwork(
                      songId: albumSongId,
                      borderRadius: 12,
                      size: 120,
                    ),
                  ),
                  size: 120,
                  onTap: () {
                    ref.read(bottomNavVisibleProvider.notifier).state = false;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailsScreen(
                          title: album.album,
                          artist: album.artist,
                          imageUrl: "",
                        ),
                      ),
                    ).then((_) {
                      ref.read(bottomNavVisibleProvider.notifier).state = true;
                    });
                  },
                  onLongPress: () => AppCenteredModal.show(
                    context,
                    title: album.album,
                    items: MediaMenuService.buildAlbumActions(
                      context: context,
                      ref: ref,
                      album: album,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (results.artists.isNotEmpty) ...[
          _buildHeader("ARTISTS"),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: results.artists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final artist = results.artists[index];
                final artistSongId = ref.watch(
                  libraryProvider.select(
                    (s) => s.representativeArtistSongs[artist.artist],
                  ),
                );
                final fallbackSongId = ref.watch(
                  libraryProvider.select(
                    (s) => s.songs.isNotEmpty ? s.songs.first.id : 0,
                  ),
                );
                final finalSongId = artistSongId ?? fallbackSongId;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(bottomNavVisibleProvider.notifier).state =
                            false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistDetailsScreen(
                              name: artist.artist,
                              imageUrl: "",
                            ),
                          ),
                        ).then((_) {
                          ref.read(bottomNavVisibleProvider.notifier).state =
                              true;
                        });
                      },
                      onLongPress: () => AppCenteredModal.show(
                        context,
                        title: artist.artist,
                        items: MediaMenuService.buildArtistActions(
                          context: context,
                          ref: ref,
                          artist: artist,
                        ),
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentBlue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: AppArtwork(
                            songId: finalSongId,
                            size: 80,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        artist.artist,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 2,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}
