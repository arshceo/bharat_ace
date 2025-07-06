import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestSupabaseConnection extends StatefulWidget {
  @override
  _TestSupabaseConnectionState createState() => _TestSupabaseConnectionState();
}

class _TestSupabaseConnectionState extends State<TestSupabaseConnection> {
  String _status = 'Testing connection...';
  List<dynamic> _userCreations = [];
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      final supabase = Supabase.instance.client;

      // Test basic connection
      setState(() {
        _status = 'Connected to Supabase ✅';
      });

      // Test fetching users table
      try {
        final usersResponse =
            await supabase.from('users').select('id, username, name').limit(5);
        setState(() {
          _users = usersResponse;
          _status += '\nFetched ${usersResponse.length} users';
        });
      } catch (e) {
        setState(() {
          _status += '\nError fetching users: $e';
        });
      }

      // Test fetching user_creations table
      try {
        final creationsResponse = await supabase
            .from('user_creations')
            .select('id, title, type, user_id')
            .limit(10);
        setState(() {
          _userCreations = creationsResponse;
          _status += '\nFetched ${creationsResponse.length} user creations';
        });
      } catch (e) {
        setState(() {
          _status += '\nError fetching user_creations: $e';
        });
      }

      // Test fetching video creations specifically
      try {
        final videoResponse = await supabase
            .from('user_creations')
            .select('id, title, type, user_id')
            .eq('type', 'video')
            .limit(10);
        setState(() {
          _status += '\nFound ${videoResponse.length} video creations';
        });
      } catch (e) {
        setState(() {
          _status += '\nError fetching videos: $e';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supabase Test')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            if (_users.isNotEmpty) ...[
              Text('Users:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_users.map(
                  (user) => Text('- ${user['username']} (${user['name']})'))),
              SizedBox(height: 20),
            ],
            if (_userCreations.isNotEmpty) ...[
              Text('User Creations:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_userCreations.map((creation) =>
                  Text('- ${creation['title']} (${creation['type']})'))),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testConnection,
              child: Text('Refresh Test'),
            ),
          ],
        ),
      ),
    );
  }
}
