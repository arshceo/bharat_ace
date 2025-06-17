import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts
import 'package:percent_indicator/percent_indicator.dart'; // For progress rings

// Data Models (You'll likely want to move these to separate files)
class StudySession {
  final DateTime startTime;
  DateTime? endTime;

  StudySession({required this.startTime});

  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;
}

class DailyProgress {
  final DateTime date;
  final List<StudySession> sessions;
  int xpEarned;

  DailyProgress(
      {required this.date, this.sessions = const [], this.xpEarned = 0});

  Duration get totalStudyTime =>
      sessions.fold(Duration.zero, (sum, session) => sum + session.duration);
}

// Riverpod Providers
final studySessionProvider = StateProvider<StudySession?>((ref) => null);
final dailyProgressProvider =
    StateNotifierProvider<DailyProgressNotifier, DailyProgress>((ref) {
  return DailyProgressNotifier(date: DateTime.now(), read: null);
});

class DailyProgressNotifier extends StateNotifier<DailyProgress> {
  DailyProgressNotifier({required DateTime date, required this.read})
      : super(DailyProgress(date: date));
  final Ref? read;

  void startSession() {
    state = DailyProgress(
        date: state.date,
        sessions: [...state.sessions, StudySession(startTime: DateTime.now())]);

    read?.read(studySessionProvider.notifier).state =
        state.sessions.last; // Update the current session
  }

  void endSession() {
    if (state.sessions.isNotEmpty && state.sessions.last.endTime == null) {
      List<StudySession> updatedSessions = [...state.sessions];
      updatedSessions.last.endTime = DateTime.now();

      state = DailyProgress(
          date: state.date,
          sessions: updatedSessions,
          xpEarned: state.xpEarned);
      read?.read(studySessionProvider.notifier).state =
          null; // Clear current session
    }
  }

  // Add XP
  void addXP(int amount) {
    state = DailyProgress(
        date: state.date,
        sessions: state.sessions,
        xpEarned: state.xpEarned + amount);
  }
}

// ... (Other providers for weekly, monthly, yearly progress, breaks, etc.)

// Provider for managing break minutes (break bucket)
final breakBucketProvider = StateProvider<int>((ref) => 0);

final List<String> motivationalQuotes = [
  "The only way to do great work is to love what you do. - Steve Jobs",
  "Believe you can and you're halfway there. - Theodore Roosevelt",
  "The mind is everything. What you think you become. – Buddha",
  "The expert in anything was once a beginner. – Helen Hayes",
  // Add more quotes here...
];

// Constants
const Color darkBg = Color(0xFF12121F);
const Color primaryPurple = Color(0xFF8A2BE2);
const Color accentCyan = Color(0xFF00FFFF);
const Color textPrimary = Color(0xFFEAEAEA);
const Color textSecondary = Color(0xFFAAAAAA);
const Color surfaceDark = Color(0xFF1E1E2E);

