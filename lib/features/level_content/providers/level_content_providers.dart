// lib/features/level_content/providers/level_content_providers.dart
import 'dart:collection'; // For SplayTreeMap
import 'package:flutter/material.dart'; // For TextSelection, TextRange
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- UI State Providers for LevelContentScreen ---
final isListeningProvider = StateProvider.autoDispose<bool>((ref) => false);
final isAnsweringProvider = StateProvider.autoDispose<bool>((ref) => false);
final qaHistoryProvider =
    StateProvider.autoDispose<List<Map<String, String>>>((ref) => []);

// --- Reader Settings Providers ---
final currentFontSizeMultiplierProvider = StateProvider<double>((ref) => 1.0);
final currentFontFamilyProvider = StateProvider<String>((ref) => 'Roboto');
final highlightsProvider =
    StateProvider<Map<String, List<TextSelection>>>((ref) => SplayTreeMap());
final keyNotesProvider =
    StateProvider<Map<String, List<String>>>((ref) => SplayTreeMap());

// --- TTS State Providers ---
enum TtsState { playing, paused, stopped, buffering, error }

final ttsStateProvider = StateProvider<TtsState>((ref) => TtsState.stopped);
final currentSpeakingIdProvider = StateProvider<String?>((ref) => null);
final ttsHighlightRangeProvider = StateProvider<TextRange?>((ref) => null);
final currentSpokenTextProvider =
    StateProvider<String>((ref) => ""); // Text being spoken by TTS
final ttsRestartOffsetProvider =
    StateProvider<int>((ref) => 0); // For restarting TTS from a point

// --- Language Selection Provider ---
enum TargetLanguage { english, punjabiEnglish, hindi, hinglish }

final targetLanguageProvider =
    StateProvider<TargetLanguage>((ref) => TargetLanguage.english);

// Note: The LevelContentController and its specific provider (levelContentControllerProvider)
// will be in `level_content_controller.dart` because of its complexity and direct
// responsibility for fetching and managing the main content data for the screen.
