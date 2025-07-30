import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../supabase_client.dart';
import 'upload_documents_page.dart';

class ManageLoansPage extends StatefulWidget {
  const ManageLoansPage({super.key});

  @override
  State<ManageLoansPage> createState() => _ManageLoansPageState();
}

class _ManageLoansPageState extends State<ManageLoansPage> {
  List<dynamic> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoans();
  }

  Future<void> fetchLoans() async {
    try {
     final response = await supabase
    .from('loans')
    .select('''
      *,
      borrower:user_profiles!loans_user_id_fkey(username, address),
      merchant:user_profiles!fk_referred_by(username)
    ''')
    .eq('status', 'pending')
    .order('created_at', ascending: false);


      setState(() {
        loans = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching loans: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateLoanStatus(String loanId, String status) async {
    await supabase
        .from('loans')
        .update({'status': status})
        .eq('id', loanId);

    fetchLoans();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Loan Applications'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[900]),
                dataRowColor: MaterialStateProperty.all(Colors.grey[850]),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Address', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Merchant', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                ],
                rows: loans.map((loan) {
                  final borrower = loan['borrower'];
                  final merchant = loan['merchant'];
                  final status = loan['status'];

                  return DataRow(cells: [
                    DataCell(Text(borrower?['name'] ?? '-', style: const TextStyle(color: Colors.white))),
                    DataCell(Text(borrower?['address'] ?? '-', style: const TextStyle(color: Colors.white))),
                    DataCell(Text('₹${loan['loan_amount'] ?? 0}', style: const TextStyle(color: Colors.white))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )),
                    DataCell(Text(merchant?['username'] ?? '-', style: const TextStyle(color: Colors.white70))),
                    DataCell(Row(
                      children: [
                        ElevatedButton(
                          onPressed: status == 'pending'
                              ? () => updateLoanStatus(loan['id'], 'accepted')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.green.withOpacity(0.5),
                          ),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: status == 'pending'
                              ? () => updateLoanStatus(loan['id'], 'rejected')
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red.withOpacity(0.5),
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: status == 'accepted'
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UploadDocumentsPage(loanId: loan['id']),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            disabledBackgroundColor: Colors.blueGrey,
                          ),
                          child: const Text('Upload Docs'),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}





