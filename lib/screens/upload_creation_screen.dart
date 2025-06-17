import 'dart:io';
import 'package:bharat_ace/core/services/creation_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:video_player/video_player.dart';
import 'package:bharat_ace/core/models/content_type_enum.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:bharat_ace/screens/profile_screen.dart'
    show userCreationsProvider; // For invalidating

// Providers for UI state during upload
final isUploadingProvider = StateProvider<bool>((ref) => false);
final uploadProgressProvider = StateProvider<double>((ref) => 0.0);

class UploadCreationScreen extends ConsumerStatefulWidget {
  final XFile pickedFile;
  final ContentType type;

  const UploadCreationScreen({
    super.key,
    required this.pickedFile,
    required this.type,
    required File file,
  });

  @override
  ConsumerState<UploadCreationScreen> createState() =>
      _UploadCreationScreenState();
}

class _UploadCreationScreenState extends ConsumerState<UploadCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  VideoPlayerController? _videoController;
  late File _fileToShow;

  @override
  void initState() {
    super.initState();
    _fileToShow = File(widget.pickedFile.path);
    if (widget.type == ContentType.video) {
      _videoController = VideoPlayerController.file(_fileToShow)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    final student = ref.read(studentDetailsProvider).valueOrNull;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("User not found. Please log in again.")));
      return;
    }

    ref.read(isUploadingProvider.notifier).state = true;
    ref.read(uploadProgressProvider.notifier).state = 0.0;

    final success =
        await ref.read(creationServiceProvider).createAndUploadContent(
              file: _fileToShow,
              title: _titleController.text.trim(),
              userId: student.id,
              type: widget.type,
              onProgress: (progress) {
                ref.read(uploadProgressProvider.notifier).state = progress;
              },
            );

    if (mounted) {
      ref.read(isUploadingProvider.notifier).state = false;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploaded successfully!")));
        ref.invalidate(
            userCreationsProvider); // Refresh the creations on profile
        Navigator.pop(context); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Upload failed. Please try again.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(isUploadingProvider);
    final progress = ref.watch(uploadProgressProvider);

    // Define colors or import from your theme
    const Color darkBg = Color(0xFF12121F);
    const Color surfaceLight = Color(0xFF2A2A3A);
    const Color textPrimary = Color(0xFFEAEAEA);
    const Color textSecondary = Color(0xFFAAAAAA);
    const Color accentCyan = Color(0xFF29B6F6);
    const Color accentPink = Color(0xFFEC407A);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text("New ${widget.type.name}"),
        backgroundColor: surfaceLight,
        actions: [
          if (!isUploading)
            TextButton(
              onPressed: _handleUpload,
              child: const Text("POST",
                  style: TextStyle(
                      color: accentCyan, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Preview
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.type == ContentType.image
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_fileToShow, fit: BoxFit.contain))
                        : (_videoController?.value.isInitialized ?? false)
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_videoController!),
                                    IconButton(
                                      iconSize: 60,
                                      icon: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_circle_outline
                                            : Icons.play_circle_outline,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () => setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      }),
                                    )
                                  ],
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                    color: accentPink)),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: "Write a caption...",
                      hintStyle: const TextStyle(color: textSecondary),
                      filled: false, // Or true with fillColor: surfaceLight
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: surfaceLight)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: accentCyan)),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? "Caption cannot be empty."
                            : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: Container(
                color: darkBg.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          value: progress,
                          color: accentPink,
                          backgroundColor: surfaceLight),
                      const SizedBox(height: 16),
                      Text("Uploading ${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              color: textPrimary, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
