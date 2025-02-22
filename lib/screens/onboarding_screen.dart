import 'package:bharat_ace/common/app_theme.dart';
import 'package:bharat_ace/screens/smaterial/study_material.dart';
import 'package:bharat_ace/widgets/scroll_arrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/floating_particles.dart';
import '../widgets/glowing_button.dart';
import '../data/onboarding_data.dart'; // ✅ Import this

class OnboardingScreen extends ConsumerWidget {
  OnboardingScreen({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final currentIndex = ref.watch(onboardingIndexProvider);

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FloatingParticles(
                numParticles: 40, particleColor: Colors.white30),
          ),
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (index) {
              ref.read(onboardingIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              return _buildPage(
                context,
                onboardingPages[index]["main"],
                onboardingPages[index]["sub"],
                onboardingPages[index]["animation"],
                index == onboardingPages.length - 1, // Last page
              );
            },
          ),
          Positioned(
            bottom: 70,
            child: Column(
              children: [
                // Icon(Icons.keyboard_arrow_up, size: 32, color: Colors.white)
                //     .animate()
                //     .fadeIn()
                //     .moveY(
                //         begin: 10,
                //         end: 0,
                //         duration: 1200.ms,
                //         curve: Curves.easeInOut),
                ScrollArrow(),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: onboardingPages.length,
                  axisDirection: Axis.vertical,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppTheme.primaryColor,
                    dotColor: Colors.white54,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, String mainText, String subText,
      Function(String) animationBuilder, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedTextKit(
            animatedTexts: [animationBuilder(mainText)],
            repeatForever: false,
            totalRepeatCount: 1,
          ),
          const SizedBox(height: 20),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor.withAlpha(180)),
          ).animate().fadeIn(delay: 3500.ms),
          const SizedBox(height: 40),
          if (isLastPage)
            // GlowingButton(
            //   text: "Let's Start!",
            //   onTap: () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => StudentQueryScreen()));
            //   },
            // ),
            GlowingButton(
              text: "Let's Start!",
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        StudyMaterialsScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: Curves.easeOutBack),
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
