import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sip_drips/features/auth/screens/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Attempt to load the .env file.
    await dotenv.load(fileName: ".env");

    // 2. --- DIAGNOSTIC PRINT ---
    // This will show us exactly what the app is reading from the .env file.
    print('---.env file content check---');
    print('API_KEY: ${dotenv.env['API_KEY']}');
    print('APP_ID: ${dotenv.env['APP_ID']}');
    print('MESSAGING_SENDER_ID: ${dotenv.env['MESSAGING_SENDER_ID']}');
    print('PROJECT_ID: ${dotenv.env['PROJECT_ID']}');
    print('AUTH_DOMAIN: ${dotenv.env['AUTH_DOMAIN']}');
    print('STORAGE_BUCKET: ${dotenv.env['STORAGE_BUCKET']}');
    print('---------------------------');

    // 3. Check if any key is null before proceeding.
    if (dotenv.env['API_KEY'] == null || dotenv.env['APP_ID'] == null) {
      print('!!!!!!!!!! ERROR: CRITICAL API KEYS ARE NULL !!!!!!!!!!');
      print('Please check your .env file for formatting errors (e.g., extra spaces, missing quotes).');
      return; // Stop execution if keys are null.
    }

    // 4. Attempt to initialize Firebase.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

  } catch (e) {
    // 5. If any part of the setup fails, print the specific error.
    print('!!!!!!!!!! FIREBASE INITIALIZATION FAILED !!!!!!!!!!');
    print(e.toString());
    print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    return; // Stop execution on error.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SipDrips',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF7F0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFA726)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

