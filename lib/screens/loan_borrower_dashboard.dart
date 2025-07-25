import 'package:flutter/material.dart';
import 'package:loan_management_application/screens/notifications_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../screens/apply_loan_page.dart';
import '../screens/loan_history_screen.dart';
import '../screens/login_page.dart';
import '../screens/purchase_history_screen.dart';

class LoanBorrowerDashboard extends StatefulWidget {
  const LoanBorrowerDashboard({super.key});

  @override
  State<LoanBorrowerDashboard> createState() => _LoanBorrowerDashboardState();
}

class _LoanBorrowerDashboardState extends State<LoanBorrowerDashboard> {
  String userName = '';
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchProducts();
  }

  Future<void> fetchUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('user_profiles')
        .select('username')
        .eq('id', userId)
        .single();

    setState(() {
      userName = response['username'] ?? '';
    });
  }

  Future<void> fetchProducts() async {
    final data = await supabase.from('products').select();
    setState(() {
      products = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> buyProduct(Map<String, dynamic> product) async {
    final userId = supabase.auth.currentUser?.id;
    try {
      await supabase.from('purchases').insert({
        'user_id': userId,
        'product_id': product['product_id'],
      });

      await supabase.from('notifications').insert({
        'user_id': userId,
        'message': 'You purchased ${product['name']} successfully.',
        'type': 'product',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product purchased successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
      }
    }
  }

  void goToApplyLoan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApplyLoanPage()),
    );
  }

  void goToLoanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoanHistoryScreen()),
    );
  }

  void goToPurchaseHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
    );
  }

  void logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void openProfileSheet() async {
    final userId = supabase.auth.currentUser?.id;

    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    final usernameController =
        TextEditingController(text: profile['username'] ?? '');
    final emailController =
        TextEditingController(text: supabase.auth.currentUser?.email ?? '');
    final phoneController =
        TextEditingController(text: profile['phone'] ?? '');
    final ageController =
        TextEditingController(text: profile['age']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A171E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding:
            const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'My Profile',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromHeight(45),
                ),
                onPressed: () async {
                  final updatedEmail = emailController.text.trim();
                  final updatedUsername = usernameController.text.trim();

                  // Update Auth Email
                  if (updatedEmail != supabase.auth.currentUser?.email) {
                    await supabase.auth.updateUser(
                      UserAttributes(email: updatedEmail),
                    );
                  }

                  // Update profile data
                  await supabase.from('user_profiles').update({
                    'username': updatedUsername,
                    'phone': phoneController.text.trim(),
                    'age': int.tryParse(ageController.text.trim()) ?? 0,
                  }).eq('id', userId);

                  if (mounted) {
                    Navigator.pop(context);
                    fetchUserProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(45),
                ),
                onPressed: logout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        title: const Text('Loan Borrower Dashboard'),
        backgroundColor: const Color(0xFF1A171E),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: openProfileSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: goToApplyLoan,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Apply for a New Loan'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: goToLoanHistory,
              icon: const Icon(Icons.history),
              label: const Text('View My Loan History'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: goToPurchaseHistory,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('View Purchase History'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Available Products:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text('No products available at the moment.', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.shopping_cart,
                                color: Colors.deepPurple),
                            title: Text(
                              product['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              product['description'] ?? 'No description',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${product['price'] ?? '0'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    buyProduct(product);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: const Size(50, 30),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  child: const Text('Buy'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}










