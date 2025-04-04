import 'dart:async'; // Import for Timer

import 'package:bharat_ace/core/providers/topic_details_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the audio toggle state
final audioToggleProvider = StateProvider<bool>((ref) => false);

class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  // Timer for countdown
  Timer? _timer;
  int _remainingSeconds = 11 * 60 + 48; // Initial time: 00:11:48 -> seconds

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel(); // Stop the timer when it reaches 0
        // You could trigger some action here (e.g., show a notification)
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60) % 60; // Correct minutes calculation
    final hours = totalSeconds ~/ 3600;
    final seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final topicData = ref.watch(topicProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isAudioOn =
        ref.watch(audioToggleProvider); // Watch the audio toggle state

    return Scaffold(
      backgroundColor: const Color(0xFF6200EE),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.transparent
                    ], // White at the top, transparent at the bottom
                    stops: [0.0, 1], // Adjust stops for the fade effect
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topicData['title']!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"${topicData['subtitle']!}"',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        topicData['body']!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.2),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            // Wrap in a Row for horizontal layout
            children: [
              const Icon(
                  Icons
                      .circle, // This is just a placeholder, change to your actual icon if you use it
                  color: Colors.white,
                  size: 16), // Adjust size as needed
              const SizedBox(width: 8),
              Text(
                _formatTime(_remainingSeconds), // Display formatted time
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Close the screen
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isAudioOn) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
          // Add a subtle border on top
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Placeholder buttons (replace with your actual icons and logic)
              _buildBottomBarButton(Icons.menu),
              const SizedBox(width: 16),
              GestureDetector(
                  onTap: () {
                    // Toggle the audio state using ref.read(...).state = ...
                    ref.read(audioToggleProvider.notifier).state = !isAudioOn;
                  },
                  child: _buildBottomBarButton(
                      isAudioOn ? Icons.volume_up : Icons.volume_off)),
              const SizedBox(width: 16),
              _buildBottomBarButton(Icons.text_format),
            ],
          ),
          Ink(
            decoration: const ShapeDecoration(
              color: Colors.white, // White background for the circle
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF6200EE)),
              // Purple checkmark
              onPressed: () {
                // Handle checkmark tap
              },
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBarButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
