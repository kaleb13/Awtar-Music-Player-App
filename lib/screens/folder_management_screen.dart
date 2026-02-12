import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../widgets/app_widgets.dart';
import 'dart:ui';
import '../providers/storage_provider.dart';
import 'tabs/storage_folders_screen.dart';

class FolderManagementScreen extends ConsumerWidget {
  const FolderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageState = ref.watch(storageProvider);
    final libraryState = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                if (storageState.isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentYellow,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      children: storageState.storages.map((storage) {
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
                                        builder: (context) =>
                                            StorageFoldersScreen(
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
                              total:
                                  "${storage.totalSize.toStringAsFixed(1)} GB",
                              percent: storage.percent,
                              accentColor: storage.isAvailable
                                  ? accentColor
                                  : Colors.grey,
                              isEnabled: storage.isAvailable,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (libraryState.isRefiningLibrary)
            _buildRefiningOverlay(libraryState.refineProgress),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manage Library", style: AppTextStyles.titleMedium),
              Text(
                "Select a storage source to manage",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefiningOverlay(double progress) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            Text("Refining Library...", style: AppTextStyles.titleMedium),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
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
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        "$used / $total",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
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
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
