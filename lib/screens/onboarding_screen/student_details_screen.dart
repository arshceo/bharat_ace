// --- student_details_screen.dart (Complete Code) ---
import 'package:bharat_ace/common/routes.dart';
import 'package:bharat_ace/core/providers/student_details_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentDetailsScreen extends ConsumerStatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  ConsumerState<StudentDetailsScreen> createState() =>
      _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends ConsumerState<StudentDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  int _selectedAvatar = 0;
  bool _isCheckingUsername = false; // For async username check
  bool _isSubmitting = false; // **NEW**: For overall submit loading state
  String? _usernameError;
  String? _phoneError;
  String? _nameError;
  String? _boardError; // **NEW**: Error for dropdowns
  String? _schoolError; // **NEW**: Error for dropdowns

  final List<String> _avatars = [
    'assets/avatars/male_avatar.png', // Make sure these assets exist
    'assets/avatars/female_avatar.png',
  ];

  final List<String> _boards = ["CBSE", "ICSE", "PSEB", "State Board", "Other"];
  // Consider fetching schools dynamically or adding an "Other" option
  final List<String> _schools = [
    "Delhi Public School", "St. Xavier's", "Greenfield Academy", "Other"
    // "Your Partnered School 1",
    // "Your Partnered School 2",
  ];

  String? _selectedBoard;
  String? _selectedSchool;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

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
    if (username.isEmpty || username.length < 3) {
      return false; // Basic validation
    }
    final snapshot = await FirebaseFirestore.instance
        .collection("students")
        .where("username", isEqualTo: username)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  bool _validateInputs() {
    // Returns true if valid, false otherwise
    bool isValid = true;
    setState(() {
      _nameError =
          _nameController.text.trim().isEmpty ? "Name is required" : null;
      _usernameError = _usernameController.text.trim().length < 3
          ? "Username > 2 chars"
          : _usernameError; // Keep existing async error
      _phoneError = (_phoneController.text.length != 10 ||
              !RegExp(r'^[0-9]+$').hasMatch(_phoneController.text))
          ? "Phone must be 10 digits"
          : null;
      _boardError = _selectedBoard == null ? "Please select a board" : null;
      _schoolError = _selectedSchool == null ? "Please select a school" : null;

      isValid = _nameError == null &&
          _phoneError == null &&
          _boardError == null &&
          _schoolError == null;
      // Username error checked separately due to async nature
    });
    return isValid;
  }

  // Debounce might be good here in a real app
  Future<void> _validateUsernameOnChanged(String username) async {
    if (username.length < 3) {
      setState(() => _usernameError = "Username > 2 chars");
      return;
    }
    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });
    bool exists = await _checkUsernameExists(username.trim());
    // Check if still mounted and username hasn't changed again
    if (mounted && _usernameController.text.trim() == username.trim()) {
      setState(() {
        _usernameError = exists ? "Username already taken" : null;
      });
    }
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _submitDetails() async {
    // 1. Run basic validations
    bool basicValidationPassed = _validateInputs();

    // Don't proceed if basic validation fails
    if (!basicValidationPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    // 2. Start loading indicator for submit process
    setState(() => _isSubmitting = true);

    // 3. Ensure async username check is complete (wait if it's still running)
    //    and check its result one last time.
    while (_isCheckingUsername) {
      await Future.delayed(const Duration(milliseconds: 100)); // Wait briefly
    }
    // Re-check username validity after potentially waiting
    if (_usernameController.text.trim().length >= 3 && _usernameError == null) {
      await _validateUsernameOnChanged(_usernameController.text.trim());
    }

    // 4. Final check after all validations
    if (_nameError == null &&
        _usernameError == null &&
        _phoneError == null &&
        _boardError == null &&
        _schoolError == null) {
      // --- Update State ONLY ---
      try {
        final studentNotifier = ref.read(studentDetailsProvider.notifier);
        studentNotifier.updateProfileDetails(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          board: _selectedBoard!, // Use ! because validation passed
          school: _selectedSchool!, // Use ! because validation passed
          avatar: _avatars[_selectedAvatar],
        );

        // ---- NO Firestore write here ----

        // Navigate to the next screen
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.onboard_subject_selection);
        }
      } catch (e) {
        print("Error updating profile state: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An error occurred: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false); // Stop loading indicator
        }
      }
    } else {
      // Validation failed after async check or initial check
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct the errors.")),
        );
        setState(() => _isSubmitting = false); // Stop loading indicator
      }
      print(
          "Final Validation failed: NameErr=$_nameError, UserErr=$_usernameError, PhoneErr=$_phoneError, BoardErr=$_boardError, SchoolErr=$_schoolError");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        /* ... AppBar code ... */
        leading: BackButton(color: Colors.white),
        title:
            const Text("Student Setup", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Fields
            _buildHackerInput("Enter Your Name", _nameController, _nameFocus,
                nextFocus: _usernameFocus,
                errorText: _nameError,
                onChanged: (_) => _validateInputs()),
            const SizedBox(height: 15),
            _buildHackerInput(
                "Choose a Username", _usernameController, _usernameFocus,
                nextFocus: _phoneFocus,
                errorText: _usernameError,
                suffixIcon: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.cyanAccent))
                    : (_usernameError == null &&
                            _usernameController.text.length >= 3
                        ? const Icon(Icons.check_circle,
                            color: Colors.greenAccent)
                        : null),
                onChanged:
                    _validateUsernameOnChanged), // Pass function reference
            const SizedBox(height: 15),
            _buildHackerInput(
                "Enter Your Phone Number", _phoneController, _phoneFocus,
                isNumeric: true,
                errorText: _phoneError,
                onChanged: (_) => _validateInputs()),
            const SizedBox(height: 15),

            // Dropdowns
            _buildDropdown("Select Your Board", _selectedBoard, _boards,
                (value) {
              setState(() {
                _selectedBoard = value;
                _boardError = null;
              });
            }),
            if (_boardError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 12.0),
                  child: Text(_boardError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12))), // Show dropdown error
            const SizedBox(height: 15),
            _buildDropdown("Select Your School", _selectedSchool, _schools,
                (value) {
              setState(() {
                _selectedSchool = value;
                _schoolError = null;
              });
            }),
            if (_schoolError != null)
              Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 12.0),
                  child: Text(_schoolError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12))), // Show dropdown error
            const SizedBox(height: 15),

            // Avatar Selection
            const Text("Select your Gender?",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(
              height: 100,
              child: ListView.builder(
                /* ... Avatar ListView ... */
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
                                              spreadRadius: 5)
                                        ]
                                      : []),
                              child: CircleAvatar(
                                  backgroundImage: AssetImage(_avatars[index]),
                                  radius: _selectedAvatar == index ? 50 : 40,
                                  backgroundColor: _selectedAvatar == index
                                      ? Colors.blue
                                      : Colors.grey))));
                },
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 12),
                    shadowColor: Colors.blueAccent,
                    elevation: 10),
                // Disable button during async checks or submission
                onPressed: _isCheckingUsername || _isSubmitting
                    ? null
                    : _submitDetails,
                child: _isSubmitting // Show loading indicator on button
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text("Continue →",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Field Widget
  Widget _buildHackerInput(
      String label, TextEditingController controller, FocusNode currentFocus,
      {FocusNode? nextFocus,
      bool isNumeric = false,
      String? errorText,
      Widget? suffixIcon,
      Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 5), // Add space
      TextField(
        controller: controller,
        focusNode: currentFocus,
        keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
        style:
            const TextStyle(color: Colors.greenAccent, fontFamily: "Courier"),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.grey[900],
          // hintText: "█ █ █ █ █ █ █ █ █ █", // Placeholder text can be distracting
          // hintStyle: const TextStyle(color: Colors.white24),
          errorText: errorText,
          suffixIcon: suffixIcon, // Add suffix icon for validation feedback
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey[700]!)), // Default border
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey[700]!)), // Enabled border
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Colors.cyanAccent)), // Focused border
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error)), // Error border
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1.5)), // Focused Error border
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
    ]);
  }

  // Dropdown Widget
  Widget _buildDropdown(String label, String? currentValue,
      List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: currentValue, // Control the selected value
          dropdownColor: Colors.grey[900], // Match input background
          iconEnabledColor: Colors.cyanAccent,
          style:
              const TextStyle(color: Colors.greenAccent, fontFamily: "Courier"),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[700]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[700]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.cyanAccent)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.error)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error, width: 1.5)),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
                value: option,
                child:
                    Text(option)); // Style applied by DropdownButtonFormField
          }).toList(),
          onChanged: onChanged,
          hint: const Text("Select...",
              style: TextStyle(
                  color: Colors.white38, fontFamily: "Courier")), // Add a hint
          isExpanded: true, // Make dropdown take full width
        ),
      ],
    );
  }
}
