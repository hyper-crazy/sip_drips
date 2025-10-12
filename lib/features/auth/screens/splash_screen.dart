import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/auth/screens/auth_gate.dart';

/// The initial screens displayed when the application is launched.
///
/// Shows a branded loading view for a short duration before transitioning
/// to the main application logic, now handled by [AuthGate].
///
/// Note: While the app's entry point in main.dart is now [AuthGate], this
/// splash screens could be reintroduced for tasks like pre-loading assets
/// or initial configuration checks.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Navigates to the AuthGate after a 3-second delay.
    Timer(const Duration(seconds: 3), () {
      // A 'mounted' check ensures the widget is still in the tree before navigating.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Uses the app's primary background color for a consistent theme.
      backgroundColor: Color(0xFFFFF7F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SipDrips',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
            ),
          ],
        ),
      ),
    );
  }
}

