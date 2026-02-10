import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/storage_provider.dart';
import '../../providers/library_provider.dart';
import 'storage_folders_screen.dart';

class FoldersTab extends ConsumerWidget {
  const FoldersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(storageProvider);
    final libraryState = ref.watch(libraryProvider);

    ref.listen<LibraryState>(libraryProvider, (previous, next) {
      if (previous?.permissionStatus != LibraryPermissionStatus.granted &&
          next.permissionStatus == LibraryPermissionStatus.granted) {
        ref.read(storageProvider.notifier).refresh();
      }
    });

    if (libraryState.permissionStatus != LibraryPermissionStatus.granted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "Storage access required",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "To see your audio folders, please grant storage permission",
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(libraryProvider.notifier).requestPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text("Storage", style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text("Select a source to browse", style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),

          if (storageState.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accentYellow),
            )
          else ...[
            ...storageState.storages.map((storage) {
              Color accentColor;
              IconData icon;
              String storageRoot = "";

              if (storage.name.contains("Internal")) {
                accentColor = const Color(0xFF5186d2);
                icon = Icons.smartphone;
                storageRoot = "/storage/emulated/0";
              } else if (storage.name.contains("SD")) {
                accentColor = const Color(0xFF50be5b);
                icon = Icons.sd_storage;
                // Find SD root from storageMap keys if not emulated
                storageRoot = libraryState.storageMap.keys.firstWhere(
                  (k) => !k.contains("emulated"),
                  orElse: () => "",
                );
              } else {
                accentColor = Colors.grey;
                icon = Icons.usb;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: storage.isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StorageFoldersScreen(
                                storageName: storage.name,
                                storageRoot: storageRoot,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: AppStorageCard(
                    name: storage.name,
                    icon: icon,
                    used: "${storage.usedSize.toStringAsFixed(1)} GB",
                    total: "${storage.totalSize.toStringAsFixed(1)} GB",
                    percent: storage.percent,
                    accentColor: storage.isAvailable
                        ? accentColor
                        : Colors.grey,
                    isEnabled: storage.isAvailable,
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 120), // Bottom padding
        ],
      ),
    );
  }
}

class AppStorageCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final String used;
  final String total;
  final double percent;
  final Color accentColor;
  final bool isEnabled;

  const AppStorageCard({
    super.key,
    required this.name,
    required this.icon,
    required this.used,
    required this.total,
    required this.percent,
    required this.accentColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyMain.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "$used / $total",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.2),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
