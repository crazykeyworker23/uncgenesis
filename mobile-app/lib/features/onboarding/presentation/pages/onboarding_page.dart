import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(
        children: [
          // Background Image (100% full screen background image)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Subtle dark overlay to ensure readability
          Positioned.fill(
            child: Container(
              color: AppColors.darkGreen.withValues(alpha: 0.65),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header: Logo + GÉNESIS APP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logos/logo.png',
                        width: 38,
                        height: 38,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.church,
                          color: AppColors.dorado,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GÉNESIS APP',
                        style: AppTextStyles.titleMedium.copyWith(
                          letterSpacing: 2.0,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Main Cursive Title: Conecta, crece y participa
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'cursive',
                              fontSize: 38,
                              fontStyle: FontStyle.italic,
                              color: AppColors.white,
                              height: 1.15,
                            ),
                            children: [
                              const TextSpan(text: 'Conecta, '),
                              const TextSpan(
                                text: 'crece ',
                                style: TextStyle(color: AppColors.doradoClaro),
                              ),
                              const TextSpan(text: 'y\n'),
                              TextSpan(
                                text: 'participa',
                                style: TextStyle(
                                  shadows: [
                                    Shadow(
                                      color: Colors.red.withValues(alpha: 0.5),
                                      offset: const Offset(0, 4),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Red paint brush underline under "participa"
                        Container(
                          width: 140,
                          height: 3,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle: Una casa para todos
                  const Center(
                    child: Text(
                      'Una casa para todos ♡',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: AppColors.doradoClaro,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Three circular benefit rows
                  _buildBenefitRow(
                    icon: Icons.people_outline,
                    text: 'Conéctate con tu iglesia y tu grupo',
                  ),
                  const SizedBox(height: 20),
                  _buildBenefitRow(
                    icon: Icons.menu_book_outlined,
                    text: 'Encuentra recursos que alimentan tu fe',
                  ),
                  const SizedBox(height: 20),
                  _buildBenefitRow(
                    icon: Icons.notifications_none_outlined,
                    text: 'Mantente al día con lo que sucede',
                  ),

                  const Spacer(flex: 2),

                  // Action Buttons
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.dorado.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dorado,
                        foregroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.crema.withValues(alpha: 0.6),
                    ),
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.dorado.withValues(alpha: 0.6), width: 1.5),
            color: AppColors.deepTeal.withValues(alpha: 0.4),
          ),
          child: Icon(
            icon,
            color: AppColors.dorado,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.crema,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
