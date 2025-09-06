// lib/widgets/discipline_system.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';

// Provider for discipline system state
final disciplineSystemProvider =
    StateNotifierProvider<DisciplineSystemNotifier, DisciplineSystemState>(
        (ref) {
  return DisciplineSystemNotifier();
});

class DisciplineSystemState {
  final bool isActive;
  final Duration remainingTime;
  final bool isOnBreak;
  final Duration accumulatedBreakTime;
  final DateTime? lastBreakCheck;

  const DisciplineSystemState({
    this.isActive = false,
    this.remainingTime = Duration.zero,
    this.isOnBreak = false,
    this.accumulatedBreakTime = Duration.zero,
    this.lastBreakCheck,
  });

  DisciplineSystemState copyWith({
    bool? isActive,
    Duration? remainingTime,
    bool? isOnBreak,
    Duration? accumulatedBreakTime,
    DateTime? lastBreakCheck,
  }) {
    return DisciplineSystemState(
      isActive: isActive ?? this.isActive,
      remainingTime: remainingTime ?? this.remainingTime,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      accumulatedBreakTime: accumulatedBreakTime ?? this.accumulatedBreakTime,
      lastBreakCheck: lastBreakCheck ?? this.lastBreakCheck,
    );
  }
}

class DisciplineSystemNotifier extends StateNotifier<DisciplineSystemState> {
  DisciplineSystemNotifier() : super(const DisciplineSystemState()) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _updateState();
  }

  void _updateState() {
    final isActive = AppTimerManager.isDisciplineSessionActive();
    final remainingTime = AppTimerManager.getRemainingDisciplineTime();
    final accumulatedBreakTime = AppTimerManager.getAccumulatedBreakTime();

    state = state.copyWith(
      isActive: isActive,
      remainingTime: remainingTime,
      accumulatedBreakTime: accumulatedBreakTime,
    );

    if (isActive) {
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) _updateState();
      });
    }
  }

  void startBreak() {
    AppTimerManager.startBreak();
    state = state.copyWith(isOnBreak: true);
  }

  void skipBreak() {
    AppTimerManager.skipBreak();
    state = state.copyWith(lastBreakCheck: DateTime.now());
  }

  void endBreak() {
    state = state.copyWith(isOnBreak: false);
  }
}

class BreakReminderDialog extends StatelessWidget {
  final Duration accumulatedBreakTime;
  final VoidCallback onTakeBreak;
  final VoidCallback onSkipBreak;

  const BreakReminderDialog({
    super.key,
    required this.accumulatedBreakTime,
    required this.onTakeBreak,
    required this.onSkipBreak,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXS),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              Icons.self_improvement,
              color: AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            'Time for a Break!',
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.gray900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You\'ve been studying for 25 minutes. Taking short breaks helps improve focus and retention.',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.gray700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          if (accumulatedBreakTime.inMinutes > 0)
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.info,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Text(
                    'Saved break time: ${accumulatedBreakTime.inMinutes} minutes',
                    style: AppTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTheme.spaceMD),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppTheme.success,
                  size: 32,
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  'Recommended 5-minute break',
                  style: AppTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSkipBreak();
          },
          child: Text(
            'Skip (Save for later)',
            style: TextStyle(color: AppTheme.gray600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onTakeBreak();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
          ),
          child: const Text('Take Break'),
        ),
      ],
    );
  }
}

class EmergencyBreakButton extends StatefulWidget {
  const EmergencyBreakButton({super.key});

  @override
  State<EmergencyBreakButton> createState() => _EmergencyBreakButtonState();
}

class _EmergencyBreakButtonState extends State<EmergencyBreakButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _showEmergencyBreakDialog(context),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXS),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppTheme.error.withOpacity(0.2)
              : AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(
            color: AppTheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.emergency,
          color: AppTheme.error,
          size: 16,
        ),
      ),
    );
  }

  void _showEmergencyBreakDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmergencyBreakDialog(),
    );
  }
}

class EmergencyBreakDialog extends StatefulWidget {
  @override
  State<EmergencyBreakDialog> createState() => _EmergencyBreakDialogState();
}

class _EmergencyBreakDialogState extends State<EmergencyBreakDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordCorrect = false;
  String _selectedBreakType = 'timed';
  int _selectedMinutes = 30;

  // This should be configured by parents or stored securely
  final String _parentPassword =
      '1234'; // In real app, this should be hashed/encrypted

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXS),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(
              Icons.emergency,
              color: AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceXS),
          Text(
            'Emergency Break',
            style: AppTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.gray900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content:
          _isPasswordCorrect ? _buildBreakOptions() : _buildPasswordInput(),
      actions: _buildActions(context),
    );
  }

  Widget _buildPasswordInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parent password required for emergency break',
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.gray700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Parent Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onChanged: (value) {
            if (value == _parentPassword) {
              setState(() => _isPasswordCorrect = true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBreakOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select break duration:',
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.gray900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMD),

        // Timed break option
        RadioListTile<String>(
          value: 'timed',
          groupValue: _selectedBreakType,
          onChanged: (value) => setState(() => _selectedBreakType = value!),
          title: Text('Timed Break'),
          subtitle: Text('Resume after selected time'),
        ),

        if (_selectedBreakType == 'timed')
          Padding(
            padding: const EdgeInsets.only(left: AppTheme.space2XL),
            child: DropdownButton<int>(
              value: _selectedMinutes,
              items: [15, 30, 60, 120, 180].map((minutes) {
                return DropdownMenuItem(
                  value: minutes,
                  child: Text('$minutes minutes'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedMinutes = value!),
            ),
          ),

        // Full day break option
        RadioListTile<String>(
          value: 'fullday',
          groupValue: _selectedBreakType,
          onChanged: (value) => setState(() => _selectedBreakType = value!),
          title: Text('Full Day Break'),
          subtitle: Text('App will be restricted until tomorrow'),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (!_isPasswordCorrect) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          // Implement emergency break logic here
          Navigator.of(context).pop();
          _showBreakActiveDialog(context);
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
        child: Text('Start Break'),
      ),
    ];
  }

  void _showBreakActiveDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        title: Text('Break Active'),
        content: Text(
          _selectedBreakType == 'timed'
              ? 'Emergency $_selectedMinutes-minute break started. The app will be restricted during this time.'
              : 'Full day break started. The app will be restricted until tomorrow.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Exit the app or navigate to a break screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
