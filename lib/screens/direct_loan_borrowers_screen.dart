import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class DirectLoanBorrowersScreen extends StatefulWidget {
  const DirectLoanBorrowersScreen({super.key});

  @override
  State<DirectLoanBorrowersScreen> createState() => _DirectLoanBorrowersScreenState();
}

class _DirectLoanBorrowersScreenState extends State<DirectLoanBorrowersScreen> {
  List<Map<String, dynamic>> directLoans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDirectLoans();
  }

  Future<void> fetchDirectLoans() async {
    final response = await supabase
        .from('loans')
        .select()
        .is_('referred_by', null) // Borrower-applied loans
        .order('created_at', ascending: false);

    setState(() {
      directLoans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : directLoans.isEmpty
            ? const Center(child: Text('No direct loan applications'))
            : ListView.builder(
                itemCount: directLoans.length,
                itemBuilder: (context, index) {
                  final loan = directLoans[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ExpansionTile(
                      title: Text('${loan['first_name']} ${loan['last_name']}'),
                      subtitle: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                      children: [
                        ListTile(title: Text('Phone: ${loan['phone']}')),
                        ListTile(title: Text('Occupation: ${loan['occupation']}')),
                        ListTile(title: Text('Status: ${loan['status']}')),
                        ListTile(title: Text('Created: ${loan['created_at']}')),
                      ],
                    ),
                  );
                },
              );
  }
}
