import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sip_drips/features/auth/screens/login_screen.dart';
import '../../core/main_navigation_screen.dart';


/// A widget that acts as a gatekeeper for the application's authentication state.
///
/// This widget listens for changes in the user's authentication status and
/// routes them to the appropriate screen. It is the single source of truth
/// for high-level navigation.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listens to real-time authentication state changes from Firebase.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If a user is logged in, snapshot.hasData will be true.
          if (snapshot.hasData) {
            // If we have a user, we must verify their status (e.g., not banned).
            return _UserStatusChecker(user: snapshot.data!);
          }
          // If no user is logged in, show the login screen.
          else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

/// A helper widget that checks the Firestore data for a logged-in user.
///
/// This widget is shown after a user is authenticated but before the main
/// app screen is displayed. It fetches the user's document to check for
/// flags like 'isBanned' and syncs their email address.
class _UserStatusChecker extends StatelessWidget {
  final User user;
  const _UserStatusChecker({required this.user});

  /// Syncs the email in Firestore with the email in Firebase Auth.
  /// This is crucial for after a user verifies a new email address.
  Future<void> _syncFirestoreEmail(DocumentSnapshot userDoc, String authEmail) async {
    final firestoreEmail = (userDoc.data() as Map<String, dynamic>)['email'];
    if (firestoreEmail != authEmail) {
      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({'email': authEmail});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Fetches the user's document from the 'users' collection.
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        // While waiting for the document, show a loading indicator.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If an error occurs or the document doesn't exist, sign out the user.
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const Center(child: CircularProgressIndicator());
        }

        final userDoc = snapshot.data!;
        final userData = userDoc.data() as Map<String, dynamic>;
        final isBanned = userData['isBanned'] ?? false;

        // If the user is banned, show a SnackBar and sign them out.
        if (isBanned) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account is banned. Please contact SipDrips.',
                  textAlign: TextAlign.center,
                ),
                backgroundColor: Colors.red,
              ),
            );
            FirebaseAuth.instance.signOut();
          });
          return const Center(child: CircularProgressIndicator());
        }

        // --- SYNCHRONIZATION LOGIC ---
        // After confirming the user is not banned, sync their email.
        if (user.email != null) {
          _syncFirestoreEmail(userDoc, user.email!);
        }

        // If the user is not banned, grant access to the main app.
        return const MainNavigationScreen();
      },
    );
  }
}

