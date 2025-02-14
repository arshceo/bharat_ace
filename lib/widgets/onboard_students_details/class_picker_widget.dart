// import 'dart:ui';

// import 'package:bharat_ace/common/app_theme.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class ClassPickerWidget extends StatelessWidget {
//   const ClassPickerWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   /// Circular Cupertino Picker
//                   ClipOval(
//                     child: Container(
//                       width: 250,
//                       height: 250,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: AppTheme.primaryColor.withAlpha(80),
//                       ),
//                       child: Center(
//                         child: SizedBox(
//                           height: 150,
//                           child: CupertinoPicker(
//                             itemExtent: 50,
//                             magnification: 2,
//                             scrollController: FixedExtentScrollController(
//                                 initialItem: _selectedClass),
//                             onSelectedItemChanged: (index) {
//                               setState(() {
//                                 _selectedClass = index;
//                               });
//                             },
//                             selectionOverlay:
//                                 Container(), // Removes default overlay
//                             children: _classLabels.map((label) {
//                               return Center(
//                                 child: Text(
//                                   label,
//                                   style: TextStyle(
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.bold,
//                                     color: _selectedClass ==
//                                             _classLabels.indexOf(label)
//                                         ? Colors.white
//                                         : Colors.white54,
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   /// Glassmorphic Blurred Slit Overlay (Expanding beyond the circle)
//                   Positioned(
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(30),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                         child: Container(
//                           width: 280, // Expanded beyond the circular picker
//                           height:
//                               75, // Slightly bigger for better text visibility
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(30),
//                             color: Colors.white24,
//                             border: Border.all(
//                               color: Colors.white30,
//                               width: 2,
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               _classLabels[
//                                   _selectedClass], // Show selected class
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//   }
// }
