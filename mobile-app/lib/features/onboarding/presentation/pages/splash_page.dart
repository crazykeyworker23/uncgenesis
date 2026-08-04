import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../home/presentation/providers/home_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final delayFuture = Future.delayed(const Duration(seconds: 3));

    try {
      await ref.read(publicSettingsProvider.future);
    } catch (_) {
      // Suppress network errors in splash to allow offline launch
    }

    await delayFuture;

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          // 1. New Worship Background Image covering 100% full screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/worship_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 2. Dark overlay gradient for dramatic contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkGreen.withValues(alpha: 0.65),
                    AppColors.darkGreen.withValues(alpha: 0.45),
                    AppColors.darkGreen.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. Center Content: Golden 3D Logo, GÉNESIS APP, Motto
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean transparent Golden Logo
                Image.asset(
                  'assets/logos/logo.png',
                  width: 200,
                  height: 200,
                  color: AppColors.dorado,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  'GÉNESIS',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6.0,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— A P P —',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 14,
                    letterSpacing: 8.0,
                    color: AppColors.doradoClaro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Una casa para todos ♡',
                  style: TextStyle(
                    fontFamily: 'cursive',
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: AppColors.dorado,
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Loading progress indicator
          Positioned(
            bottom: 75,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.dorado),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cargando...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.dorado,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
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
