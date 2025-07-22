import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import 'apply_loan_page.dart';
import 'login_page.dart';
import 'loan_history_screen.dart'; // ✅ Import LoanHistoryScreen

class LoanBorrowerDashboardScreen extends StatefulWidget {
  const LoanBorrowerDashboardScreen({super.key});

  @override
  State<LoanBorrowerDashboardScreen> createState() => _LoanBorrowerDashboardScreenState();
}

class _LoanBorrowerDashboardScreenState extends State<LoanBorrowerDashboardScreen> {
  List<Map<String, dynamic>> myLoans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyLoans();
  }

  Future<void> fetchMyLoans() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final response = await supabase
          .from('loans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        myLoans = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    }
  }

  void logout() async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? 'Borrower';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userEmail'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApplyLoanPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Apply for New Loan'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View Loan History'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            const Text('My Loan Applications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: myLoans.isEmpty
                        ? const Center(child: Text('No loans found'))
                        : ListView.builder(
                            itemCount: myLoans.length,
                            itemBuilder: (context, index) {
                              final loan = myLoans[index];
                              return Card(
                                child: ListTile(
                                  title: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                                  subtitle: Text('Status: ${loan['status']}'),
                                  trailing: Text(loan['created_at'].toString().split('T').first),
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


