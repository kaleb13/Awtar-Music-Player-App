import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainDark,
      body: SafeArea(
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
                  Text("About AwtarPlayer", style: AppTextStyles.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          AppAssets.logo,
                          height: 80,
                          width: 80,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.music_note,
                                color: AppColors.primaryGreen,
                                size: 80,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "AwtarPlayer+",
                          style: AppTextStyles.titleLarge.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "PREMIUM EXPERIENCE",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryGreen,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Developer Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              "assets/icons/developer.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.network(
                                    "https://avatars.githubusercontent.com/u/120258164?v=4",
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: AppColors.primaryGreen
                                                  .withOpacity(0.1),
                                              child: const Icon(
                                                Icons.person,
                                                color: AppColors.primaryGreen,
                                                size: 30,
                                              ),
                                            ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kaleb Tesfaye",
                                style: AppTextStyles.bodyMain.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Developer and UI/UX Designer of AwtarPlayer+",
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final url = Uri.parse('https://t.me/zkaleb');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.send_rounded,
                                        color: AppColors.primaryGreen,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "@zkaleb",
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildSection(
                    title: "OUR MISSION",
                    content:
                        "AwtarPlayer is designed to be the ultimate music companion, providing a seamless and high-fidelity experience for your music library. No distractions, no interruptions, just pure music.",
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: "CURRENT FEATURES",
                    isFeature: true,
                    icon: Icons.star_rounded,
                    content:
                        "Premium high-performance audio engine, advanced metadata management, and a stunning adaptive UI designed for music lovers.",
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: "COMING SOON",
                    children: [
                      _buildUpcomingItem(
                        icon: Icons.confirmation_number_outlined,
                        title: "Concert Tickets",
                        description:
                            "Purchase tickets for upcoming concerts and live events directly within the app.",
                      ),
                      const SizedBox(height: 16),
                      _buildUpcomingItem(
                        icon: Icons.movie_filter_outlined,
                        title: "Album Trailers",
                        description:
                            "Watch exclusive trailers and teasers for upcoming music releases and albums.",
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    bool isFeature = false,
    IconData? icon,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.accentYellow,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFeature
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFeature
                    ? AppColors.primaryGreen.withOpacity(0.3)
                    : Colors.white10,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    content,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (children != null) ...children,
      ],
    );
  }

  Widget _buildUpcomingItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accentYellow, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMain.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
