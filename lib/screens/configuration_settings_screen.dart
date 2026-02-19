import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../widgets/app_widgets.dart';

class ConfigurationSettingsScreen extends ConsumerStatefulWidget {
  const ConfigurationSettingsScreen({super.key});

  @override
  ConsumerState<ConfigurationSettingsScreen> createState() =>
      _ConfigurationSettingsScreenState();
}

class _ConfigurationSettingsScreenState
    extends ConsumerState<ConfigurationSettingsScreen> {
  late AlbumNameSource _tempAlbumSource;
  late TitleSource _tempTitleSource;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(libraryProvider);
    _tempAlbumSource = state.albumNameSource;
    _tempTitleSource = state.titleSource;
  }

  void _checkChanges() {
    final state = ref.read(libraryProvider);
    setState(() {
      _hasChanges =
          _tempAlbumSource != state.albumNameSource ||
          _tempTitleSource != state.titleSource;
    });
  }

  Future<void> _applyChanges() async {
    await ref
        .read(libraryProvider.notifier)
        .updateNamingConfiguration(
          albumSource: _tempAlbumSource,
          titleSource: _tempTitleSource,
        );
    if (mounted) {
      setState(() {
        _hasChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Text("Configuration", style: AppTextStyles.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildConfigCard(
                        title: "Album Identification",
                        description:
                            "Choose whether to name albums using embedded metadata or the containing folder's name.",
                        icon: Icons.album_outlined,
                        child: RadioGroup<AlbumNameSource>(
                          groupValue: _tempAlbumSource,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _tempAlbumSource = v);
                              _checkChanges();
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<AlbumNameSource>(
                                value: AlbumNameSource.metadata,
                                title: const Text(
                                  "Use Metadata",
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  "Standard album names from tags",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                activeColor: AppColors.accentBlue,
                              ),
                              RadioListTile<AlbumNameSource>(
                                value: AlbumNameSource.folder,
                                title: const Text(
                                  "Use Folder Name",
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  "Perfect if you organize songs by folder",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                activeColor: AppColors.accentBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildConfigCard(
                        title: "Song Title Source",
                        description:
                            "Choose whether to display the song's title from its metadata or use the actual file name.",
                        icon: Icons.title,
                        child: RadioGroup<TitleSource>(
                          groupValue: _tempTitleSource,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _tempTitleSource = v);
                              _checkChanges();
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<TitleSource>(
                                value: TitleSource.metadata,
                                title: const Text(
                                  "Use Metadata Title",
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  "Titles as embedded in the file",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                activeColor: AppColors.accentBlue,
                              ),
                              RadioListTile<TitleSource>(
                                value: TitleSource.filename,
                                title: const Text(
                                  "Use File Name",
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  "Display files by their literal names",
                                  style: TextStyle(color: Colors.white54),
                                ),
                                activeColor: AppColors.accentBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_hasChanges)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ElevatedButton(
                            onPressed: libraryState.isLoading
                                ? null
                                : _applyChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.accentBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: const Text(
                              "Apply & Rebuild Library",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Note: Applying these changes will trigger a background re-scan to organize your library according to the new rules. This may take a moment depending on your library size.",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (libraryState.isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Updating Configuration...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Organizing library by ${_tempAlbumSource == AlbumNameSource.folder ? 'folders' : 'metadata'}...",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: libraryState.scanProgress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentBlue,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${(libraryState.scanProgress * 100).toInt()}%",
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accentBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
