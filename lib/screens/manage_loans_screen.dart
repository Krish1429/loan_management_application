import 'package:flutter/material.dart';
import '../../supabase_client.dart';
import 'loan_details_page.dart';

class ManageLoansScreen extends StatefulWidget {
  const ManageLoansScreen({super.key});

  @override
  State<ManageLoansScreen> createState() => _ManageLoansScreenState();
}

class _ManageLoansScreenState extends State<ManageLoansScreen> {
  List<Map<String, dynamic>> allLoans = [];
  List<Map<String, dynamic>> filteredLoans = [];
  bool isLoading = true;

  String searchQuery = '';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    setState(() => isLoading = true);
    final response = await supabase
        .from('loans')
        .select('id, loan_amount, status, user_profiles(name, address)')
        .order('created_at', ascending: false);
    allLoans = List<Map<String, dynamic>>.from(response);
    applyFilters();
    setState(() => isLoading = false);
  }

  Future<void> updateLoanStatus(String loanId, String newStatus) async {
    await supabase.from('loans').update({'status': newStatus}).eq('id', loanId);
    await fetchLoans(); // Refresh after status change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loan marked as $newStatus')),
    );
  }

  void applyFilters() {
    List<Map<String, dynamic>> results = allLoans;
    if (selectedStatus != 'All') {
      results = results.where((loan) => loan['status'] == selectedStatus.toLowerCase()).toList();
    }
    if (searchQuery.isNotEmpty) {
      results = results.where((loan) {
        final id = loan['id'].toString().toLowerCase();
        final amount = loan['loan_amount'].toString().toLowerCase();
        return id.contains(searchQuery.toLowerCase()) || amount.contains(searchQuery.toLowerCase());
      }).toList();
    }
    setState(() => filteredLoans = results);
  }

  Widget buildStatusTag(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Loan Applications')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// Search & Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search by ID or Amount',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            searchQuery = value;
                            applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: selectedStatus,
                        items: ['All', 'Pending', 'Approved', 'Rejected']
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) {
                          selectedStatus = value!;
                          applyFilters();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// DataTable
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filteredLoans.map((loan) {
                          final user = loan['user_profiles'];
                          final status = loan['status'];
                          return DataRow(cells: [
                            DataCell(Text(user['name'] ?? '-')),
                            DataCell(Text(user['address'] ?? '-')),
                            DataCell(Text("₹${loan['loan_amount']}")),
                            DataCell(buildStatusTag(status)),
                            DataCell(Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LoanDetailsPage(loanId: loan['id']),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('View'),
                                ),
                                const SizedBox(width: 6),
                                if (status == 'pending') ...[
                                  ElevatedButton(
                                    onPressed: () => updateLoanStatus(loan['id'], 'approved'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Approve'),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: () => updateLoanStatus(loan['id'], 'rejected'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

