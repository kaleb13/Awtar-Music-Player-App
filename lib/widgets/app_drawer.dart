import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Drawer(
        backgroundColor: AppColors.surfacePopover,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          AppAssets.logo,
                          height: 32,
                          width: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.music_note,
                                color: AppColors.primaryGreen,
                                size: 32,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AwtarPlayer+",
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              "Premium Experience",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textGrey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(color: Colors.white10),
              ),
              const SizedBox(height: 12),
              _buildDrawerItem(
                context,
                icon: Icons.settings_outlined,
                label: "Settings",
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        label,
        style: AppTextStyles.bodyMain.copyWith(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
