// Widget _buildGlowingButton() {
//     return GestureDetector(
//       onTapDown: (_) {
//         setState(() {
//           isButtonPressed = true;
//         });
//       },
//       onTapUp: (_) {
//         setState(() {
//           isButtonPressed = false;
//         });

//         // TODO: Implement authentication logic
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Soft Neon Glow Effect
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             width: 150,
//             height: 50,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: isButtonPressed
//                       ? Colors.purpleAccent.withOpacity(0.2)
//                       : Colors.purpleAccent.withOpacity(0.8),
//                   blurRadius: 20,
//                   spreadRadius: 8,
//                 ),
//               ],
//             ),
//           ),

//           // Main Button
//           Container(
//             width: 150,
//             height: 50,
//             decoration: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Center(
//               child: Text(
//                 "Login",
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
