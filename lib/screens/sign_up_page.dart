import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  String selectedRole = 'Loan Borrower'; // default

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final roles = ['Loan Borrower', 'Merchant', 'NBFC Admin'];

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final age = int.tryParse(ageController.text.trim()) ?? 0;

    try {
      final response = await supabase.auth.signUp(email: email, password: password);

      final userId = response.user?.id;

      if (userId != null) {
        await supabase.from('user_profiles').insert({
          'id': userId,
          'username': name,
          'email': email,
          'phone': phone,
          'sign_up_as': selectedRole,
          'age': age,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please login.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Create a new account', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Name'),
                validator: (val) => val!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Password'),
                obscureText: true,
                validator: (val) => val!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: ageController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Age'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Enter age' : null,
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
                onPressed: isLoading ? null : signUp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text("Already have an account? Log in"),
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

