import 'package:flutter/material.dart';

class LoanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> loanData;

  const LoanDetailsPage({super.key, required this.loanData});

  @override
  Widget build(BuildContext context) {
    final borrower = loanData['user_profiles'];
    final merchant = loanData['referred_by'];
    final amount = loanData['loan_amount'];
    final purpose = loanData['loan_purpose'];
    final status = loanData['status'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Name: ${borrower?['name'] ?? '-'}', style: const TextStyle(color: Colors.white)),
            Text('Address: ${borrower?['address'] ?? '-'}', style: const TextStyle(color: Colors.white)),
            Text('Amount: ₹${amount?.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('Purpose: $purpose', style: const TextStyle(color: Colors.white)),
            Text('Status: $status', style: const TextStyle(color: Colors.white)),
            Text('Referred By: ${merchant?['username'] ?? 'Direct'}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}


