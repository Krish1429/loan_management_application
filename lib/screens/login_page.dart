import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../screens/sign_up_page.dart';
import 'loan_borrower_dashboard.dart';
import 'merchant_dashboard.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String selectedRole = 'Loan Borrower';

  final roles = ['Loan Borrower', 'Merchant', 'NBFC Admin'];

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final userData = await supabase
            .from('user_profiles')
            .select('sign_up_as')
            .eq('id', user.id)
            .maybeSingle();

        if (userData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User profile not found.')),
          );
          setState(() => isLoading = false);
          return;
        }

        final role = userData['sign_up_as'];

        if (!mounted) return;

        if (role != selectedRole) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access denied: You are registered as $role')),
          );
        } else {
          if (role == 'Loan Borrower') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoanBorrowerDashboard()),
              (route) => false,
            );
          } else if (role == 'Merchant') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
              (route) => false,
            );
          } else if (role == 'NBFC Admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password.')),
      );
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email,
          redirectTo: 'https://your-app-url.com/reset-password');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Login'),
        automaticallyImplyLeading: false, // 👈 Hides back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Login to your account',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email'),
                validator: (val) => val!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Password'),
                validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
              ),

              // Forgot Password Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                value: selectedRole,
                decoration: _inputDecoration('Select Role'),
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedRole = value!);
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text("Don't have an account? Sign up", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white30),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}



