import 'package:bharat_ace/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';

<<<<<<< Updated upstream
void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: MyApp()));
=======
void main() {
  //   WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: MyApp())); // ✅ Wrap with ProviderScope
>>>>>>> Stashed changes
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}
