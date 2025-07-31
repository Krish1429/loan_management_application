import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantLoansPage extends StatefulWidget {
  const MerchantLoansPage({super.key});

  @override
  State<MerchantLoansPage> createState() => _MerchantLoansPageState();
}

class _MerchantLoansPageState extends State<MerchantLoansPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('loans')
          .select('''
            id, first_name, last_name, address, phone, loan_amount, status, loan_purpose, created_at,
            user_profiles!loans_user_id_fkey (
              email
            )
          ''')
          .eq('user_id', userId);

      loans = (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching loans: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  Color _getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  void showLoanDetails(Map<String, dynamic> loan) {
    final profile = loan['user_profiles'] ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Loan Details',
            style: TextStyle(color: Colors.purple[400]),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name',
                  '${loan['first_name'] ?? '-'} ${loan['last_name'] ?? '-'}'),
              _buildDetailRow('Email', profile['email'] ?? '-'),
              _buildDetailRow('Phone', loan['phone'] ?? '-'),
              _buildDetailRow('Address', loan['address'] ?? '-'),
              _buildDetailRow('Amount', '₹${loan['loan_amount'] ?? '-'}'),
              _buildDetailRow('Purpose', loan['loan_purpose'] ?? '-'),
              _buildDetailRow('Status', loan['status'] ?? '-'),
              _buildDetailRow('Created At', loan['created_at'] ?? '-'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.purple)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('My Loans'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loans.isEmpty
              ? const Center(
                  child: Text(
                    'No loans found',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade900),
                          dataRowColor: MaterialStateProperty.all(const Color(0xFF1E1E1E)),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text('Name',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Address',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Amount',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Status',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text('Actions',
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: loans.map((loan) {
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  '${loan['first_name'] ?? ''} ${loan['last_name'] ?? ''}',
                                  style: const TextStyle(color: Colors.white),
                                )),
                                DataCell(Text(
                                  loan['address'] ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                )),
                                DataCell(Text(
                                  '₹${loan['loan_amount']?.toString() ?? '-'}',
                                  style: const TextStyle(color: Colors.white),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(loan['status']),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (loan['status'] ?? '-').toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),
                                DataCell(
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: () => showLoanDetails(loan),
                                    child: const Text('View'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}





