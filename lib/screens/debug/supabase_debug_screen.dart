// lib/screens/debug/supabase_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/utils/supabase_test.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bharat_ace/core/services/supabase_service.dart';

class SupabaseDebugScreen extends ConsumerStatefulWidget {
  const SupabaseDebugScreen({super.key});

  @override
  ConsumerState<SupabaseDebugScreen> createState() =>
      _SupabaseDebugScreenState();
}

class _SupabaseDebugScreenState extends ConsumerState<SupabaseDebugScreen> {
  bool _isRunningTests = false;
  bool _isUploading = false;
  String _testResults = '';

  void _addToResults(String message) {
    setState(() {
      _testResults += '$message\n';
    });
  }

  Future<void> _runSupabaseTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = '';
    });

    // Redirect print statements to our results
    void testPrint(String message) {
      _addToResults(message);
    }

    try {
      testPrint('🧪 Starting Supabase tests...');
      testPrint('=' * 50);

      // Test connection
      try {
        SupabaseTest.testConnection();
        testPrint('✅ Connection test completed');
      } catch (e) {
        testPrint('❌ Connection test failed: $e');
      }

      testPrint('-' * 30);

      // Test authentication
      try {
        await SupabaseTest.testAuthentication();
        testPrint('✅ Authentication test completed');
      } catch (e) {
        testPrint('❌ Authentication test failed: $e');
      }

      testPrint('-' * 30);

      // Test storage
      try {
        await SupabaseTest.testStorageUpload();
        testPrint('✅ Storage test completed');
      } catch (e) {
        testPrint('❌ Storage test failed: $e');
      }

      testPrint('🏁 All tests completed!');
    } catch (e) {
      testPrint('❌ Overall test failed: $e');
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testImageUpload() async {
    final student = ref.read(studentDetailsProvider).valueOrNull;
    if (student == null) {
      _addToResults('❌ No student data available. Please log in first.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        _addToResults('❌ No image selected');
        return;
      }

      _addToResults('📤 Starting image upload test...');
      _addToResults('👤 User ID: ${student.id}');
      _addToResults('📱 File path: ${image.path}');

      final file = File(image.path);
      final fileSize = await file.length();
      _addToResults('📊 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

      // Test upload
      try {
        final downloadUrl =
            await SupabaseService.uploadUserContent(file, student.id, 'image');

        _addToResults('✅ Upload successful!');
        _addToResults('🔗 Download URL: $downloadUrl');
      } catch (uploadError) {
        _addToResults('❌ Upload failed: $uploadError');

        // Try to provide more context
        if (uploadError.toString().contains('403')) {
          _addToResults('🔐 This is likely a permissions issue');
          _addToResults('💡 Try running the authentication test first');
        }
      }
    } catch (e) {
      _addToResults('❌ Image upload test failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(studentDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    student.when(
                      data: (user) => user != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${user.id}'),
                                Text('Name: ${user.name}'),
                                Text('Email: ${user.email}'),
                              ],
                            )
                          : const Text('No user data'),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunningTests ? null : _runSupabaseTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isRunningTests
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Testing...'),
                            ],
                          )
                        : const Text('Run All Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _testImageUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Uploading...'),
                            ],
                          )
                        : const Text('Test Upload'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResults = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Results'),
            ),

            const SizedBox(height: 16),

            // Results
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'No test results yet. Run a test to see output here.'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
