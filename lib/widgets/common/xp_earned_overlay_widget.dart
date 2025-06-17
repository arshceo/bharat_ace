// lib/widgets/common/xp_earned_overlay_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Adjust import path

class XpEarnedOverlayWidget extends StatelessWidget {
  final int amount;
  final String message;
  final String? subMessage;

  const XpEarnedOverlayWidget({
    super.key,
    required this.amount,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: IgnorePointer(
        // Allows taps to go through to content below
        child: Container(
          color: Colors.black.withOpacity(0.3), // Optional dim background
          child: Center(
            child: Animate(
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeIn),
                ScaleEffect(
                    begin: Offset(0.5, 0.5),
                    duration: 300.ms,
                    curve: Curves.elasticOut),
              ],
              child: Card(
                elevation: 8,
                color: AppColors.cardBackground.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subMessage != null && subMessage!.isNotEmpty)
                        Text(
                          subMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.secondaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (subMessage != null && subMessage!.isNotEmpty)
                        const SizedBox(height: 8),
                      Text(
                        '+$amount XP',
                        style: textTheme.displaySmall?.copyWith(
                          color:
                              AppColors.greenSuccess, // Or a gold/yellow color
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(
              // This outer animate handles the exit animation
              // It triggers when the widget is removed from the tree (when isVisible becomes false)
              onComplete: (controller) {
                // Optional: if you need to do something on explicit hide rather than auto-hide
              },
            ).fadeOut(
                delay: 2700.ms,
                duration: 300.ms), // Start fading out before timer ends
          ),
        ),
      ),
    );
  }
}
