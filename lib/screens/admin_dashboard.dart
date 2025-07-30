import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_client.dart';
import '../screens/all_loan_page.dart';
import '../screens/pending_loan_page.dart';
import '../screens/accepted_loan_page.dart';

import '../screens/login_page.dart'; // for logout

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalLoans = 0;
  int pendingLoans = 0;
  int acceptedLoans = 0;
  Map<String, int> loanPurposeCounts = {};
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchLoanStats();
    userEmail = supabase.auth.currentUser?.email;
  }

  Future<void> fetchLoanStats() async {
    final loans = await supabase.from('loans').select();

    setState(() {
      totalLoans = loans.length;
      pendingLoans = loans.where((l) => l['status'] == 'pending').length;
      acceptedLoans = loans.where((l) => l['status'] == 'approved').length;

      loanPurposeCounts = {};
      for (var loan in loans) {
        final purpose = loan['loan_purpose'] ?? 'Unknown';
        loanPurposeCounts[purpose] = (loanPurposeCounts[purpose] ?? 0) + 1;
      }
    });
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
                Text("$count applications", style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> getChartSections() {
    final total = loanPurposeCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      Colors.blue, Colors.green, Colors.yellow, Colors.red,
      Colors.cyan, Colors.purple
    ];
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("NBFC Admin Dashboard"),
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
              child: Text('NBFC Admin Dashboard', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {}, // current page
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.white),
              title: const Text('Manage Loans', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLoansPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.white),
              title: const Text('Accepted Loans', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AcceptedLoansPage()));
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
              child: Text("Welcome Dashboard", style: TextStyle(color: Colors.white, fontSize: 22)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                buildStatCard(
                  "Total Loan Applications",
                  totalLoans,
                  Colors.blue,
                  Icons.folder,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllLoansPage())),
                ),
                const SizedBox(width: 12),
                buildStatCard(
                  "Pending Loans",
                  pendingLoans,
                  Colors.amber,
                  Icons.access_time,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingLoansPage())),
                ),
                const SizedBox(width: 12),
                buildStatCard(
                  "Accepted Loans",
                  acceptedLoans,
                  Colors.green,
                  Icons.check_circle,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcceptedLoansPage())),
                ),
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
                        child: Text(
                          "Loan Purpose Distribution",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
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












