import 'package:flutter/material.dart';
import 'manage_products_screen.dart';
import 'view_profile_screen.dart';
import 'merchant_loans_screen.dart';
import 'referral_loan_page.dart'; // ✅ import this

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  int _selectedIndex = 0;

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
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loans'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToReferralForm,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Refer a Loan'),
      ),
    );
  }
}


