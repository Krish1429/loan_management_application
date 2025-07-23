import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../screens/apply_loan_page.dart';
import '../screens/loan_history_screen.dart';
import '../screens/view_profile_screen.dart';
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
    debugPrint('Fetched products: $data');

    setState(() {
      products = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> buyProduct(String productId) async {
    final userId = supabase.auth.currentUser?.id;
    try {
      await supabase.from('purchases').insert({
        'user_id': userId,
        'product_id': productId,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product purchased successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error buying product: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed')),
        );
      }
    }
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

  void goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewProfileScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Borrower Dashboard'),
        actions: [
          IconButton(onPressed: goToProfile, icon: const Icon(Icons.person)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products available at the moment.'))
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.shopping_cart, color: Colors.deepPurple),
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
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${product['price'] ?? '0'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    buyProduct(product['product_id']);
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







