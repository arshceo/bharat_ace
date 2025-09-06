// lib/widgets/discipline_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'timer_widget.dart';
import 'discipline_system.dart';

class DisciplineWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String screenName;
  final bool isTopicDetailScreen;

  const DisciplineWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.isTopicDetailScreen = false,
  });

  @override
  ConsumerState<DisciplineWrapper> createState() => _DisciplineWrapperState();
}

class _DisciplineWrapperState extends ConsumerState<DisciplineWrapper>
    with WidgetsBindingObserver {
  DateTime? _lastBreakCheck;
  DateTime? _screenStartTime;
  bool _isBreakDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screenStartTime = DateTime.now();
    AppTimerManager.startScreenTimer(widget.screenName);

    if (widget.isTopicDetailScreen) {
      _startBreakMonitoring();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppTimerManager.stopScreenTimer(widget.screenName);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Prevent app quit during discipline session
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (AppTimerManager.isDisciplineSessionActive() &&
          widget.isTopicDetailScreen) {
        // In a real app, you would use platform-specific methods to prevent app quit
        // For now, we'll just show a warning when they return
        _showAppQuitWarning();
      }
    }
  }

  void _startBreakMonitoring() {
    _checkForBreakTime();
  }

  void _checkForBreakTime() {
    if (!mounted || !widget.isTopicDetailScreen) return;

    // Check every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted &&
          AppTimerManager.shouldShowBreakDialog() &&
          !_isBreakDialogShowing) {
        _showBreakDialog();
      }
      _checkForBreakTime();
    });
  }

  void _showBreakDialog() {
    if (_isBreakDialogShowing) return;

    setState(() => _isBreakDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreakReminderDialog(
        accumulatedBreakTime: AppTimerManager.getAccumulatedBreakTime(),
        onTakeBreak: () {
          _handleTakeBreak();
        },
        onSkipBreak: () {
          _handleSkipBreak();
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isBreakDialogShowing = false);
      }
    });
  }

  void _handleTakeBreak() {
    ref.read(disciplineSystemProvider.notifier).startBreak();
    AppTimerManager.startBreak();

    final breakDuration =
        const Duration(minutes: 5) + AppTimerManager.getAccumulatedBreakTime();

    // Navigate to break screen or show break countdown
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BreakScreen(
          duration: breakDuration,
          onBreakComplete: () {
            ref.read(disciplineSystemProvider.notifier).endBreak();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _handleSkipBreak() {
    ref.read(disciplineSystemProvider.notifier).skipBreak();
    AppTimerManager.skipBreak();
  }

  void _showAppQuitWarning() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warning),
                const SizedBox(width: AppTheme.spaceXS),
                Text('Stay Focused!'),
              ],
            ),
            content: Text(
              'You\'re in discipline mode! Staying focused will help you achieve your goals faster.',
              style: AppTheme.textTheme.bodyMedium,
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Continue Learning'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during discipline session on topic detail screen
        if (AppTimerManager.isDisciplineSessionActive() &&
            widget.isTopicDetailScreen) {
          _showAppQuitWarning();
          return false;
        }
        return true;
      },
      child: widget.child,
    );
  }
}

class BreakScreen extends StatefulWidget {
  final Duration duration;
  final VoidCallback onBreakComplete;

  const BreakScreen({
    super.key,
    required this.duration,
    required this.onBreakComplete,
  });

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.duration;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.addListener(() {
      setState(() {
        _remainingTime = widget.duration * (1 - _controller.value);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onBreakComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent leaving break screen
      child: Scaffold(
        backgroundColor: AppTheme.success.withOpacity(0.1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space2XL),
                margin: const EdgeInsets.all(AppTheme.spaceLG),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.spa,
                      size: 80,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),
                    Text(
                      'Break Time!',
                      style: AppTheme.textTheme.headlineLarge?.copyWith(
                        color: AppTheme.gray900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(
                      'Take a deep breath, stretch, or hydrate.\nYou\'ll be back to learning soon!',
                      textAlign: TextAlign.center,
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.gray600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space2XL),

                    // Countdown timer
                    Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _controller.value,
                            strokeWidth: 8,
                            backgroundColor: AppTheme.gray200,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppTheme.success),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                                style:
                                    AppTheme.textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.gray900,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'remaining',
                                style: AppTheme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.space2XL),

                    // Break suggestions
                    Wrap(
                      spacing: AppTheme.spaceXS,
                      children: [
                        _buildBreakSuggestion('💧 Drink water'),
                        _buildBreakSuggestion('🧘‍♀️ Deep breaths'),
                        _buildBreakSuggestion('🤸‍♂️ Stretch'),
                        _buildBreakSuggestion('👀 Rest eyes'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakSuggestion(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceXS,
        vertical: AppTheme.space2XS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Text(
        text,
        style: AppTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.success,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
