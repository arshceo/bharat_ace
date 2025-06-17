// lib/screens/home/widgets/ai_chat_widget.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:bharat_ace/core/models/chat_message.dart';
import 'package:bharat_ace/core/models/daily_feed_item.dart';
import 'package:bharat_ace/core/services/gemini_service.dart';

import '../../core/theme/app_colors.dart';

class AiChatWidget extends ConsumerStatefulWidget {
  final DailyFeedItem? item; // Make item nullable

  const AiChatWidget({super.key, this.item}); // Update constructor

  @override
  ConsumerState<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends ConsumerState<AiChatWidget> {
  final List<ChatMessage> _messages = [];
  final List<gen_ai.Content> _geminiHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    String initialAiMessageText;
    // String chatTitle; // chatTitle is now built in the build method

    if (widget.item != null) {
      final initialContent = widget.item!.content;
      final truncatedContent =
          initialContent.substring(0, min(initialContent.length, 80));
      initialAiMessageText =
          "Hello! You were looking at '${widget.item!.title}', which is about \"$truncatedContent${initialContent.length > 80 ? "..." : ""}\". How can I help you explore this topic further?";
      // chatTitle = "Chat about: ${widget.item!.title}";
    } else {
      // General chat
      initialAiMessageText =
          "Hello! I'm your AI assistant. How can I help you today?";
      // chatTitle = "Ask AI Anything";
    }

    final initialChatMessage =
        ChatMessage(text: initialAiMessageText, isUserMessage: false);
    _messages.add(initialChatMessage);
    _geminiHistory
        .add(gen_ai.Content.model([gen_ai.TextPart(initialAiMessageText)]));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final String userInputText = _chatController.text.trim();
    if (userInputText.isEmpty || _isLoading) return;

    _chatController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userInputText, isUserMessage: true));
      _isLoading = true;
      _messages.add(ChatMessage(
          text: "● ● ●", isUserMessage: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();

    final geminiService = ref.read(geminiEvaluationServiceProvider);

    final int aiMessageIndex = _messages.length - 1;
    String currentAiResponseText = "";
    // List<gen_ai.Content> historyForThisCall = List.from(_geminiHistory); // Not used

    try {
      final stream = geminiService.generateChatResponseStream(
        userInputText,
        history: _geminiHistory,
      );

      await for (final chunk in stream) {
        currentAiResponseText += chunk;
        if (mounted) {
          setState(() {
            _messages[aiMessageIndex] = ChatMessage(
              text: currentAiResponseText.isEmpty
                  ? "● ● ●"
                  : currentAiResponseText,
              isUserMessage: false,
              timestamp: _messages[aiMessageIndex].timestamp,
            );
          });
          _scrollToBottom();
        }
      }

      if (mounted &&
          currentAiResponseText.isEmpty &&
          !_messages[aiMessageIndex].text.startsWith("Error")) {
        setState(() {
          _messages[aiMessageIndex] = ChatMessage(
            text:
                "I don't have a specific response for that right now. Could you try rephrasing?",
            isUserMessage: false,
            timestamp: _messages[aiMessageIndex].timestamp,
          );
        });
      }
    } catch (e) {
      // print("Error in AiChatWidget sending message: $e"); // Consider a logger
      if (mounted) {
        setState(() {
          _messages[aiMessageIndex] = ChatMessage(
            text:
                "Sorry, an error occurred while I was thinking. Please try again.", // User-friendly error
            isUserMessage: false,
            timestamp: _messages[aiMessageIndex].timestamp,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (currentAiResponseText.isNotEmpty &&
          !_messages[aiMessageIndex].text.startsWith("Error") &&
          !_messages[aiMessageIndex].text.startsWith("Sorry")) {
        _geminiHistory.add(gen_ai.Content.text(userInputText));
        _geminiHistory.add(
            gen_ai.Content.model([gen_ai.TextPart(currentAiResponseText)]));
      } else {
        // Add user input to history even if AI errored, so context isn't lost for next turn.
        _geminiHistory.add(gen_ai.Content.text(userInputText));
        // Add a placeholder for the model's turn if there was an error or no response
        _geminiHistory.add(gen_ai.Content.model([
          gen_ai.TextPart("Model response was empty or errored for this turn.")
        ]));
      }
      if (mounted) _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String chatTitle;
    String hintText;

    if (widget.item != null) {
      chatTitle = "Chat about: ${widget.item!.title}";
      hintText = "Ask about ${widget.item!.title}...";
    } else {
      chatTitle = "Ask AI Assistant";
      hintText = "Type your question...";
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: <Widget>[
            Container(
              // Drag Handle
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              // Title
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              child: Text(
                chatTitle, // Use dynamic title
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              // Chat Messages
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildLocalChatMessageBubble(message, context);
                },
              ),
            ),
            Padding(
              // Input Field
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: hintText, // Use dynamic hint text
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7)),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.accentCyan),
                              )
                            : const Icon(Icons.send_rounded,
                                color: AppColors.accentCyan, size: 26),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalChatMessageBubble(
      ChatMessage message, BuildContext context) {
    final bool isUser = message.isUserMessage;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isUser
        ? AppColors.primaryPurple.withOpacity(0.85)
        : AppColors.surfaceLight;
    final textColor = AppColors.textPrimary;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(4))
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18));

    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, height: 1.35, fontSize: 15),
        ),
      ),
    );
  }
}
