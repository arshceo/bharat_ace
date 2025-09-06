// lib/widgets/profile_menu_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../screens/profile/leave_application_screen.dart';
import '../core/providers/feature_toggle_provider.dart';
import '../core/providers/theme_provider.dart';
import 'professional_card.dart' as widgets;

class ProfileMenuWidget extends ConsumerWidget {
  const ProfileMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the feature toggle state to decide what to show
    final extraFeaturesEnabled = ref.watch(featureToggleProvider);
    final isDarkMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return widgets.ProfessionalCard(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & More',
            style: AppTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLG),

          // Feature toggle switch
          _buildFeatureToggleSwitch(context, ref, extraFeaturesEnabled),

          const SizedBox(height: AppTheme.spaceMD),

          // Dark theme toggle switch
          _buildThemeToggleSwitch(context, ref, isDarkMode),

          const SizedBox(height: AppTheme.spaceMD),

          // Leave Application Option - only show when features are enabled
          if (extraFeaturesEnabled)
            _buildMenuOption(
              context: context,
              icon: Icons.pending_actions,
              title: 'Apply for DL',
              subtitle: 'Apply for discipline leave (pre/post)',
              color: AppTheme.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApplicationScreen(),
                ),
              ),
            ),

          if (extraFeaturesEnabled) const SizedBox(height: AppTheme.spaceMD),

          const SizedBox(height: AppTheme.spaceMD),

          // Settings Option (placeholder)
          _buildMenuOption(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'App preferences and configurations',
            color: AppTheme.gray600,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings screen coming soon!'),
                ),
              );
            },
          ),

          const SizedBox(height: AppTheme.spaceMD),

          // Help & Support Option (placeholder)
          _buildMenuOption(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            color: AppTheme.info,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        title,
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.gray900,
                        ),
                      );
                    }),
                    const SizedBox(height: AppTheme.spaceXS),
                    Builder(builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        subtitle,
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.gray600,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.gray400,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Feature toggle switch widget
  Widget _buildFeatureToggleSwitch(
      BuildContext context, WidgetRef ref, bool isEnabled) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isEnabled
                ? AppTheme.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(
                Icons.toggle_on,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      'Extra Features',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.gray900,
                      ),
                    );
                  }),
                  const SizedBox(height: AppTheme.spaceXS),
                  Builder(builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      isEnabled
                          ? 'All app features are enabled'
                          : 'Some features are hidden for simplicity',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.gray600,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                ref.read(featureToggleProvider.notifier).toggleFeatures();
              },
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // Dark theme toggle switch widget
  Widget _buildThemeToggleSwitch(
      BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isDarkMode
                ? AppTheme.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      'Dark Mode',
                      style: AppTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.gray900,
                      ),
                    );
                  }),
                  const SizedBox(height: AppTheme.spaceXS),
                  Builder(builder: (context) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      isDarkMode
                          ? 'Dark theme is enabled'
                          : 'Light theme is enabled',
                      style: AppTheme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.gray600,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Switch(
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
