import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

class FoldersTab extends ConsumerWidget {
  const FoldersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const AppStorageCard(
            name: "Internal Storage",
            icon: Icons.smartphone,
            used: "45 GB",
            total: "64 GB",
            percent: 0.7,
            accentColor: Color(0xFF5186d2),
          ),
          const SizedBox(height: 12),
          const AppStorageCard(
            name: "SD Card",
            icon: Icons.sd_storage,
            used: "12 GB",
            total: "128 GB",
            percent: 0.1,
            accentColor: Color(0xFF50be5b),
          ),
          const SizedBox(height: 12),
          const AppStorageCard(
            name: "USB Drive",
            icon: Icons.usb,
            used: "0 GB",
            total: "0 GB",
            percent: 0.0,
            isEnabled: false,
            accentColor: Colors.grey,
          ),
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
            // Minimal Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 16),
            // Name and Progress Column
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
                  // Slim Progress Bar
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
