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
          const SizedBox(height: 8),
          Text("Select a source to browse", style: AppTextStyles.bodySmall),
          const SizedBox(height: 30),
          const AppStorageCard(
            name: "Internal Storage",
            icon: Icons.smartphone,
            used: "45 GB",
            total: "64 GB",
            percent: 0.7,
            gradientColors: [Color(0xFFF12711), Color(0xFFF5AF19)],
          ),
          const SizedBox(height: 20),
          const AppStorageCard(
            name: "SD Card",
            icon: Icons.sd_storage,
            used: "12 GB",
            total: "128 GB",
            percent: 0.1,
            gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
          const SizedBox(height: 20),
          const AppStorageCard(
            name: "USB Drive",
            icon: Icons.usb,
            used: "0 GB",
            total: "0 GB",
            percent: 0.0,
            isEnabled: false,
            gradientColors: [Colors.grey, Colors.grey],
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
  final List<Color> gradientColors;
  final bool isEnabled;

  const AppStorageCard({
    super.key,
    required this.name,
    required this.icon,
    required this.used,
    required this.total,
    required this.percent,
    this.gradientColors = const [
      AppColors.primaryGreen,
      AppColors.accentYellow,
    ],
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(name, style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$used used",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentYellow,
                  ),
                ),
                Text("of $total", style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(gradientColors.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
