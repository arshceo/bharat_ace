import 'package:bharat_ace/core/services/auth_checker.dart';
import 'package:bharat_ace/screens/authentication/login_screen.dart';
import 'package:bharat_ace/screens/authentication/signup_screen.dart';
import 'package:bharat_ace/screens/home_screen/home_screen2.dart';
import 'package:bharat_ace/screens/main_layout_screen.dart';
import 'package:bharat_ace/screens/onboarding_screen/onboarding_screen.dart';
import 'package:bharat_ace/screens/onboarding_screen/subject_selection_screen.dart';
import 'package:bharat_ace/screens/topic_details_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String authChecker = "/";
  static const String login = "/login";
  static const String signup = "/signup";
  static const String home = "/home";
  static const String main_layout_nav = "/main_nav";
  static const String onboard = "/onboard";
  static const String onboard_subject_selection = "/onboard_subjects";
  static const String topic_details_screen = "/topic_details";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authChecker:
        return MaterialPageRoute(builder: (_) => AuthChecker());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen2());
      case onboard:
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case onboard_subject_selection:
        return MaterialPageRoute(builder: (_) => SubjectSelectionScreen());
      case topic_details_screen:
        return MaterialPageRoute(builder: (_) => TopicDetailScreen());
      case main_layout_nav:
        return MaterialPageRoute(builder: (_) => MainLayout());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("No route defined for ${settings.name}")),
          ),
        );
    }
  }
}
