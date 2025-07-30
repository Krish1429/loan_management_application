import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../supabase_client.dart';

class MerchantReferredLoansScreen extends StatefulWidget {
  const MerchantReferredLoansScreen({super.key});

  @override
  State<MerchantReferredLoansScreen> createState() =>
      _MerchantReferredLoansScreenState();
}

class _MerchantReferredLoansScreenState
    extends State<MerchantReferredLoansScreen> {
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

  String formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  void showLoanDetailsDialog(Map<String, dynamic> loan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            "${loan['first_name'] ?? ''} ${loan['last_name'] ?? ''}",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detailItem("Address", loan['address']),
                detailItem("Phone", loan['phone']),
                detailItem("Occupation", loan['occupation']),
                detailItem("Loan Amount", '₹${loan['loan_amount']?.toStringAsFixed(2)}'),
                detailItem("Loan Purpose", loan['loan_purpose']),
                detailItem("Status", loan['status']),
                detailItem("Created At", formatDate(loan['created_at'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close", style: TextStyle(color: Colors.deepPurple)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget detailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value != null ? value.toString() : 'N/A',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Referred Loans'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : referredLoans.isEmpty
              ? const Center(
                  child: Text(
                    'No referred loan applications yet.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (_) => Colors.deepPurple.shade100),
                    dataRowColor: MaterialStateColor.resolveWith(
                        (_) => Colors.grey.shade900),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text("Customer Name")),
                      DataColumn(label: Text("Address")),
                      DataColumn(label: Text("Amount")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: referredLoans.map((loan) {
                      final name =
                          '${loan['first_name'] ?? ''} ${loan['last_name'] ?? ''}'.trim();
                      final address = loan['address'] ?? 'N/A';
                      final amount = loan['loan_amount'] ?? 0;
                      final status = loan['status'] ?? 'Pending';

                      return DataRow(cells: [
                        DataCell(Text(name, style: const TextStyle(color: Colors.white))),
                        DataCell(Text(address, style: const TextStyle(color: Colors.white))),
                        DataCell(Text('₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: getStatusColor(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text("View"),
                            onPressed: () => showLoanDetailsDialog(loan),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}
