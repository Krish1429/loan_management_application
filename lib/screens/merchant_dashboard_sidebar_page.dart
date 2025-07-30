import 'package:flutter/material.dart';
import '../screens/merchant_loans_screen.dart';
import '../screens/manage_products_screen.dart';
import 'merchant_profile_page.dart';

class MerchantDashboardSidebar extends StatefulWidget {
  const MerchantDashboardSidebar({super.key});

  @override
  State<MerchantDashboardSidebar> createState() => _MerchantDashboardSidebarState();
}

class _MerchantDashboardSidebarState extends State<MerchantDashboardSidebar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MerchantLoansScreen(),         // Your referred loans page
    ManageProductsScreen(),      // Product management page
    MerchantProfilePage(),       // Profile page
  ];

  final List<String> _titles = ['Loan Applications', 'My Products', 'My Profile'];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A171E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Merchant Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.white),
              title: const Text('Loans', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.white),
              title: const Text('Products', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1A171E),
      body: _pages[_selectedIndex],
    );
  }
}
