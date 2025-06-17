import 'package:flutter/material.dart';
// Adjust import paths
import 'package:bharat_ace/screens/gifts_screen/models/student_progress_model.dart';
import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart'; // Import Gift model

class StudentXpHeader extends StatelessWidget {
  final StudentProgress studentProgress;
  final List<Gift> allGifts; // Add this to receive all available gifts

  const StudentXpHeader({
    super.key,
    required this.studentProgress,
    required this.allGifts, // Require it in constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Gift? nextMilestoneGift;
    int nextMilestoneXpTarget =
        studentProgress.currentXp + 500; // Default if no more gifts

    // Ensure gifts are sorted by XP if not already (repository should do this)
    // final sortedGifts = List<Gift>.from(allGifts)..sort((a,b) => a.xpRequired.compareTo(b.xpRequired));

    for (var gift in allGifts) {
      // Assumes allGifts is sorted by xpRequired
      // Check if this gift is truly locked
      bool isGiftLockedByCriteria =
          studentProgress.currentXp < gift.xpRequired ||
              studentProgress.consistencyStreakDays <
                  gift.consistencyDaysRequired ||
              studentProgress.getCompletedTestsForGift(gift.id) <
                  gift.testsRequired;

      if (isGiftLockedByCriteria &&
          gift.xpRequired > studentProgress.currentXp) {
        nextMilestoneGift = gift;
        nextMilestoneXpTarget = gift.xpRequired;
        break;
      } else if (isGiftLockedByCriteria &&
          gift.xpRequired <= studentProgress.currentXp) {
        // XP met, but other criteria not. Still show this as a target.
        nextMilestoneGift = gift;
        nextMilestoneXpTarget = gift.xpRequired;
        break;
      }
    }

    // If all gifts are unlocked (or XP meets all requirements for all gifts)
    if (nextMilestoneGift == null && allGifts.isNotEmpty) {
      bool allUnlocked = allGifts.every((gift) =>
          studentProgress.currentXp >= gift.xpRequired &&
          studentProgress.consistencyStreakDays >=
              gift.consistencyDaysRequired &&
          studentProgress.getCompletedTestsForGift(gift.id) >=
              gift.testsRequired);
      if (allUnlocked) {
        nextMilestoneXpTarget = studentProgress.currentXp > 0
            ? studentProgress.currentXp
            : 100; // Show current XP as maxed or a small target
      } else if (studentProgress.currentXp >= allGifts.last.xpRequired) {
        // If XP is high but some other criteria for last gift not met
        nextMilestoneGift = allGifts.last;
        nextMilestoneXpTarget = allGifts.last.xpRequired;
      }
    } else if (allGifts.isEmpty) {
      nextMilestoneXpTarget =
          studentProgress.currentXp > 0 ? studentProgress.currentXp : 100;
    }

    double progressValue = 0.0;
    if (nextMilestoneXpTarget > 0 &&
        studentProgress.currentXp <= nextMilestoneXpTarget) {
      progressValue =
          (studentProgress.currentXp / nextMilestoneXpTarget).clamp(0.0, 1.0);
    } else if (studentProgress.currentXp > nextMilestoneXpTarget) {
      progressValue = 1.0; // Maxed out for this target
    }

    String xpText = "${studentProgress.currentXp} / $nextMilestoneXpTarget XP";
    if (nextMilestoneGift != null) {
      // Shorten gift name for display
      List<String> nameParts = nextMilestoneGift.name.split(' ');
      String shortName = nameParts.length > 2
          ? '${nameParts[0]} ${nameParts[1]}...'
          : nextMilestoneGift.name;
      xpText += " (to $shortName)";
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "YOUR COSMIC XP",
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontSize: 24, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  xpText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11), // Adjusted font size
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 8),
              Text(
                "${studentProgress.consistencyStreakDays} Days Stellar Streak!",
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontSize: 18, color: Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Unlockable Discoveries",
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
