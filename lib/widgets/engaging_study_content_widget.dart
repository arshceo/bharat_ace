// lib/widgets/engaging_study_content_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/study_task_model.dart';
import '../core/services/ai_content_service.dart';
import '../core/providers/student_details_provider.dart';
import '../core/providers/subscription_provider.dart';
import '../core/theme/app_theme.dart';
import '../screens/subscription/subscription_plans_screen.dart';

// Provider for the audio toggle state
final studyAudioToggleProvider = StateProvider<bool>((ref) => false);

class EngagingStudyContentWidget extends ConsumerStatefulWidget {
  final StudyTask task;
  final VoidCallback? onContentCompleted;

  const EngagingStudyContentWidget({
    super.key,
    required this.task,
    this.onContentCompleted,
  });

  @override
  ConsumerState<EngagingStudyContentWidget> createState() =>
      _EngagingStudyContentWidgetState();
}

class _EngagingStudyContentWidgetState
    extends ConsumerState<EngagingStudyContentWidget> {
  // Essential functionality variables only
  String _selectedLanguage = 'English';
  double _fontSize = 16.0;
  int _simplificationLevel = 0;
  String? _topicContent;
  bool _isLoadingContent = false;

  // Helper method to get theme-aware colors
  Color _getThemeAwareColor(Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkColor
        : lightColor;
  }

  @override
  void initState() {
    super.initState();
    _loadTopicContent();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Extract human-readable topic name from topic ID
  String _getReadableTopicName() {
    String topicName = widget.task.topic ?? widget.task.title;

    // If topic is in ID format like "sst_c6_ch1_hist_topic_what_past"
    if (topicName.contains('_topic_')) {
      // Extract the part after '_topic_' and format it
      final parts = topicName.split('_topic_');
      if (parts.length > 1) {
        topicName = parts[1]
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
            .join(' ');
      }
    } else if (topicName.contains('_')) {
      // General ID to readable name conversion
      topicName = topicName
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '')
          .join(' ');
    }

    return topicName;
  }

  // Process content and build formatted widgets with colors
  Widget _buildFormattedContent(String content) {
    // Clean markdown symbols
    String cleanedContent = content
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'') // Remove ** formatting
        .replaceAll(RegExp(r'##\s*([^\n]+)'), r'') // Remove ## formatting
        .replaceAll(RegExp(r'\*([^*]+)\*'), r''); // Remove single * formatting

    // Split content into sections based on common patterns
    List<String> sections =
        cleanedContent.split(RegExp(r'\n\s*\n')); // Split by double newlines

    List<Widget> contentWidgets = [];

    List<Color> sectionColors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.indigo.shade700,
      Colors.red.shade700,
    ];

    int colorIndex = 0;

    for (String section in sections) {
      if (section.trim().isEmpty) continue;

      Color sectionColor = sectionColors[colorIndex % sectionColors.length];
      colorIndex++;

      // Check if this looks like a section header (shorter text, often contains keywords)
      bool isHeader = section.trim().length < 100 &&
          (section.contains(':') ||
              section.trim().split(' ').length < 8 ||
              RegExp(r'^[A-Z][^.!?]*$').hasMatch(section.trim()));

      if (isHeader) {
        contentWidgets.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sectionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: sectionColor.withOpacity(0.3), width: 1),
            ),
            child: Text(
              section.trim(),
              style: TextStyle(
                fontSize: _fontSize + 4, // Larger font for headers
                fontWeight: FontWeight.bold,
                color: sectionColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else {
        // Regular content
        List<TextSpan> spans = [];
        List<String> sentences = section.split(RegExp(r'[.!?]+'));

        for (int i = 0; i < sentences.length; i++) {
          String sentence = sentences[i].trim();
          if (sentence.isEmpty) continue;

          // Check if sentence contains important keywords
          bool isImportant = RegExp(
                  r'\b(important|key|main|primary|essential|critical|remember|note|definition|conclusion)\b',
                  caseSensitive: false)
              .hasMatch(sentence);

          spans.add(
            TextSpan(
              text: sentence + (i < sentences.length - 1 ? '. ' : ''),
              style: TextStyle(
                fontSize: _fontSize + 2, // Increased base font size
                fontWeight: isImportant ? FontWeight.bold : FontWeight.w400,
                color: isImportant ? sectionColor : Colors.black87,
                height: 1.6,
              ),
            ),
          );
        }

        contentWidgets.add(
          Container(
            margin: EdgeInsets.symmetric(vertical: 6),
            child: RichText(
              text: TextSpan(children: spans),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets.isNotEmpty
          ? contentWidgets
          : [
              Text(
                cleanedContent,
                style: TextStyle(
                  fontSize: _fontSize + 2,
                  color: Colors.black87,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAudioOn = ref.watch(studyAudioToggleProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 20, 25, 60), // Deep blue background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(255, 20, 25, 60), // Deep blue
                      const Color.fromARGB(255, 30, 40, 100), // Lighter blue
                      const Color.fromARGB(
                          255, 45, 55, 120), // Even lighter blue
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Decorative stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.yellow, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Topic Title - Centered and attractive
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.pink.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _getReadableTopicName(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _fontSize + 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Fun emoji decorations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🚀', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Text('📚', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Text('⭐', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Text('🎯', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Content Container
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_isLoadingContent)
                              Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.purple.shade400,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Loading awesome content for you! 🌟',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.purple.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              _buildFormattedContent(
                                _topicContent ??
                                    'Getting ready to learn something amazing! ✨',
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      // Bottom decorative elements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Keep Learning!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('🎉', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.1),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(context, isAudioOn),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isAudioOn) {
    // Check if this is a quiz to disable chat (from task type)
    final bool isQuiz = widget.task.type == TaskType.quiz;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme
            .darkBg, // Always keep the bottom bar dark for better contrast
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildBottomBarButton(
                Icons.language,
                onTap: _showLanguageSelector,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(studyAudioToggleProvider.notifier).state =
                      !isAudioOn;
                },
                child: _buildBottomBarButton(
                  isAudioOn ? Icons.volume_up : Icons.volume_off,
                ),
              ),
              const SizedBox(width: 8),
              _buildBottomBarButton(
                Icons.text_decrease,
                onTap: _decreaseFontSize,
              ),
              const SizedBox(width: 8),
              _buildBottomBarButton(
                Icons.text_increase,
                onTap: _increaseFontSize,
              ),
              const SizedBox(width: 8),
              _buildBottomBarButton(
                Icons.auto_fix_high,
                onTap: _simplifyContent,
              ),
              const SizedBox(width: 8),
              // Chat button - disabled during quizzes
              if (!isQuiz)
                _buildBottomBarButton(
                  Icons.chat_bubble_outline,
                  onTap: _openStudyChat,
                ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.check, color: Colors.black, size: 28),
              onPressed: _handleMastery,
              splashColor: Colors.grey.withOpacity(0.3),
              highlightColor: Colors.grey.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.language, color: Colors.purple, size: 28),
            SizedBox(width: 10),
            Text(
              'Choose Language 🌍',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Hindi', 'Tamil', 'Telugu', 'Gujarati']
                .map((lang) => Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedLanguage == lang
                            ? Colors.purple.shade50
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _selectedLanguage == lang
                              ? Colors.purple
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          lang,
                          style: TextStyle(
                            fontWeight: _selectedLanguage == lang
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedLanguage == lang
                                ? Colors.purple.shade700
                                : Colors.black87,
                          ),
                        ),
                        leading: Radio<String>(
                          value: lang,
                          groupValue: _selectedLanguage,
                          onChanged: (value) {
                            setState(() => _selectedLanguage = value!);
                            Navigator.pop(context);
                            _loadTopicContent();
                          },
                          activeColor: Colors.purple,
                        ),
                        onTap: () {
                          setState(() => _selectedLanguage = lang);
                          Navigator.pop(context);
                          _loadTopicContent();
                        },
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 24.0) _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 12.0) _fontSize -= 2.0;
    });
  }

  void _simplifyContent() async {
    final userSubscription = ref.read(userSubscriptionProvider);
    final subject = widget.task.subject;

    if (!userSubscription.canSimplifyContent(subject)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkCard
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text(
                'Premium Feature! ⭐',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.pink.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎯', style: TextStyle(fontSize: 40)),
                SizedBox(height: 10),
                Text(
                  'Content simplification makes learning super easy! Unlock this amazing feature now! 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Upgrade Now! 🎉',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoadingContent = true);

    try {
      _simplificationLevel++;
      // Simulate content simplification
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _topicContent = "📝 Simplified Version $_simplificationLevel: " +
            (_topicContent ??
                "This content has been made easier to understand! 🌟");
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() => _isLoadingContent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oops! Failed to simplify content. Try again! 😅'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleMastery() {
    if (widget.onContentCompleted != null) {
      widget.onContentCompleted!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('🎉'),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Awesome! You\'ve mastered ${_getReadableTopicName()}! Keep it up, superstar! ⭐',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    }
  }

  // Method to open study chat
  void _openStudyChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkCard
                  : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: Offset(0, 1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.group, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Buddies Chat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Ask questions and help each other',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Message area (placeholder)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildChatMessage(
                          'Raj',
                          'Hey everyone! I\'m having trouble understanding the concept. Can someone help?',
                          isMe: false,
                          time: '10:30 AM',
                          avatar: 'R',
                          avatarColor: Colors.blue,
                        ),
                        _buildChatMessage(
                          'Meera',
                          'Sure! Which part specifically?',
                          isMe: false,
                          time: '10:32 AM',
                          avatar: 'M',
                          avatarColor: Colors.green,
                        ),
                        _buildChatMessage(
                          'You',
                          'I think it\'s about the main principles we just covered.',
                          isMe: true,
                          time: '10:33 AM',
                          avatar: 'Y',
                          avatarColor: Colors.purple,
                        ),
                        _buildChatMessage(
                          'Raj',
                          'Yes, exactly! I\'m confused about how these principles apply in real-world scenarios.',
                          isMe: false,
                          time: '10:34 AM',
                          avatar: 'R',
                          avatarColor: Colors.blue,
                        ),
                        _buildChatMessage(
                          'Priya',
                          'Let me share an example that helped me understand...',
                          isMe: false,
                          time: '10:35 AM',
                          avatar: 'P',
                          avatarColor: Colors.orange,
                        ),
                        _buildChatMessage(
                          'Priya',
                          'Think of it like this: [example explanation with real-world application]',
                          isMe: false,
                          time: '10:36 AM',
                          avatar: 'P',
                          avatarColor: Colors.orange,
                        ),
                        _buildChatMessage(
                          'Raj',
                          'That makes so much more sense now! Thank you!',
                          isMe: false,
                          time: '10:38 AM',
                          avatar: 'R',
                          avatarColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _getThemeAwareColor(Colors.white, AppTheme.darkSurface),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        offset: Offset(0, -1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                          onPressed: () {
                            // Show message sent confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message sent!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to build chat message bubbles
  Widget _buildChatMessage(
    String sender,
    String message, {
    required bool isMe,
    required String time,
    required String avatar,
    required Color avatarColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isMe ? Colors.purple : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.purple.shade100 : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: isMe ? const Radius.circular(16) : Radius.zero,
                      topRight: isMe ? Radius.zero : const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.purple.shade800 : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                avatar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadTopicContent() async {
    setState(() => _isLoadingContent = true);

    try {
      final studentAsync = ref.read(studentDetailsProvider);
      final student = studentAsync.valueOrNull;

      if (student == null) {
        setState(() {
          _topicContent =
              '🤖 Getting amazing content ready for you! Please wait a moment... ✨';
          _isLoadingContent = false;
        });
        return;
      }

      final contentService = ref.read(aiContentGenerationServiceProvider);
      final generatedContent = await contentService.generateTopicContent(
        subject: widget.task.subject,
        chapter: widget.task.chapter ?? 'General',
        topic: widget.task.topic ?? widget.task.subject,
        studentClass: student.grade,
        board: student.board,
        additionalPromptSegment: _selectedLanguage != 'English'
            ? 'Provide explanations in $_selectedLanguage language.'
            : '',
      );

      setState(() {
        _topicContent = generatedContent;
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _topicContent =
            '🔄 Hmm, something went wrong! Let\'s try again in a moment! Don\'t worry, we\'ll get your awesome content ready soon! 🌟';
        _isLoadingContent = false;
      });
    }
  }
}
