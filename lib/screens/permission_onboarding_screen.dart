import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class PermissionOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  ConsumerState<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState
    extends ConsumerState<PermissionOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<PermissionStep> _permissionSteps = [
    PermissionStep(
      title: 'Storage Access',
      description:
          'Access your music library to play your favorite songs and create playlists.',
      icon: Icons.folder_rounded,
      color: Color(0xFF5186d2),
      permissions: [
        Permission.storage,
        Permission.photos,
        Permission.mediaLibrary,
        Permission.audio,
      ],
      isRequired: true,
    ),
    PermissionStep(
      title: 'Notifications',
      description:
          'Show playback controls in your notification shade for easy access.',
      icon: Icons.notifications_active_rounded,
      color: AppColors.accentYellow,
      permissions: [Permission.notification],
      isRequired: false,
    ),
    PermissionStep(
      title: 'Photos & Videos',
      description:
          'Access photos and videos to set custom album art and playlist covers.',
      icon: Icons.photo_library_rounded,
      color: AppColors.primaryGreen,
      permissions: [Permission.photos, Permission.videos],
      isRequired: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePermissions(List<Permission> permissions) async {
    for (var permission in permissions) {
      final status = await permission.request();

      if (status.isGranted) {
        debugPrint('✅ Permission granted: ${permission.toString()}');
      } else if (status.isDenied) {
        debugPrint('⚠️ Permission denied: ${permission.toString()}');
      } else if (status.isPermanentlyDenied) {
        debugPrint('❌ Permission permanently denied: ${permission.toString()}');
      }
    }
  }

  Future<void> _nextStep() async {
    // Request current permissions
    await _handlePermissions(_permissionSteps[_currentStep].permissions);

    if (_currentStep < _permissionSteps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _skipStep() async {
    if (_permissionSteps[_currentStep].isRequired) {
      // Show warning that this is required
      _showRequiredPermissionDialog();
      return;
    }

    if (_currentStep < _permissionSteps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  void _showRequiredPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Required Permission',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This permission is required for the app to function properly. Please grant access to continue.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.accentYellow),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: List.generate(
                    _permissionSteps.length,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right: index == _permissionSteps.length - 1 ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.accentYellow
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _permissionSteps.length,
                  itemBuilder: (context, index) {
                    final step = _permissionSteps[index];
                    return _buildPermissionCard(step);
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Grant Permission Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _permissionSteps[_currentStep].color,
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: _permissionSteps[_currentStep].color
                              .withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentStep == _permissionSteps.length - 1
                              ? 'Get Started'
                              : 'Grant Permission',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    // Skip Button (only for optional permissions)
                    if (!_permissionSteps[_currentStep].isRequired) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _skipStep,
                        child: Text(
                          _currentStep == _permissionSteps.length - 1
                              ? 'Skip & Continue'
                              : 'Skip for Now',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: step.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(step.icon, size: 60, color: step.color),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Required/Optional badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: step.isRequired
                  ? Colors.red.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: step.isRequired
                    ? Colors.red.withOpacity(0.5)
                    : Colors.blue.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              step.isRequired ? 'Required' : 'Optional',
              style: TextStyle(
                color: step.isRequired ? Colors.redAccent : Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Permission> permissions;
  final bool isRequired;

  PermissionStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.permissions,
    required this.isRequired,
  });
}
