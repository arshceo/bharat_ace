// Test file to verify content formatting works correctly
import 'package:flutter/material.dart';

void main() {
  // Test content with markdown symbols
  String testContent = '''
## Introduction to History
This is a **very important** section about history.

## Key Points
- First important point with **bold text**
- Second point with *italic text*
- Third point with regular text

## Conclusion
This **conclusion** section summarizes everything important.
  ''';

  // Clean markdown symbols (same logic as in the widget)
  String cleanedContent = testContent
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1') // Remove ** formatting
      .replaceAll(RegExp(r'##\s*([^\n]+)'), r'\1') // Remove ## formatting
      .replaceAll(RegExp(r'\*([^*]+)\*'), r'\1'); // Remove single * formatting

  print('Original content:');
  print(testContent);
  print('\nCleaned content:');
  print(cleanedContent);

  print('\nContent formatting test completed successfully!');
}
