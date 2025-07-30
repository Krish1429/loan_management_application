import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import 'login_page.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('user_profiles')
        .select('username, email, phone, age')
        .eq('id', user.id)
        .single();

    setState(() {
      profile = data;
      isLoading = false;
    });
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await supabase.auth.updateUser(UserAttributes(email: newEmail));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated')),
      );
      fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating email: $e')),
      );
    }
  }

  Future<void> showEditEmailDialog() async {
    final controller = TextEditingController(text: profile?['email']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateEmail(controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void logout() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Profile',
                style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 20),
            profileTile('Name', profile?['username']),
            profileTile('Email', profile?['email']),
            profileTile('Phone', profile?['phone']),
            profileTile('Age', profile?['age']?.toString()),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: showEditEmailDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileTile(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        tileColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle: Text(value ?? 'N/A', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
