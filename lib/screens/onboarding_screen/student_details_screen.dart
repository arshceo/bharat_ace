import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentDetailsScreen extends ConsumerStatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  _StudentDetailsScreenState createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends ConsumerState<StudentDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  int _selectedAvatar = 0;
  bool _isCheckingUsername = false;
  String? _usernameError;
  String? _phoneError;
  String? _nameError;

  final List<String> _avatars = [
    'assets/avatars/male_avatar.png',
    'assets/avatars/female_avatar.png',
  ];

  final List<String> _boards = ["CBSE", "ICSE", "PSEB", "State Board"];
  final List<String> _schools = [
    "Delhi Public School",
    "St. Xavier's",
    "Greenfield Academy",
    "Your Partnered School 1",
    "Your Partnered School 2",
  ];

  String? _selectedBoard;
  String? _selectedSchool;

  void _onAvatarSelected(int index) {
    setState(() {
      _selectedAvatar = index;
    });
  }

  void _nextField(FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Future<bool> _checkUsernameExists(String username) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("students")
        .where("username", isEqualTo: username)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  void _validateInputs() {
    setState(() {
      _nameError =
          _nameController.text.trim().isEmpty ? "Name is required" : null;
      _phoneError = (_phoneController.text.length != 10 ||
              !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text))
          ? "Phone must be 10 digits"
          : null;
    });
  }

  Future<void> _validateUsername() async {
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    bool exists = await _checkUsernameExists(_usernameController.text.trim());
    if (exists) {
      setState(() {
        _usernameError = "Username already taken";
      });
    }

    setState(() {
      _isCheckingUsername = false;
    });
  }

  Future<void> _submitDetails() async {
    _validateInputs();
    await _validateUsername();

    if (_usernameError == null &&
        _phoneError == null &&
        _nameError == null &&
        _selectedBoard != null &&
        _selectedSchool != null) {
      final studentProvider = ref.read(studentDetailsProvider.notifier);
      final currentStudent = ref.read(studentDetailsProvider);

      studentProvider.setStudentDetails(
        currentStudent!.copyWith(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          school: _selectedSchool,
          board: _selectedBoard,
          avatar: _avatars[_selectedAvatar],
        ),
      );
      Navigator.pushNamed(context, AppRoutes.onboard_subject_selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
        ),
        title: const Text(
          "Student Setup",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHackerInput(
              "Enter Your Name",
              _nameController,
              _nameFocus,
              nextFocus: _usernameFocus,
              errorText: _nameError,
            ),
            const SizedBox(height: 15),
            _buildHackerInput(
              "Choose a Username",
              _usernameController,
              _usernameFocus,
              nextFocus: _phoneFocus,
              errorText: _usernameError,
              onChanged: (_) => _validateUsername(),
            ),
            const SizedBox(height: 15),
            _buildHackerInput(
              "Enter Your Phone Number",
              _phoneController,
              _phoneFocus,
              isNumeric: true,
              errorText: _phoneError,
              onChanged: (_) => _validateInputs(),
            ),
            const SizedBox(height: 15),
            _buildDropdown("Select Your Board", _boards, (value) {
              setState(() {
                _selectedBoard = value;
              });
            }),
            const SizedBox(height: 15),
            _buildDropdown("Select Your School", _schools, (value) {
              setState(() {
                _selectedSchool = value;
              });
            }),
            const SizedBox(height: 15),
            const Text("Select your Gender?",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _onAvatarSelected(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _selectedAvatar == index
                              ? [
                                  BoxShadow(
                                    color: Colors.deepPurple,
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                  )
                                ]
                              : [],
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(_avatars[index]),
                          radius: _selectedAvatar == index ? 50 : 40,
                          backgroundColor: _selectedAvatar == index
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shadowColor: Colors.blueAccent,
                  elevation: 10,
                ),
                onPressed: _isCheckingUsername ? null : _submitDetails,
                child: const Text(
                  "Continue →",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHackerInput(
      String label, TextEditingController controller, FocusNode currentFocus,
      {FocusNode? nextFocus,
      bool isNumeric = false,
      String? errorText,
      Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
        TextField(
          controller: controller,
          focusNode: currentFocus,
          keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
          style:
              const TextStyle(color: Colors.greenAccent, fontFamily: "Courier"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            hintText: "█ █ █ █ █ █ █ █ █ █",
            hintStyle: const TextStyle(color: Colors.white24),
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: onChanged,
          textInputAction:
              nextFocus != null ? TextInputAction.next : TextInputAction.done,
          onSubmitted: (_) {
            if (nextFocus != null) {
              _nextField(currentFocus, nextFocus);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: null,
      dropdownColor: Colors.black54,
      items: options.map((option) {
        return DropdownMenuItem(
            value: option,
            child: Text(option, style: const TextStyle(color: Colors.white)));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
