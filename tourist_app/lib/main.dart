import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Make sure this is imported
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // Import the new file
import 'loginScreen.dart'; // Make sure this is named correctly (login_screen.dart)
import 'mainScreen.dart'; // Make sure this is named correctly (main_screen.dart)

void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase using the auto-generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tourist Safety App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking login status
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data?.getString('jwt_token');
          if (token != null) {
            return MainScreen(token: token);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
