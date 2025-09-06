import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const JsonTestPage(),
    );
  }
}

class JsonTestPage extends StatefulWidget {
  const JsonTestPage({super.key});

  @override
  State<JsonTestPage> createState() => _JsonTestPageState();
}

class _JsonTestPageState extends State<JsonTestPage> {
  String _jsonResult = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    setState(() {
      _isLoading = true;
      _jsonResult = 'Loading...';
    });

    try {
      // Try different asset paths
      List<String> pathsToTry = [
        'assets/career/career_database.json',
        'assets/career_database.json',
        './assets/career/career_database.json',
        '/assets/career/career_database.json',
      ];

      String? jsonString;
      String usedPath = '';

      for (final path in pathsToTry) {
        try {
          jsonString = await rootBundle.loadString(path);
          usedPath = path;
          print('Successfully loaded JSON from path: $path');
          break;
        } catch (e) {
          print('Failed to load from path: $path, Error: $e');
        }
      }

      if (jsonString == null) {
        setState(() {
          _isLoading = false;
          _jsonResult = 'Failed to load JSON from any path';
        });
        return;
      }

      // Try to parse the JSON
      try {
        final Map<String, dynamic> jsonData = json.decode(jsonString);

        // Check if it contains careers_database key
        if (!jsonData.containsKey('careers_database')) {
          setState(() {
            _isLoading = false;
            _jsonResult =
                'JSON loaded but does not contain "careers_database" key. Available keys: ${jsonData.keys.toList()}';
          });
          return;
        }

        final careers = jsonData['careers_database'] as Map<String, dynamic>;

        setState(() {
          _isLoading = false;
          _jsonResult = 'Successfully loaded and parsed JSON from $usedPath\n'
              'Found ${careers.length} careers in the database\n'
              'Career IDs: ${careers.keys.take(5).join(', ')}...';
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _jsonResult = 'Failed to parse JSON: $e';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _jsonResult = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _jsonResult,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadJsonData,
                child: const Text('Retry Loading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
