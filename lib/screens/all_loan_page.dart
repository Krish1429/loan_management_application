import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import 'loan_details_page.dart';

class AllLoansPage extends StatefulWidget {
  const AllLoansPage({super.key});

  @override
  State<AllLoansPage> createState() => _AllLoansPageState();
}

class _AllLoansPageState extends State<AllLoansPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    final response = await supabase
        .from('loans')
        .select('*, user_profiles(name, address)')
        .order('created_at', ascending: false);

    setState(() {
      loans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Loan Applications"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    MaterialStateProperty.all(theme.colorScheme.surfaceVariant),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: loans.map((loan) {
                  final name = loan['user_profiles']['name'] ?? 'N/A';
                  final address = loan['user_profiles']['address'] ?? 'N/A';
                  final amount = loan['loan_amount'] ?? 0;
                  final status = loan['status'] ?? 'pending';

                  return DataRow(
                    cells: [
                      DataCell(Text(name)),
                      DataCell(Text(address)),
                      DataCell(Text('₹${amount.toStringAsFixed(2)}')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: _getStatusColor(status)),
                        ),
                      )),
                      DataCell(ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LoanDetailsPage(loanData: loan), // ✅ Required argument
                            ),
                          );
                        },
                        child: const Text("View"),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
