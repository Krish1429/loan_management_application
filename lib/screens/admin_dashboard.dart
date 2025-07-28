import 'package:flutter/material.dart';
import 'package:loan_management_application/screens/notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../supabase_client.dart';
import 'login_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allLoans = [];
  List<Map<String, dynamic>> directLoans = [];
  List<Map<String, dynamic>> referredLoans = [];
  Map<String, String> merchantNames = {};
  String selectedStatus = 'pending';
  bool isLoading = true;

  final statusOptions = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    setState(() => isLoading = true);

    final response = await supabase
        .from('loans')
        .select()
        .eq('status', selectedStatus)
        .order('created_at', ascending: false);

    final loans = List<Map<String, dynamic>>.from(response);

    final referredIds = loans
        .map((loan) => loan['referred_by']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    if (referredIds.isNotEmpty) {
      final refData = await supabase
          .from('user_profiles')
          .select('id, username')
          .in_('id', referredIds);

      merchantNames = {
        for (var m in refData)
          if (m['id'] != null && m['username'] != null)
            m['id'].toString(): m['username']
      };
    }

    setState(() {
      allLoans = loans;
      directLoans =
          loans.where((loan) => loan['referred_by'] == null).toList();
      referredLoans =
          loans.where((loan) => loan['referred_by'] != null).toList();
      isLoading = false;
    });
  }

  Future<void> updateLoanStatus(String loanId, String newStatus) async {
  // Step 1: Update loan status
  await supabase.from('loans').update({'status': newStatus}).eq('id', loanId);

  // Step 2: Fetch loan details
  final loan = await supabase.from('loans').select().eq('id', loanId).single();

  // Step 3: Notify the borrower
  await supabase.from('notifications').insert({
    'user_id': loan['user_id'],
    'message': 'Your loan has been $newStatus.',
    'type': 'loan',
    'is_read': false,
    'created_at': DateTime.now().toIso8601String(),
  });

  // ✅ Step 4: Notify merchant if referred
  if (loan['referred_by'] != null && newStatus == 'approved') {
    await supabase.from('notifications').insert({
      'user_id': loan['referred_by'],
      'message': 'Loan Approved - Upload documents now.',
      'type': 'loan',
      'loan_id': loan['id'], // must include this
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Step 5: Refresh UI
  fetchLoans();

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

    final usernameController = TextEditingController(text: profile['username']);
    final emailController = TextEditingController(text: profile['email'] ?? '');
    final phoneController = TextEditingController(text: profile['phone'] ?? '');
    final ageController =
        TextEditingController(text: profile['age']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('user_profiles').update({
                'username': usernameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'age': int.tryParse(ageController.text.trim()) ?? 0,
              }).eq('id', userId);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void showLoanDetails(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A171E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Full Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Name: ${loan['first_name']} ${loan['last_name']}', style: const TextStyle(color: Colors.white)),
            Text('Phone: ${loan['phone']}', style: const TextStyle(color: Colors.white)),
            Text('Occupation: ${loan['occupation']}', style: const TextStyle(color: Colors.white)),
            Text('Monthly Income: ₹${loan['monthly_income']}', style: const TextStyle(color: Colors.white)),
            Text('Loan Amount: ₹${loan['loan_amount']}', style: const TextStyle(color: Colors.white)),
            Text('Purpose: ${loan['loan_purpose']}', style: const TextStyle(color: Colors.white)),
            Text('Status: ${loan['status']}', style: const TextStyle(color: Colors.white)),
            Text('Applied At: ${loan['created_at']}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () {
                    launchUrl(Uri.parse(loan['aadhaar_url']));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Aadhaar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () {
                    launchUrl(Uri.parse(loan['pan_url']));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download PAN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoanList(List<Map<String, dynamic>> loans) {
    return loans.isEmpty
        ? const Center(child: Text('No loans found'))
        : ListView.builder(
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final referredById = loan['referred_by']?.toString();
              String merchantName = merchantNames[referredById] ?? '';

              if (merchantName.isEmpty && merchantNames.isNotEmpty) {
                print('📦 Loan: ${loan['id']} referred_by: ${loan['referred_by']} -> ${merchantNames[loan['referred_by']]}');
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${loan['first_name'] ?? ''} ${loan['last_name'] ?? ''}',
                        ),
                      ),
                      if (referredById != null)
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
                          onPressed: () => updateLoanStatus(loan['id'], 'approved'),
                          child: const Text('Approve'),
                        ),
                        TextButton(
                          onPressed: () => updateLoanStatus(loan['id'], 'rejected'),
                          child: const Text('Reject'),
                        ),
                        ElevatedButton(
                          onPressed: () => showLoanDetails(loan),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NBFC Admin Dashboard'),
          actions: [
            IconButton(onPressed: viewProfile, icon: const Icon(Icons.person)),
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
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
                  fetchLoans();
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Direct'),
              Tab(text: 'Referred'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  buildLoanList(allLoans),
                  buildLoanList(directLoans),
                  buildLoanList(referredLoans),
                ],
              ),
      ),
    );
  }
}

Future<void> launchUrl(Uri url) async {
  if (!await launch(url.toString())) {
    throw 'Could not launch $url';
  }
}

// ✅ Step 6: Send notification to merchant after approval
Future<void> notifyMerchantOfApproval(String loanId) async {
  try {
    final loan = await supabase
        .from('loans')
        .select('referred_by')
        .eq('id', loanId)
        .maybeSingle();

    if (loan == null || loan['referred_by'] == null) {
      print('No referring merchant found for this loan.');
      return;
    }

    final merchantId = loan['referred_by'];

    await supabase.from('notifications').insert({
  'user_id': merchantId,               // Referring merchant
  'message': 'Loan Approved',
  'loan_id': loanId,                   // ✅ Must include this
  'type': 'loan',
  'is_read': false,
  'created_at': DateTime.now().toIso8601String(),
});


    print('Notification sent to merchant!');
  } catch (e) {
    print('Error sending merchant notification: $e');
  }
}










