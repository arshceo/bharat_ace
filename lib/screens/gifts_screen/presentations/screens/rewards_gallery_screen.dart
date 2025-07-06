import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Adjust import paths
import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart';
import 'package:bharat_ace/screens/gifts_screen/models/student_progress_model.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/providers/rewards_providers.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/rewards_gallery/cosmic_background.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/rewards_gallery/student_xp_header.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/widgets/rewards_gallery/gift_pod_widget.dart';

class RewardsGalleryScreen extends ConsumerWidget {
  const RewardsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the student's class from the provider
    final studentClass = ref.watch(currentStudentClassProvider);
    // Pass the class to the gifts provider
    final giftsAsyncValue = ref.watch(availableGiftsProvider(studentClass));
    final studentProgressAsyncValue = ref.watch(studentProgressProvider);

    return Scaffold(
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: studentProgressAsyncValue.when(
              data: (studentProgress) => giftsAsyncValue.when(
                data: (gifts) {
                  if (gifts.isEmpty ||
                      (gifts.length == 1 && gifts.first.id == 'error_gift')) {
                    return Center(
                        child: Text(
                      gifts.isNotEmpty && gifts.first.id == 'error_gift'
                          ? gifts.first.name // Show error message from gift
                          : "No gifts available for your class yet!",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ));
                  }
                  // Pass allGifts to _buildGalleryContent for the header
                  return _buildGalleryContent(
                      context, ref, gifts, studentProgress);
                },
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: Colors.amberAccent)),
                error: (err, stack) => Center(
                    child: Text('Error loading gifts: $err',
                        style: const TextStyle(color: Colors.redAccent))),
              ),
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: Colors.lightBlueAccent)),
              error: (err, stack) => Center(
                  child: Text('Error loading your progress: $err',
                      style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        // Adjust padding if needed, ensure it's above any bottom navigation bar
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 76.0 : 70.0),
        child: FloatingActionButton.extended(
          heroTag: "rewards_gallery_dev_fab", // Add unique heroTag
          onPressed: () {
            ref
                .read(studentProgressProvider.notifier)
                .addXp(200); // Increased XP for faster testing
            ref.read(studentProgressProvider.notifier).incrementConsistency();

            // Simulate completing a test for the first available (and not fully completed) gift
            giftsAsyncValue.whenData((gifts) {
              if (gifts.isNotEmpty) {
                final progress = ref.read(studentProgressProvider).valueOrNull;
                if (progress != null) {
                  // Find first gift that is not yet fully completed test-wise
                  Gift? testableGift;
                  for (var g in gifts) {
                    if (progress.getCompletedTestsForGift(g.id) <
                        g.testsRequired) {
                      testableGift = g;
                      break;
                    }
                  }

                  if (testableGift != null) {
                    int currentTestsDone =
                        progress.getCompletedTestsForGift(testableGift.id);
                    ref
                        .read(studentProgressProvider.notifier)
                        .completeTestForGift(
                            testableGift.id, currentTestsDone + 1);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "DEV: Test +1 for ${testableGift.name.split(' ').first}")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "DEV: All tests completed for available gifts!")));
                  }
                }
              }
            });
          },
          label: const Text("DEV: +XP, Day, Test"),
          icon: const Icon(Icons.developer_mode),
          backgroundColor: Colors.orangeAccent,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildGalleryContent(BuildContext context, WidgetRef ref,
      List<Gift> gifts, StudentProgress studentProgress) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      // Adjusted breakpoint for better tablet/large phone
      crossAxisCount = 3;
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          // Pass allGifts to StudentXpHeader
          child: StudentXpHeader(
              studentProgress: studentProgress, allGifts: gifts),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio:
                  0.7, // Keep this value if it works for your content height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gift = gifts[index];
                final isUnlocked = ref.watch(isGiftUnlockedProvider(gift));

                return GiftPodWidget(
                  gift: gift,
                  isUnlocked: isUnlocked,
                );
              },
              childCount: gifts.length,
            ),
          ),
        ),
        // Adjust bottom padding to ensure FAB doesn't overlap last row
        const SliverToBoxAdapter(
            child: SizedBox(height: 130)), // Increased space
      ],
    );
  }
}
