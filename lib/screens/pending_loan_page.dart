import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class PendingLoansPage extends StatefulWidget {
  const PendingLoansPage({super.key});

  @override
  State<PendingLoansPage> createState() => _PendingLoansPageState();
}

class _PendingLoansPageState extends State<PendingLoansPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingLoans();
  }

  Future<void> fetchPendingLoans() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('loans')
          .select('''
            *,
            borrower:user_profiles!loans_user_id_fkey(name, address),
            merchant:user_profiles!fk_referred_by(username)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      setState(() {
        loans = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching loans: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateLoanStatus(String loanId, String status) async {
    try {
      await supabase.from('loans').update({'status': status}).eq('id', loanId);
      fetchPendingLoans();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan $status')),
      );
    } catch (e) {
      print('Error updating loan: $e');
    }
  }

  Widget buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 18,
        headingRowColor: MaterialStateColor.resolveWith((_) => Colors.black),
        dataRowColor: MaterialStateColor.resolveWith((_) => Colors.grey[850]!),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        dataTextStyle: const TextStyle(color: Colors.white70),
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Loan Amount')),
          DataColumn(label: Text('Purpose')),
          DataColumn(label: Text('Merchant')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Actions')),
        ],
        rows: loans.map((loan) {
          final borrower = loan['borrower'];
          final merchant = loan['merchant'];
          return DataRow(cells: [
            DataCell(Text(borrower?['name'] ?? '-')),
            DataCell(Text(borrower?['address'] ?? '-')),
            DataCell(Text('₹${loan['loan_amount'].toString()}')),
            DataCell(Text(loan['loan_purpose'] ?? '-')),
            DataCell(Text(merchant?['username'] ?? 'Direct')),
            DataCell(Text(loan['created_at'].toString().substring(0, 10))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => updateLoanStatus(loan['id'], 'approved'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => updateLoanStatus(loan['id'], 'rejected'),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A171E),
      appBar: AppBar(
        title: const Text('Pending Loans'),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loans.isEmpty
              ? const Center(
                  child: Text('No pending loans', style: TextStyle(color: Colors.white70)),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: buildDataTable(),
                ),
    );
  }
}



