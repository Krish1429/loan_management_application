import 'package:flutter/material.dart';
import 'package:loan_management_application/screens/notifications_screen.dart';
import 'manage_products_screen.dart';
import 'view_profile_screen.dart';
import 'merchant_loans_screen.dart';
import 'referral_loan_page.dart';
import '../supabase_client.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  int _selectedIndex = 0;
  String merchantName = '';
  int unreadCount = 0;
  String? lastSeenNotificationId;

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
    fetchMerchantName();
    fetchUnreadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUnreadNotifications(); // refresh on rebuild
  }

  Future<void> fetchMerchantName() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('user_profiles')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    if (response != null && mounted) {
      setState(() {
        merchantName = response['username'] ?? '';
      });
    }
  }

  Future<void> fetchUnreadNotifications() async {
    final userId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response.isNotEmpty) {
      setState(() {
        unreadCount = response.length;
      });

      // Only show latest notification once
      if (lastSeenNotificationId != response.first['id']) {
        lastSeenNotificationId = response.first['id'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.first['message']),
              backgroundColor: Colors.deepPurple,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      setState(() {
        unreadCount = 0;
      });
    }
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

  void _goToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    setState(() {
      unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_selectedIndex]),
            if (merchantName.isNotEmpty)
              Text('Welcome, $merchantName 👋',
                  style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _goToNotifications,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Loans'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              onPressed: _goToReferralForm,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Refer a Loan'),
            )
          : null,
    );
  }
}






