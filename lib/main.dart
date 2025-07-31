import 'package:flutter/material.dart';
import 'package:loan_management_application/screens/merchant_dashboard_screen.dart';
import 'package:loan_management_application/screens/merchant_loans_page.dart'; // ✅ NEW screen
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/admin_dashboard.dart';
import 'screens/login_page.dart';
import 'supabase_client.dart';

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
  bool _loading = true;
  Widget _redirectWidget = const LoginPage();

  @override
  void initState() {
    super.initState();
    checkLoginAndRole();
  }

  Future<void> checkLoginAndRole() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final userId = session.user.id;

      final profile = await supabase
          .from('user_profiles')
          .select('sign_up_as')
          .eq('id', userId)
          .maybeSingle();

      final role = profile?['sign_up_as'];

      Widget target;
      if (role == 'merchant') {
        target = const MerchantDashboardScreen();
      } else if (role == 'loan_borrower') {
        target = const MerchantLoansPage(); // ✅ Updated screen for borrower
      } else if (role == 'nbfc_admin') {
        target = const AdminDashboardScreen();
      } else {
        target = const LoginPage(); // fallback
      }

      setState(() {
        _redirectWidget = target;
        _loading = false;
      });
    } else {
      setState(() {
        _redirectWidget = const LoginPage();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: _loading
          ? const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            )
          : _redirectWidget,
    );
  }
}





