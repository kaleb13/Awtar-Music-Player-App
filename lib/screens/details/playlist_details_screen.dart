import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_artwork.dart';
import '../../widgets/app_song_list_tile.dart';
import '../../models/song.dart';

class PlaylistDetailsScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailsScreen({super.key, required this.playlistId});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await ref
            .read(libraryProvider.notifier)
            .updatePlaylistImage(playlistId, image.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Playlist cover updated!"),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);

    // Find playlist safely
    final playlistIndex = library.playlists.indexWhere(
      (p) => p.id == playlistId,
    );
    if (playlistIndex == -1) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            "Playlist not found",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final playlist = library.playlists[playlistIndex];

    // Get the songs for this playlist
    final songs = playlist.songIds
        .map(
          (id) => library.songs.firstWhere(
            (s) => s.id == id,
            orElse: () => Song(
              id: -1,
              title: "Unknown",
              artist: "Unknown",
              duration: 0,
              url: "",
              lyrics: [],
            ),
          ),
        )
        .where((s) => s.id != -1)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Banner with Image Upload
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Playlist Cover
                  if (playlist.imagePath != null)
                    Image.file(File(playlist.imagePath!), fit: BoxFit.cover)
                  else if (songs.isNotEmpty)
                    AppArtwork(
                      songId: songs.first.id,
                      songPath: songs.first.url,
                      size: 300,
                      borderRadius: 0,
                    )
                  else
                    Container(
                      color: AppColors.surfaceDark,
                      child: const Icon(
                        Icons.playlist_play,
                        size: 100,
                        color: Colors.white12,
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),

                  // Upload Button Overlay
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => _pickImage(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Playlist Name
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PLAYLIST",
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shuffle Play Button Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  // Shuffle Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (songs.isNotEmpty) {
                        final shuffledSongs = List<Song>.from(songs)..shuffle();
                        ref
                            .read(playerProvider.notifier)
                            .play(shuffledSongs.first, queue: shuffledSongs);
                      }
                    },
                    icon: const Icon(Icons.shuffle, size: 20),
                    label: const Text(
                      "SHUFFLE",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${songs.length} Songs",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Songs List
          if (songs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  "No songs in this playlist yet.",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 120, left: 16, right: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppSongListTile(
                      song: song,
                      isActive: false,
                      onTap: () {
                        ref
                            .read(playerProvider.notifier)
                            .play(song, queue: songs, index: index);
                      },
                    ),
                  );
                }, childCount: songs.length),
              ),
            ),
        ],
      ),
    );
  }
}
