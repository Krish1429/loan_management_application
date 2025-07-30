import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';

class ReferredLoansScreen extends StatefulWidget {
  const ReferredLoansScreen({super.key});

  @override
  State<ReferredLoansScreen> createState() => _ReferredLoansScreenState();
}

class _ReferredLoansScreenState extends State<ReferredLoansScreen> {
  List<Map<String, dynamic>> referredLoans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReferredLoans();
  }

  Future<void> fetchReferredLoans() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('loans')
        .select()
        .eq('referred_by', userId)
        .order('created_at', ascending: false);

    setState(() {
      referredLoans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  void showLoanDetailsModal(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('${loan['first_name']} ${loan['last_name']}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailText('Phone', loan['phone']),
              detailText('Occupation', loan['occupation']),
              detailText('Monthly Income', '₹${loan['monthly_income']}'),
              detailText('Loan Amount', '₹${loan['loan_amount']}'),
              detailText('Purpose', loan['loan_purpose']),
              detailText('Status', loan['status']),
              detailText('Address', loan['address']),
              detailText('Created At', formatDate(loan['created_at'])),
            ],
          ),
        ),
        actions: [
          if (loan['status'] == 'pending') ...[
            TextButton(
              onPressed: () => updateLoanStatus(loan['id'], 'approved'),
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () => updateLoanStatus(loan['id'], 'rejected'),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget detailText(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: $value', style: const TextStyle(color: Colors.white)),
    );
  }

  Future<void> updateLoanStatus(String loanId, String status) async {
    await supabase
        .from('loans')
        .update({'status': status})
        .eq('id', loanId);

    if (mounted) {
      Navigator.pop(context); // Close modal
      fetchReferredLoans();   // Refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan $status successfully'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        title: const Text('Referred Loans'),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Referred Loans",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.deepPurple.shade100),
                      dataRowColor: MaterialStateProperty.all(Colors.grey.shade900),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text("Customer Name")),
                        DataColumn(label: Text("Address")),
                        DataColumn(label: Text("Amount")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: referredLoans.map((loan) {
                        final name = '${loan['first_name']} ${loan['last_name']}';
                        final address = loan['address'] ?? 'N/A';
                        final amount = loan['loan_amount'] ?? 0;
                        final status = loan['status'] ?? 'pending';

                        return DataRow(cells: [
                          DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                          DataCell(Text(address, style: const TextStyle(color: Colors.white))),
                          DataCell(Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.bold),
                            ),
                          )),
                          DataCell(
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: () {
                                showLoanDetailsModal(loan);
                              },
                              child: const Text("View"),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


