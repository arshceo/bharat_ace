import 'package:bharat_ace/screens/home_screen/home_screen.dart';
import 'package:flutter/material.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  _StudentDetailsScreenState createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  int _selectedAvatar = 0;

  final List<String> _avatars = [
    'assets/avatars/male_avatar.png',
    'assets/avatars/female_avatar.png',
    // 'assets/avatars/avatar3.png',
    // 'assets/avatars/avatar4.png',
    // 'assets/avatars/avatar5.png',
  ];

  void _onAvatarSelected(int index) {
    setState(() {
      _selectedAvatar = index;
    });
  }

  void _submitDetails() {
    // Process student details (save to database or move to next step)
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Student Details"),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter Your Name",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            TextField(
                controller: _nameController,
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            const Text("Choose a Username",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            TextField(
                controller: _usernameController,
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            const Text("Select Your Avatar",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onAvatarSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundImage: AssetImage(_avatars[index]),
                        radius: _selectedAvatar == index ? 40 : 30,
                        backgroundColor: _selectedAvatar == index
                            ? Colors.yellow
                            : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitDetails,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
