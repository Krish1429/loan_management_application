import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/sign_up_page.dart'; // adjust path if needed
import 'supabase_client.dart';      // your Supabase config
import 'screens/reset_password_screen.dart'; // ✅ You need this screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zqvvqofqnpjhqsmhpvtk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxdnZxb2ZxbnBqaHFzbWhwdnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNjkxMjMsImV4cCI6MjA2ODc0NTEyM30.wHVwD4TjVO40iqLtU4REpOmS1xtFs_fK6aDw0dSqYPE',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // ✅ Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        // 🔁 Navigate to password reset screen
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Management App',
      theme: ThemeData.dark(),
      navigatorKey: _navigatorKey, // ✅ Needed for deep link routing
      debugShowCheckedModeBanner: false,
      home: const SignUpPage(),
    );
  }
}




