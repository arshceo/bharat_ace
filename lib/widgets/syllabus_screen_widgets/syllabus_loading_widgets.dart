import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bharat_ace/core/theme/app_colors.dart'; // Adjusted import

Widget buildShimmerCard(
    {required double height, double? width, double borderRadius = 15}) {
  return Shimmer.fromColors(
    baseColor: AppColors.shimmerBase,
    highlightColor: AppColors.shimmerHighlight,
    child: Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
}

Widget buildSyllabusLoadingState(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        buildShimmerCard(
            height: 130, borderRadius: 12), // Overall progress shimmer
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: buildShimmerCard(
                  height: 100, borderRadius: 16), // Subject card shimmer
            ),
          ),
        ),
      ],
    ),
  );
}
