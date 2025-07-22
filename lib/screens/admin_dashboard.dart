import 'package:flutter/material.dart';
import '../supabase_client.dart';
import 'login_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> allLoans = [];
  Map<String, String> merchantNames = {}; // Referrer names
  String selectedStatus = 'pending';
  bool isLoading = true;

  final statusOptions = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    fetchLoansByStatus();
  }

  Future<void> fetchLoansByStatus() async {
    setState(() => isLoading = true);

    final response = await supabase
        .from('loans')
        .select()
        .eq('status', selectedStatus)
        .order('created_at', ascending: false);

    final loans = List<Map<String, dynamic>>.from(response);

    final referredIds = loans
        .map((loan) => loan['referred_by'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (referredIds.isNotEmpty) {
      final refData = await supabase
          .from('user_profiles')
          .select('id, username')
          .in_('id', referredIds); // ✅ Replace inFilter with in_()

      merchantNames = {
        for (var m in refData) m['id']: m['username']
      };
    }

    setState(() {
      allLoans = loans;
      isLoading = false;
    });
  }

  Future<void> updateLoanStatus(String loanId, String newStatus) async {
    await supabase.from('loans').update({'status': newStatus}).eq('id', loanId);
    fetchLoansByStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan marked as $newStatus')),
      );
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

  void viewProfile() async {
    final userId = supabase.auth.currentUser?.id;
    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${profile['username']}'),
            Text('Email: ${profile['email']}'),
            Text('Phone: ${profile['phone']}'),
            Text('Age: ${profile['age']}'),
            Text('Role: ${profile['sign_up_as']}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NBFC Admin Dashboard'),
        actions: [
          IconButton(onPressed: viewProfile, icon: const Icon(Icons.person)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
          DropdownButton<String>(
            value: selectedStatus,
            dropdownColor: Colors.grey[900],
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            items: statusOptions
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedStatus = value);
                fetchLoansByStatus();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allLoans.isEmpty
              ? Center(child: Text('No $selectedStatus loans'))
              : ListView.builder(
                  itemCount: allLoans.length,
                  itemBuilder: (context, index) {
                    final loan = allLoans[index];
                    final merchantName = merchantNames[loan['referred_by']] ?? '';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  '${loan['first_name'] ?? ''} ${loan['last_name'] ?? ''}'),
                            ),
                            if (loan['referred_by'] != null)
                              const Chip(
                                label: Text('Referred',
                                    style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.deepPurple,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                            if (merchantName.isNotEmpty)
                              Text('Referred by: $merchantName',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        children: [
                          ListTile(title: Text('Phone: ${loan['phone']}')),
                          ListTile(title: Text('Occupation: ${loan['occupation']}')),
                          ListTile(title: Text('Status: ${loan['status']}')),
                          ButtonBar(
                            alignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    updateLoanStatus(loan['id'], 'approved'),
                                child: const Text('Approve'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    updateLoanStatus(loan['id'], 'rejected'),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
