import 'package:flutter/material.dart';
import '../../supabase_client.dart';

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
    final response = await supabase.from('loans').select();
    setState(() {
      loans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Loan Applications')),
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
