// lib/screens/buddy/add_buddy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class AddBuddyScreen extends ConsumerWidget {
  const AddBuddyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationLink = "https://bharatace.com/join?code=STUDY123";

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Text(
          'Add Study Buddy',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation section
            _buildExplanationCard(),
            const SizedBox(height: AppTheme.spaceLG),

            // Link copy section
            _buildLinkSection(context, invitationLink),
            const SizedBox(height: AppTheme.spaceLG),

            // Share platforms section
            _buildSharePlatformsSection(context, invitationLink),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.white, size: 24),
              const SizedBox(width: AppTheme.spaceSM),
              Text(
                'Study Together',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            'Invite a friend to join your study session. When they join, you\'ll be able to:',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          _buildFeatureItem('Study the same topics together'),
          _buildFeatureItem('Chat and help each other understand concepts'),
          _buildFeatureItem('Track each other\'s progress'),
          _buildFeatureItem('Stay motivated with peer accountability'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppTheme.white, size: 20),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              text,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.white.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context, String link) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share this link',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMD,
                    vertical: AppTheme.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppTheme.gray300),
                  ),
                  child: Text(
                    link,
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied to clipboard'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                icon: Icon(Icons.copy, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharePlatformsSection(BuildContext context, String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share via',
          style: AppTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSharePlatformButton(
              context,
              'WhatsApp',
              Icons.chat,
              Colors.green.shade600,
              () => _shareLink(context, link, 'whatsapp'),
            ),
            _buildSharePlatformButton(
              context,
              'Snapchat',
              Icons.photo_camera,
              Colors.yellow.shade700,
              () => _shareLink(context, link, 'snapchat'),
            ),
            _buildSharePlatformButton(
              context,
              'Instagram',
              Icons.camera_alt,
              Colors.pink.shade400,
              () => _shareLink(context, link, 'instagram'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLG),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Share.share(
              'Join my study session in BharatAce! Click here: $link',
              subject: 'Study with me in BharatAce!',
            ),
            icon: const Icon(Icons.share),
            label: const Text('Share with other apps'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharePlatformButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareLink(BuildContext context, String link, String platform) {
    String message;

    switch (platform) {
      case 'whatsapp':
        message = "Join my study session in BharatAce! Click here: $link";
        break;
      case 'snapchat':
        message = "Study with me! $link";
        break;
      case 'instagram':
        message = "Let's study together with BharatAce! Join me: $link";
        break;
      default:
        message = "Join my study session in BharatAce! Click here: $link";
    }

    Share.share(message, subject: 'Study with me in BharatAce!');
  }
}
