import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class MediaEditDialogs {
  static void showEditSong(BuildContext context, WidgetRef ref, Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    final albumController = TextEditingController(text: song.album);
    final trackController = TextEditingController(
      text: song.trackNumber?.toString() ?? "",
    );
    final genreController = TextEditingController(text: song.genre ?? "");
    final yearController = TextEditingController(
      text: song.year?.toString() ?? "",
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Edit Song Metadata",
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Title", titleController),
              _buildTextField("Artist", artistController),
              _buildTextField("Album", albumController),
              _buildTextField(
                "Track Number",
                trackController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField("Genre", genreController),
              _buildTextField(
                "Year",
                yearController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showEditLyrics(context, ref, song);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  foregroundColor: AppColors.primaryGreen,
                  elevation: 0,
                ),
                child: const Text("Edit Lyrics"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(libraryProvider.notifier)
                    .updateSongMetadata(
                      song,
                      title: titleController.text,
                      artist: artistController.text,
                      album: albumController.text,
                      trackNumber: int.tryParse(trackController.text),
                      genre: genreController.text,
                      year: int.tryParse(yearController.text),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Metadata saved successfully"),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to save metadata: ${e.toString()}"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showEditAlbum(BuildContext context, WidgetRef ref, Album album) {
    final titleController = TextEditingController(text: album.album);
    final artistController = TextEditingController(text: album.artist);
    final yearController = TextEditingController(
      text: album.firstYear?.toString() ?? "",
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Album", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Album Title", titleController),
            _buildTextField("Album Artist", artistController),
            _buildTextField(
              "Year",
              yearController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(libraryProvider.notifier)
                    .updateAlbumMetadata(
                      album.album,
                      album.artist,
                      newTitle: titleController.text,
                      newArtist: artistController.text,
                      year: int.tryParse(yearController.text),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Album updated successfully")),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update album: ${e.toString()}"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Apply to all songs",
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showEditArtist(
    BuildContext context,
    WidgetRef ref,
    Artist artist,
  ) {
    final controller = TextEditingController(text: artist.artist);

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Artist", style: TextStyle(color: Colors.white)),
        content: _buildTextField("Artist Name", controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(libraryProvider.notifier)
                    .updateArtistMetadata(artist.artist, controller.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Artist updated successfully"),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to update artist: ${e.toString()}"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  static void showEditLyrics(BuildContext context, WidgetRef ref, Song song) {
    final controller = TextEditingController(
      text: song.lyrics.map((l) => l.text).join("\n"),
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfacePopover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Lyrics", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: TextField(
              controller: controller,
              maxLines: 10,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Paste or type lyrics here...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchSection(song, ref),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(libraryProvider.notifier)
                            .updateSongLyrics(song, controller.text);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lyrics updated successfully"),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to update lyrics: ${e.toString()}",
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Apply Lyrics",
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildSearchSection(Song song, WidgetRef ref) {
    final libraryState = ref.read(libraryProvider);
    final titleSource = libraryState.titleSource;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.travel_explore,
                color: AppColors.accentYellow,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "Search Lyrics Online",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _launchLyricSearch(song, titleSource),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow.withOpacity(0.1),
                    foregroundColor: AppColors.accentYellow,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Search in Browser",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _launchLyricSearch(Song song, TitleSource source) {
    String searchBase;
    if (source == TitleSource.filename) {
      // Use filename (the user's "music itself" preference)
      String fileName = song.url.split('/').last.split('\\').last;
      if (fileName.contains('.')) {
        fileName = fileName.substring(0, fileName.lastIndexOf('.'));
      }
      searchBase = fileName;
    } else {
      // Use metadata tags
      searchBase = "${song.artist} ${song.title}";
    }

    final query = Uri.encodeComponent("$searchBase lyric");
    final url = Uri.parse("https://www.google.com/search?q=$query");
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryGreen),
          ),
        ),
      ),
    );
  }
}
