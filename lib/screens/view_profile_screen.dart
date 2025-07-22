import 'package:flutter/material.dart';
import '../supabase_client.dart';
import 'login_page.dart'; // Make sure you have this page created

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  Future<Map<String, dynamic>?> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    return profile;
  }

  void logout(BuildContext context) async {
    await supabase.auth.signOut();

    // Clear navigation stack and go to login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text('No profile found'));

        final data = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${data['username']}', style: const TextStyle(fontSize: 18)),
              Text('Email: ${data['email']}'),
              Text('Phone: ${data['phone']}'),
              Text('Role: ${data['sign_up_as']}'),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

