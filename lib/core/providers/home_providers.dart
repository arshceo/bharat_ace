// lib/core/providers/home_providers.dart
import 'package:bharat_ace/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart'; // For Icons
import 'package:bharat_ace/core/models/leaderboard_user.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';

final currentStudentsOnlineProvider = FutureProvider<int>((ref) async {
  await Future.delayed(
      Duration(milliseconds: 900 + (DateTime.now().millisecond % 300)));
  return 750 + (DateTime.now().second * 17) % 500;
});

final homeLeaderboardProvider =
    FutureProvider<List<LeaderboardUser>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1300));
  return [
    LeaderboardUser(name: "Rohan V.", xp: 12050),
    LeaderboardUser(name: "Sneha P.", xp: 11800),
    LeaderboardUser(name: "Arjun M.", xp: 11550),
  ];
});

final dailyAiFeedProvider = FutureProvider<DailyFeedItem>((ref) async {
  await Future.delayed(
      const Duration(milliseconds: 800)); // Simulate network delay

  final items = <DailyFeedItem>[
    // --- SMART STUDY TIPS ---
    DailyFeedItem(
        type: DailyFeedItemType.quickTip,
        title: "Smart Study: Pomodoro",
        content:
            "Use the Pomodoro Technique: 25 mins focused study, 5 mins break. Boosts concentration!",
        icon: Icons.timer_outlined,
        iconColor: AppColors.pomodoroOrange),
    DailyFeedItem(
        type: DailyFeedItemType.studyStrategy,
        title: "Smart Study: Active Recall",
        content:
            "Test yourself! Instead of re-reading, try to retrieve information from memory. Flashcards are great for this.",
        icon: Icons.psychology_alt_outlined,
        iconColor: AppColors.activeRecallBlue),
    DailyFeedItem(
        type: DailyFeedItemType.learningTechnique,
        title: "Learn Fast: Feynman Technique",
        content:
            "Explain a concept in simple terms, as if teaching a child. Identify gaps in your understanding.",
        icon: Icons.school_outlined,
        iconColor: AppColors.accentGreen),
    DailyFeedItem(
        type: DailyFeedItemType.quickTip,
        title: "Smart Study: Spaced Repetition",
        content:
            "Review material at increasing intervals over time. This dramatically improves long-term retention.",
        icon: Icons.repeat_one_on_outlined,
        iconColor: AppColors.spacedRepetitionTeal),
    DailyFeedItem(
        type: DailyFeedItemType.studyStrategy,
        title: "Smart Study: Mind Palace",
        content:
            "Visualize a familiar place and associate facts with objects within it. A powerful mnemonic!",
        icon: Icons.castle_outlined,
        iconColor: AppColors.mindPalacePurple),
    DailyFeedItem(
        type: DailyFeedItemType.quickTip,
        title: "Smart Study: Prioritize Tasks",
        content:
            "Use the Eisenhower Matrix (Urgent/Important) to decide what to focus on first. Tackle high-impact tasks.",
        icon: Icons.checklist_rtl_outlined,
        iconColor: AppColors.prioritizeTasksRed),
    DailyFeedItem(
        type: DailyFeedItemType.learningTechnique,
        title: "Learn Fast: Chunking",
        content:
            "Break down complex information into smaller, manageable chunks. Easier to process and remember!",
        icon: Icons.grain_outlined, // Represents breaking down
        iconColor: AppColors.chunkingBrown),
    DailyFeedItem(
        type: DailyFeedItemType.quickTip,
        title: "Smart Study: No Multitasking",
        content:
            "Focus on one task at a time. Multitasking reduces efficiency and learning quality.",
        icon: Icons.block_flipped,
        iconColor: AppColors.noMultitaskingGrey),

    // --- MOTIVATIONAL QUOTES & ENCOURAGEMENT ---
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Word to Inspire",
        content: "The expert in anything was once a beginner. Keep learning!",
        icon: Icons.format_quote_rounded,
        iconColor: AppColors.accentPink),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Fuel Your Fire",
        content:
            "Believe you can and you're halfway there. - Theodore Roosevelt",
        icon: Icons.local_fire_department_outlined,
        iconColor: AppColors.fuelFireRed),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Keep Going!",
        content:
            "Success is not final, failure is not fatal: It is the courage to continue that counts. - Winston Churchill",
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.keepGoingGreen),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Embrace Learning",
        content:
            "The beautiful thing about learning is that no one can take it away from you. - B.B. King",
        icon: Icons.menu_book_rounded,
        iconColor: AppColors.feedAccentPurple),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Today's Mantra",
        content:
            "Strive for progress, not perfection. Every small step counts.",
        icon: Icons.stairs_outlined,
        iconColor: AppColors.mantraBlue),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Unlock Your Potential",
        content:
            "The only limit to our realization of tomorrow will be our doubts of today. - Franklin D. Roosevelt",
        icon: Icons.key_outlined,
        iconColor: AppColors.unlockPotentialAmber),
    DailyFeedItem(
        type: DailyFeedItemType.motivationalQuote,
        title: "Power of Knowledge",
        content:
            "An investment in knowledge pays the best interest. - Benjamin Franklin",
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.powerOfKnowledgeGreen),

    // --- HEALTHY HABITS FOR STUDENTS ---
    DailyFeedItem(
        type: DailyFeedItemType.healthWellnessTip,
        title: "Healthy Student: Hydrate!",
        content:
            "Drink plenty of water throughout the day. Dehydration can impair focus and energy levels.",
        icon: Icons.water_drop_outlined,
        iconColor: AppColors.hydrateBlue),
    DailyFeedItem(
        type: DailyFeedItemType.healthWellnessTip,
        title: "Healthy Student: Sleep Well",
        content:
            "Aim for 7-9 hours of quality sleep. It's crucial for memory consolidation and cognitive function.",
        icon: Icons.bedtime_outlined,
        iconColor: AppColors.sleepIndigo),
    DailyFeedItem(
        type: DailyFeedItemType.healthWellnessTip,
        title: "Healthy Student: Move Your Body",
        content:
            "Take short breaks to stretch or walk. Physical activity boosts blood flow to the brain.",
        icon: Icons.directions_walk_outlined,
        iconColor: AppColors.accentLime),
    DailyFeedItem(
        type: DailyFeedItemType.healthWellnessTip,
        title: "Healthy Student: Brain Food",
        content:
            "Eat nutritious meals. Foods rich in Omega-3s, antioxidants, and vitamins support brain health.",
        icon: Icons.restaurant_menu_outlined, // or Icons.apple
        iconColor: AppColors.brainFoodGreen),
    DailyFeedItem(
        type: DailyFeedItemType.healthWellnessTip,
        title: "Healthy Student: Eye Care",
        content:
            "Follow the 20-20-20 rule: Every 20 mins, look at something 20 feet away for 20 secs to reduce eye strain.",
        icon: Icons.visibility_outlined,
        iconColor: AppColors.eyeCareCyan),

    // --- ENJOY LIFE & BALANCE ---
    DailyFeedItem(
        type: DailyFeedItemType.lifeBalanceTip,
        title: "Enjoy Life: Take Breaks",
        content:
            "Schedule regular breaks for hobbies or relaxation. Prevents burnout and improves overall well-being.",
        icon: Icons.sentiment_very_satisfied_outlined,
        iconColor: AppColors.accentOrange),
    DailyFeedItem(
        type: DailyFeedItemType.lifeBalanceTip,
        title: "Enjoy Life: Connect",
        content:
            "Spend time with friends and family. Social connections are vital for mental health.",
        icon: Icons.group_outlined,
        iconColor: AppColors.connectPink),
    DailyFeedItem(
        type: DailyFeedItemType.lifeBalanceTip,
        title: "Enjoy Life: Mindfulness",
        content:
            "Practice a few minutes of mindfulness or meditation daily to reduce stress and improve focus.",
        icon: Icons.self_improvement_outlined,
        iconColor: AppColors.mindfulnessPurple),
    DailyFeedItem(
        type: DailyFeedItemType.lifeBalanceTip,
        title: "Enjoy Life: Get Outdoors",
        content:
            "Spend some time in nature. Fresh air and sunlight can boost your mood and energy levels.",
        icon: Icons.park_outlined,
        iconColor: AppColors.outdoorsGreen),
    DailyFeedItem(
        type: DailyFeedItemType.lifeBalanceTip,
        title: "Enjoy Life: Celebrate Small Wins",
        content:
            "Acknowledge and celebrate your progress, no matter how small. It keeps motivation high!",
        icon: Icons.celebration_outlined,
        iconColor: AppColors.celebrateWinsAmber),

    // --- FUN FACTS ---
    DailyFeedItem(
        type: DailyFeedItemType.funFact,
        title: "Did You Know?",
        content:
            "The human brain generates about 12-25 watts of electricity – enough to power a low-wattage LED light bulb!",
        icon: Icons.emoji_objects_outlined,
        iconColor: AppColors.accentCyan),
    DailyFeedItem(
        type: DailyFeedItemType.funFact,
        title: "Fun Fact: Honey",
        content:
            "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible!",
        icon: Icons.hive_outlined,
        iconColor: AppColors.honeyAmber),
    DailyFeedItem(
        type: DailyFeedItemType.funFact,
        title: "Fun Fact: Octopus",
        content:
            "Octopuses have three hearts and blue blood. Two hearts pump blood through the gills, and the third circulates it to the rest of the body.",
        icon: Icons.phishing_outlined, // just a fun icon for sea creature
        iconColor: AppColors.octopusBlueGrey),
    DailyFeedItem(
        type: DailyFeedItemType.funFact,
        title: "Fun Fact: Bananas",
        content:
            "Bananas are berries, but strawberries aren't! Botanically speaking, berries are fruits produced from a single flower with one ovary.",
        icon: Icons.eco_outlined, // representing plants/nature
        iconColor: AppColors.bananasYellow),
    DailyFeedItem(
        type: DailyFeedItemType.funFact,
        title: "Fun Fact: Brain Storage",
        content:
            "The human brain's storage capacity is considered virtually unlimited. It doesn't get 'full' like a hard drive.",
        icon: Icons.sd_storage_outlined,
        iconColor: AppColors.brainStorageOrange),
  ];

  return items[DateTime.now().minute % items.length];
});
