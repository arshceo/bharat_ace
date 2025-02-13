import 'package:bharat_ace/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';

class GlowingButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GlowingButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlowButton(
      spreadRadius: 4,
      onPressed: onTap,
      color: AppTheme.primaryColor,
      glowColor: Colors.deepPurple,
      height: 50,
      width: 180,
      borderRadius: BorderRadius.circular(30),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
