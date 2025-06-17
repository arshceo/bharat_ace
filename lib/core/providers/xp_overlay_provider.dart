// lib/core/providers/xp_overlay_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class XpOverlayState {
  final bool isVisible;
  final int? amount;
  final String? message;
  final String? subMessage; // Optional sub-message for context

  XpOverlayState({
    this.isVisible = false,
    this.amount,
    this.message,
    this.subMessage,
  });

  XpOverlayState copyWith({
    bool? isVisible,
    int? amount,
    String? message,
    String? subMessage,
  }) {
    return XpOverlayState(
      isVisible: isVisible ?? this.isVisible,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      subMessage: subMessage ?? this.subMessage,
    );
  }
}

final xpOverlayProvider =
    StateNotifierProvider<XpOverlayNotifier, XpOverlayState>((ref) {
  return XpOverlayNotifier();
});

class XpOverlayNotifier extends StateNotifier<XpOverlayState> {
  XpOverlayNotifier() : super(XpOverlayState());

  Timer? _timer;

  void showOverlay({
    required int amount,
    required String message,
    String? subMessage, // e.g., "Level Complete!"
    Duration duration = const Duration(seconds: 3),
  }) {
    _timer?.cancel(); // Cancel any existing timer

    state = XpOverlayState(
      isVisible: true,
      amount: amount,
      message: message,
      subMessage: subMessage,
    );

    _timer = Timer(duration, () {
      state = state.copyWith(isVisible: false);
    });
  }

  void hideOverlay() {
    _timer?.cancel();
    state = state.copyWith(isVisible: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
