// lib/widgets/add_buddy_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

class AddBuddyBottomSheet extends ConsumerStatefulWidget {
  final Function(String option)? onOptionSelected;

  const AddBuddyBottomSheet({
    super.key,
    this.onOptionSelected,
  });

  @override
  ConsumerState<AddBuddyBottomSheet> createState() =>
      _AddBuddyBottomSheetState();
}

class _AddBuddyBottomSheetState extends ConsumerState<AddBuddyBottomSheet> {
  // Generate a random invite code
  final String inviteCode = 'BDY${Random().nextInt(900000) + 100000}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Buddy Group',
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Study together, achieve more!',
                        style: AppTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Invite code display
          Container(
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      color: AppTheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Invitation Code',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.gray300,
                          ),
                        ),
                        child: Text(
                          inviteCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Share options
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Share via:',
              style: AppTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Social media sharing options
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSharingOption(
                  'WhatsApp',
                  'assets/avatars/whatsapp.png',
                  Colors.green,
                  () => _shareViaApp('whatsapp'),
                ),
                _buildSharingOption(
                  'Snapchat',
                  'assets/avatars/snapchat.png',
                  const Color(0xFFFFFC00),
                  () => _shareViaApp('snapchat'),
                ),
                _buildSharingOption(
                  'Instagram',
                  'assets/avatars/instagram.png',
                  const Color(0xFFE4405F),
                  () => _shareViaApp('instagram'),
                ),
              ],
            ),
          ),

          // Maybe Later button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: TextButton(
              onPressed: () {
                if (widget.onOptionSelected != null) {
                  widget.onOptionSelected!('maybe_later');
                }
                Navigator.pop(context);
              },
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: AppTheme.gray600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingOption(
      String name, String iconPath, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                iconPath,
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if the asset is missing
                  return Icon(
                    Icons.share,
                    color: color,
                    size: 28,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareViaApp(String app) {
    // Generate sharing message
    String shareMessage =
        'Join my BharatAce study group with code: $inviteCode. Let\'s study together and excel in our exams! 📚✨';

    // Use Share package to share content
    Share.share(
      shareMessage,
      subject: 'Join My BharatAce Study Group',
    ).then((_) {
      if (widget.onOptionSelected != null) {
        widget.onOptionSelected!(app);
      }
      Navigator.pop(context);
    });
  }
}