// UI Code (Progress Screen)
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends ConsumerState<ProgressScreen> {
  Duration _currentSessionDuration = Duration.zero;
  Timer? _sessionTimer;
  bool _isBreakActive = false; // Track break status
  String _currentQuote = ''; // Store the current quote
  double _dailyProgressPercent = 0.0; // Store the daily progress percentage
  List<FlSpot> _chartSpots = []; // Store the chart data
  int _breakBucketMinutes = 0; // State for break bucket minutes
  bool _showBucketAnimation = false; // Control the animation visibility
  int _animatedBucketMinutes = 0; // State for the animated bucket value
  static const platform =
      MethodChannel('com.example.bharatace/app_control'); // Define the channel
  @override
  void initState() {
    // Initialize quote and chart data once when the widget is created
    super.initState();
    _currentQuote =
        motivationalQuotes[Random().nextInt(motivationalQuotes.length)];
    _dailyProgressPercent =
        _calculateDailyProgress(); // Initialize with the calculated progress
    _chartSpots = _generateChartData(); //Initialize chart data
    _breakBucketMinutes = ref.read(breakBucketProvider);
    _animatedBucketMinutes = _breakBucketMinutes;
// Initialize break bucket minutes from provider
  }

  double _calculateDailyProgress() {
    // Calculate daily progress percentage
    final dailyProgress = ref.read(dailyProgressProvider);
    return min(dailyProgress.totalStudyTime.inMinutes / (8 * 60), 1.0);
  }

  List<FlSpot> _generateChartData() {
    // Generate chart data points
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), Random().nextDouble() * 5));
    }
    return spots;
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSessionDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
  }

  _showBreakConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Time for a Break!"),
          content: const Text(
              "You've studied for 25 minutes. Would you like to take a 5-minute break now?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Snooze (5 mins)"),
              onPressed: () {
                Navigator.of(context).pop();
                _startBreak();
              },
            ),
            TextButton(
              child: const Text("Not Now"),
              onPressed: () {
                Navigator.of(context).pop();
                _addToBreakBucket(5); // Add 5 minutes to the break bucket
              },
            ),
          ],
        );
      },
    );
  }

  void _startBreak() {
    _disableAppBlocking();

    //Starts 5 min break
    setState(() => _isBreakActive = true);
    _sessionTimer = Timer(const Duration(minutes: 5), () {
      //Timer for 5 minutes for testing purposes only
      setState(() => _isBreakActive = false);
      // Show a notification or alert when the break is over
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Break Time Over'),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'))
                ],
              ));
    });
  }

  void _addToBreakBucket(int minutes) {
    setState(() {
      _breakBucketMinutes += minutes;
      _showBucketAnimation = true; // Start the animation
    });
    ref.read(breakBucketProvider.notifier).state =
        _breakBucketMinutes; //Update break bucket provider

    Timer(const Duration(milliseconds: 500), () {
      // Animation duration (adjust as needed)
      setState(() {
        _animatedBucketMinutes = _breakBucketMinutes;
        _showBucketAnimation = false; // Hide animation after completion
      });
    });
  }

  void _showBreakOverDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Break's Over!"),
          content: const Text("It's time to get back to studying."),
          actions: <Widget>[
            TextButton(
              child: const Text("Back to Study"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _useBreakFromBucket() {
    //Use accumulated breaks
    if (_breakBucketMinutes >= 5) {
      //Check if enough break time in bucket
      setState(() {
        _breakBucketMinutes -= 5;
      });
      ref.read(breakBucketProvider.notifier).state =
          _breakBucketMinutes; //Update break bucket provider
      _startBreak();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not enough break time in the bucket")));
    }
  }

  Future<void> _enableAppBlocking() async {
    // Platform channel call
    List<String> appsToBlock = [
      'com.google.android.youtube',
      'com.instagram.android',
      'in.swiggy.android',
      'com.zomato.com',
      'com.facebook.katana',
      'com.twitter.android',
      'com.snapchat.android',
      'com.netflix.mediaclient',
      'com.spotify.music',
      'com.amazon.music',
      'com.spotify.premium',
      'com.reddit.frontpage',
      'com.pinterest',
      'com.quora.android',
      'com.linkedin.android',
      'com.tiktok',
    ]; //Replace with actual package names of apps to block
    try {
      await platform.invokeMethod('enableAppBlocking',
          {'appPackageNames': appsToBlock}); // Pass the list of apps to block
    } on PlatformException catch (e) {
      print('Error enabling app blocking: ${e.message}');
    }
  }

  Future<void> _disableAppBlocking() async {
    // Platform channel call
    try {
      await platform.invokeMethod('disableAppBlocking');
    } on PlatformException catch (e) {
      print('Error disabling app blocking: ${e.message}');
    }
  }

  // void _startSession() {
  //   ref.read(dailyProgressProvider.notifier).startSession();
  //   setState(() {
  //     _currentSessionDuration = Duration.zero;
  //   });
  //   _startSessionTimer();
  // }
  void _startSession() {
    ref.read(dailyProgressProvider.notifier).startSession();
    _enableAppBlocking(); // Call to enable app blocking here
    setState(() {
      _currentSessionDuration = Duration.zero;
    });
    _startSessionTimer();
    _sessionTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      // Use seconds for testing
      if (!_isBreakActive) {
        _showBreakConfirmationDialog();
        timer.cancel();
      }
    });
  }

  void _endSession() {
    ref.read(dailyProgressProvider.notifier).endSession();
    _disableAppBlocking(); // Disable blocking when session ends
    _stopSessionTimer();
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(studySessionProvider);
    final dailyProgress = ref.watch(dailyProgressProvider);

    String formattedTime =
        _formatDuration(_currentSessionDuration); // Format the duration

    return WillPopScope(
        // Wrap your Scaffold in WillPopScope
        onWillPop: () async {
          // Asynchronous callback

          //Show dialog
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Exit Study Session?'),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, false), // Stay in app
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true), // Allow exit
                    child: const Text('Yes'),
                  ),
                ],
              );
            },
          );

          // If the dialog returns true (user confirmed), allow the app to exit.
          return shouldPop!;
        },
        child: Scaffold(
            backgroundColor: darkBg, // Use dark background
            appBar: AppBar(
              title: const Text(
                'Study Progress',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textPrimary), // Light text
              ),
              backgroundColor: surfaceDark, // Dark app bar
              iconTheme: const IconThemeData(color: textPrimary), // Light icons
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),

                  // 1. Motivational Quote
                  Card(
                    elevation: 4, // Add shadow
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.format_quote,
                                size: 40, color: accentCyan),
                            const SizedBox(height: 10),
                            Text(
                              _currentQuote, // Use _currentQuote
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ), // Daily Progress Ring
                  CircularPercentIndicator(
                    radius: 100,
                    lineWidth: 20,
                    percent: _dailyProgressPercent,
                    progressColor: accentCyan,
                    backgroundColor: surfaceDark,
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_dailyProgressPercent * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimary),
                        ),
                        const Text(
                          'of daily goal',
                          style: TextStyle(color: textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  // 3. Current Session Timer and Buttons
                  Text(
                    formattedTime,
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green, // Change the background color
                          ),
                          onPressed: currentSession != null
                              ? null
                              : () {
                                  ref
                                      .read(dailyProgressProvider.notifier)
                                      .startSession();
                                  _currentSessionDuration = Duration.zero;
                                  _startSessionTimer();
                                },
                          child: const Text(
                            'Start',
                            style: TextStyle(color: Colors.white),
                          )),
                      const SizedBox(width: 20),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.red, // Change the background color
                          ),
                          onPressed: currentSession == null
                              ? null
                              : () {
                                  ref
                                      .read(dailyProgressProvider.notifier)
                                      .endSession();
                                  _stopSessionTimer();
                                },
                          child: const Text(
                            'End',
                            style: TextStyle(color: Colors.white),
                          )),
                    ],
                  ),
                  // 1. Current Session/Timer Area
                  // (Add a timer display and start/end buttons)
                  Text(
                      'Current Session: ${_formatDuration(_currentSessionDuration)}'),
                  ElevatedButton(
                    onPressed: currentSession != null ? null : _startSession,
                    child: const Text('Start Session'),
                  ),
                  ElevatedButton(
                    onPressed: currentSession == null ? null : _endSession,
                    child: const Text('End Session'),
                  ),
                  const SizedBox(height: 30),
                  // 2. Break/Snooze Area (Implement break logic here)

                  // 3. Daily Progress Display
                  Text(
                      'Today\'s Progress: ${dailyProgress.totalStudyTime}'), // Format duration
                  Text('XP Earned Today: ${dailyProgress.xpEarned}'),
                  Stack(
                      // Use a Stack for the animation
                      alignment: Alignment.center,
                      children: [
                        // Bucket Icon
                        Icon(
                          Icons
                              .inbox, // Changed from Icons.bucket to a valid icon
                          size: 80,
                          color: _isBreakActive
                              ? Colors.grey
                              : primaryPurple, // Disable if break is active),
                        ),

                        if (_showBucketAnimation) ...[
                          // Show animation only when active

                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            top:
                                0, // Adjust position of the animated + icon as needed
                            left: 0,
                            child: Icon(
                              Icons.add_circle,
                              color: Colors.green,
                              size: 30,
                            ),
                          ), // Animated + sign
                        ],

                        Positioned(
                            // Position the break minutes text in the bucket center
                            top: 30,
                            child: Text(
                                '${_animatedBucketMinutes}m', // Animated value here
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isBreakActive
                                        ? Colors.grey[400]
                                        : textPrimary))),
                      ]),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isBreakActive ? null : _useBreakFromBucket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBreakActive
                          ? Colors.grey
                          : primaryPurple, // Disable if break is active
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Use Break from Bucket ($_breakBucketMinutes mins)', // Show bucket minutes
                      style: const TextStyle(color: textPrimary),
                    ),
                  ),
                  // (Add more details as needed)
                  const SizedBox(height: 30),

                  // 4. Progress Charts/Graphs (Use fl_chart or other chart library)
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        // ... update this with styling based on main_layout_screen.dart
                        backgroundColor:
                            surfaceDark, // Example chart background color
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),

                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: ((value, meta) {
                                    // Customize x-axis labels (days of the week)
                                    const weekdays = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    return Text(
                                      weekdays[value.toInt()],
                                      style:
                                          const TextStyle(color: textSecondary),
                                    );
                                  }))),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartSpots,
                            isCurved: true,
                            color: accentCyan,
                            barWidth: 4, // Adjust line width
                            belowBarData: BarAreaData(
                              show: true,
                              color: accentCyan.withOpacity(0.3),
                            ),
                            dotData: FlDotData(
                                show: false), // Show data points if desired
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )));
  }
}
