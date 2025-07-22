import 'package:flutter/material.dart';
import '../supabase_client.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key});

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyLoans();
  }

  Future<void> fetchMyLoans() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('loans')
        .select()
        .eq('user_id', userId ?? '')
        .order('created_at', ascending: false);

    setState(() {
      loans = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  void _openUrl(String url) {
    final uri = Uri.parse(url);
   supabase.storage.from('documents').getPublicUrl(uri.toString());

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loans.isEmpty
              ? const Center(child: Text('No loans found'))
              : ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                        subtitle: Text('Status: ${loan['status']}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'aadhaar' && loan['aadhaar_url'] != null) {
                              _openUrl(loan['aadhaar_url']);
                            }
                            if (value == 'pan' && loan['pan_url'] != null) {
                              _openUrl(loan['pan_url']);
                            }
                          },
                          itemBuilder: (context) => [
                            if (loan['aadhaar_url'] != null)
                              const PopupMenuItem(value: 'aadhaar', child: Text('View Aadhaar')),
                            if (loan['pan_url'] != null)
                              const PopupMenuItem(value: 'pan', child: Text('View PAN')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
