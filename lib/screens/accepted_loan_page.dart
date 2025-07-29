import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class AcceptedLoansPage extends StatefulWidget {
  const AcceptedLoansPage({super.key});

  @override
  State<AcceptedLoansPage> createState() => _AcceptedLoansPageState();
}

class _AcceptedLoansPageState extends State<AcceptedLoansPage> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAcceptedLoans();
  }

  Future<void> fetchAcceptedLoans() async {
    final response = await supabase
        .from('loans')
        .select()
        .eq('status', 'approved');
    setState(() {
      loans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accepted Loans')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                return ListTile(
                  title: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                  subtitle: Text('Status: ${loan['status']}'),
                );
              },
            ),
    );
  }
}
