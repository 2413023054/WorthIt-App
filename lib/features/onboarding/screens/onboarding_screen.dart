import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/screens/login_screen.dart';
import '../../navigation/screens/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final LocalStorageService localStorage;

  const OnboardingScreen({super.key, required this.localStorage});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': AppStrings.onboardingTitle1,
      'desc': AppStrings.onboardingDesc1,
      'icon': Icons.insights_rounded,
      'gradient': AppColors.cardAccentGradient,
    },
    {
      'title': AppStrings.onboardingTitle2,
      'desc': AppStrings.onboardingDesc2,
      'icon': Icons.compare_arrows_rounded,
      'gradient': AppColors.primaryGradient,
    },
    {
      'title': AppStrings.onboardingTitle3,
      'desc': AppStrings.onboardingDesc3,
      'icon': Icons.cloud_done_rounded,
      'gradient': AppColors.cyanGradient,
    },
  ];

  Future<void> _continueAsGuest() async {
    await widget.localStorage.setHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(localStorage: widget.localStorage),
      ),
    );
  }

  void _navigateToLogin() {
    widget.localStorage.setHasSeenOnboarding(true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(localStorage: widget.localStorage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top Logo / App Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.savings_rounded,
                      color: isDark ? AppColors.secondaryCyan : AppColors.primaryIndigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: slide['gradient'] as LinearGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? AppColors.secondaryCyan
                                        : AppColors.primaryIndigo)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            slide['desc'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (isDark
                              ? AppColors.secondaryCyan
                              : AppColors.primaryIndigo)
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Action Buttons
              CustomButton(
                text: AppStrings.tryAsGuest,
                icon: Icons.flash_on_rounded,
                onPressed: _continueAsGuest,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: AppStrings.loginOrRegister,
                isSecondary: true,
                onPressed: _navigateToLogin,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
