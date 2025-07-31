import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_client.dart';
import '../screens/login_page.dart';
import '../screens/merchant_loans_page.dart';
import '../screens/merchant_product_page.dart';
import '../screens/merchant_profile_page.dart';
import '../screens/referral_loan_page.dart'; // ✅ Fixed import

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  int totalLoans = 0;
  int pendingLoans = 0;
  int approvedLoans = 0;
  Map<String, int> loanPurposeCounts = {};
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchLoanStats();
    userEmail = supabase.auth.currentUser?.email;
  }

  Future<void> fetchLoanStats() async {
    final response = await supabase.from('merchant_loans').select();

    setState(() {
      totalLoans = response.length;
      pendingLoans = response.where((l) => l['status'] == 'pending').length;
      approvedLoans = response.where((l) => l['status'] == 'approved').length;

      loanPurposeCounts = {};
      for (var loan in response) {
        final purpose = loan['loan_purpose'] ?? 'Unknown';
        loanPurposeCounts[purpose] = (loanPurposeCounts[purpose] ?? 0) + 1;
      }
    });
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

  Widget buildStatCard(String title, int count, Color color, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Text("$count", style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> getChartSections() {
    final total = loanPurposeCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.blue, Colors.green, Colors.yellow, Colors.red, Colors.cyan, Colors.purple];
    final purposes = loanPurposeCounts.keys.toList();

    return List.generate(purposes.length, (i) {
      final value = loanPurposeCounts[purposes[i]]!;
      final percentage = (value / total) * 100;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value.toDouble(),
        title: '${purposes[i]} (${percentage.toStringAsFixed(1)}%)',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Merchant Dashboard"),
        actions: [
          PopupMenuButton<String>(
            color: Colors.grey[800],
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'logout') logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'email',
                enabled: false,
                child: Text(userEmail ?? 'No email', style: const TextStyle(color: Colors.white70)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('Merchant Dashboard', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.white),
              title: const Text('Loans', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantLoansPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.white),
              title: const Text('Products', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantProductPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.recommend, color: Colors.white),
              title: const Text('Refer a Loan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralLoanPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantProfilePage()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Overview", style: TextStyle(color: Colors.white, fontSize: 22)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                buildStatCard("Total Loans", totalLoans, Colors.blue, Icons.folder, () {}),
                const SizedBox(width: 12),
                buildStatCard("Pending", pendingLoans, Colors.amber, Icons.access_time, () {}),
                const SizedBox(width: 12),
                buildStatCard("Approved", approvedLoans, Colors.green, Icons.check_circle, () {}),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Loan Purpose Distribution", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: getChartSections(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




