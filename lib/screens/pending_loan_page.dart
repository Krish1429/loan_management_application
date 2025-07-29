import 'package:flutter/material.dart';
import '../../supabase_client.dart';
import 'loan_details_page.dart';

class PendingLoansPage extends StatefulWidget {
  const PendingLoansPage({super.key});

  @override
  State<PendingLoansPage> createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  String selectedPurpose = 'All';
  final List<String> loanPurposes = [
    'All',
    'Personal Loan',
    'Home Loan',
    'Educational Loan',
    'Medical Loan',
    'Vehicle Loan',
    'Business Loan',
  ];

  @override
  void initState() {
    super.initState();
    fetchPendingLoans();
  }

  Future<void> fetchPendingLoans() async {
    setState(() => isLoading = true);

    var query = supabase
        .from('loans')
        .select()
        .eq('status', 'pending');

    if (selectedPurpose != 'All') {
      query = query.eq('loan_purpose', selectedPurpose);
    }

    final response = await query.order('created_at', ascending: false);

    setState(() {
      loans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> updateLoanStatus(String loanId, String newStatus) async {
    await supabase
        .from('loans')
        .update({'status': newStatus})
        .eq('id', loanId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loan marked as $newStatus')),
    );

    fetchPendingLoans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Loans')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: selectedPurpose,
              decoration: const InputDecoration(
                labelText: 'Filter by Loan Purpose',
                border: OutlineInputBorder(),
              ),
              items: loanPurposes.map((purpose) {
                return DropdownMenuItem(
                  value: purpose,
                  child: Text(purpose),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPurpose = value!;
                });
                fetchPendingLoans();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : loans.isEmpty
                    ? const Center(child: Text("No pending loans"))
                    : ListView.builder(
                        itemCount: loans.length,
                        itemBuilder: (context, index) {
                          final loan = loans[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoanDetailsPage(loanId: loan['id']),
                                  ),
                                );
                              },
                              title: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                              subtitle: Text('Requested on: ${loan['created_at'].toString().substring(0, 10)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: "Approve",
                                    onPressed: () => updateLoanStatus(loan['id'], 'approved'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    tooltip: "Reject",
                                    onPressed: () => updateLoanStatus(loan['id'], 'rejected'),
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
    );
  }
}


