import 'package:flutter/material.dart';

// class GlowingButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onTap;

//   const GlowingButton({super.key, required this.text, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GlowButton(
//       spreadRadius: 4,
//       onPressed: onTap,
//       color: AppTheme.primaryColor,
//       glowColor: AppTheme.primaryColor,
//       height: 50,
//       width: 180,
//       borderRadius: BorderRadius.circular(30),
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

class GlowingButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const GlowingButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.white54,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
