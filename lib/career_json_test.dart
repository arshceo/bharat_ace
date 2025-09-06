import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career JSON Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const JsonLoaderScreen(),
    );
  }
}

class JsonLoaderScreen extends StatefulWidget {
  const JsonLoaderScreen({Key? key}) : super(key: key);

  @override
  State<JsonLoaderScreen> createState() => _JsonLoaderScreenState();
}

class _JsonLoaderScreenState extends State<JsonLoaderScreen> {
  String _status = 'Loading...';
  bool _isLoading = true;
  List<String> _careerNames = [];

  @override
  void initState() {
    super.initState();
    _loadJsonFile();
  }

  Future<void> _loadJsonFile() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Attempting to load JSON file...';
      });

      // Check what assets we can access
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Log all available assets
      final assets = manifestMap.keys.toList();
      print('Available assets: $assets');

      String jsonData;
      try {
        // First attempt
        jsonData =
            await rootBundle.loadString('assets/career/career_database.json');
        setState(() {
          _status =
              'Successfully loaded JSON from primary path!\nSize: ${jsonData.length} characters';
        });
      } catch (e1) {
        print('Primary path failed: $e1');
        try {
          // Second attempt
          jsonData = await rootBundle.loadString('assets/career_database.json');
          setState(() {
            _status =
                'Successfully loaded JSON from alternate path!\nSize: ${jsonData.length} characters';
          });
        } catch (e2) {
          print('Alternate path failed: $e2');
          setState(() {
            _status = 'Failed to load JSON file.\nError 1: $e1\nError 2: $e2';
            _isLoading = false;
          });
          return;
        }
      }

      // Try parsing the JSON
      try {
        final Map<String, dynamic> parsedData = json.decode(jsonData);
        if (parsedData.containsKey('careers_database')) {
          final careers =
              parsedData['careers_database'] as Map<String, dynamic>;
          final careerNames = careers.keys.map((key) {
            final career = careers[key];
            return career['title'] as String? ?? key;
          }).toList();

          setState(() {
            _careerNames = careerNames;
            _status =
                'Successfully loaded and parsed ${careerNames.length} careers!';
            _isLoading = false;
          });
        } else {
          setState(() {
            _status =
                'JSON loaded but missing "careers_database" key.\nKeys found: ${parsedData.keys.join(", ")}';
            _isLoading = false;
          });
        }
      } catch (parseError) {
        setState(() {
          _status =
              'Failed to parse JSON: $parseError\nFirst 100 characters: ${jsonData.substring(0, jsonData.length > 100 ? 100 : jsonData.length)}...';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career JSON Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_careerNames.isNotEmpty) ...[
                const Text(
                  'Careers found:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _careerNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.work),
                        title: Text(_careerNames[index]),
                      );
                    },
                  ),
                )
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadJsonFile,
                child: const Text('Retry Loading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
