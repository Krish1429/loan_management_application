import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class LoanDetailsPage extends StatelessWidget {
  final String loanId;

  const LoanDetailsPage({super.key, required this.loanId});

  Future<Map<String, dynamic>?> fetchLoanDetails() async {
    final response = await supabase
        .from('loans')
        .select('*, user_profiles!loans_user_id_fkey(name, email, phone, age), referred_by')
        .eq('id', loanId)
        .maybeSingle();

    if (response == null) return null;

    // Fetch merchant info if referred_by is not null
    if (response['referred_by'] != null) {
      final merchantResponse = await supabase
          .from('user_profiles')
          .select('name, email, phone')
          .eq('id', response['referred_by'])
          .maybeSingle();

      response['merchant'] = merchantResponse;
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchLoanDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Loan not found.'));
          }

          final user = data['user_profiles'];
          final merchant = data['merchant'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text("Loan Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Loan ID: ${data['id']}"),
                Text("Loan Amount: ₹${data['loan_amount']}"),
                Text("Purpose: ${data['loan_purpose']}"),
                Text("Status: ${data['status']}"),
                const Divider(),
                const Text("Borrower Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Name: ${user['name']}"),
                Text("Email: ${user['email']}"),
                Text("Phone: ${user['phone']}"),
                Text("Age: ${user['age']}"),
                if (merchant != null) ...[
                  const Divider(),
                  const Text("Referred By (Merchant)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Name: ${merchant['name']}"),
                  Text("Email: ${merchant['email']}"),
                  Text("Phone: ${merchant['phone']}"),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}

