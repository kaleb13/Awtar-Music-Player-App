import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        backgroundColor: AppColors.surfaceDark,
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
              if (context.mounted) Navigator.pop(context);
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
        backgroundColor: AppColors.surfaceDark,
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
              await ref
                  .read(libraryProvider.notifier)
                  .updateAlbumMetadata(
                    album.album,
                    album.artist,
                    newTitle: titleController.text,
                    newArtist: artistController.text,
                    year: int.tryParse(yearController.text),
                  );
              if (context.mounted) Navigator.pop(context);
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
        backgroundColor: AppColors.surfaceDark,
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
              await ref
                  .read(libraryProvider.notifier)
                  .updateArtistMetadata(artist.artist, controller.text);
              if (context.mounted) Navigator.pop(context);
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
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Edit Lyrics", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 15,
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
              await ref
                  .read(libraryProvider.notifier)
                  .updateSongLyrics(song, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              "Apply Lyrics",
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
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
