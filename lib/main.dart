import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/sign_up_page.dart'; // adjust if folder is different
import 'supabase_client.dart';    // your Supabase config

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zqvvqofqnpjhqsmhpvtk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxdnZxb2ZxbnBqaHFzbWhwdnRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxNjkxMjMsImV4cCI6MjA2ODc0NTEyM30.wHVwD4TjVO40iqLtU4REpOmS1xtFs_fK6aDw0dSqYPE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Management App',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SignUpPage(), // Show signup page first
    );
  }
}


