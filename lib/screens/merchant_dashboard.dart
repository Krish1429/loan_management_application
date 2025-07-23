import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manage_products_screen.dart';
import 'view_profile_screen.dart';
import 'merchant_loans_screen.dart';
import 'referral_loan_page.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  int _selectedIndex = 0;
  String userName = '';

  final List<Widget> _screens = const [
    MerchantLoansScreen(),
    ManageProductsScreen(),
    ViewProfileScreen(),
  ];

  final List<String> _titles = [
    'Loan Applications',
    'Manage Products',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final response = await Supabase.instance.client
        .from('user_profiles')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    setState(() {
      userName = response?['username'] ?? '';
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _goToReferralForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReferralLoanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_selectedIndex]),
            if (userName.isNotEmpty)
              Text(
                'Welcome, $userName 👋',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loans'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: _goToReferralForm,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Refer a Loan'),
      ),
    );
  }
}




