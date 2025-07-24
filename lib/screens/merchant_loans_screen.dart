import 'package:flutter/material.dart';
import '../supabase_client.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantLoansScreen extends StatefulWidget {
  const MerchantLoansScreen({super.key});

  @override
  State<MerchantLoansScreen> createState() => _MerchantLoansScreenState();
}

class _MerchantLoansScreenState extends State<MerchantLoansScreen> {
  List<Map<String, dynamic>> loanRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoanRequests();
  }

  Future<void> fetchLoanRequests() async {
    final merchantId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('loans')
        .select()
        .eq('referred_by', merchantId) // ✅ Filter: only show referred loans
        .order('created_at', ascending: false);

    setState(() {
      loanRequests = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  void _openUrl(String filePath) async {
    final publicUrl = supabase.storage.from('documents').getPublicUrl(filePath);
    final uri = Uri.parse(publicUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : loanRequests.isEmpty
            ? const Center(child: Text('No referred loan requests found'))
            : ListView.builder(
                itemCount: loanRequests.length,
                itemBuilder: (context, index) {
                  final loan = loanRequests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ExpansionTile(
                      title: Text('${loan['first_name']} ${loan['last_name']}'),
                      subtitle: Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                      children: [
                        ListTile(title: Text('Phone: ${loan['phone']}')),
                        ListTile(title: Text('DOB: ${loan['dob']}')),
                        ListTile(title: Text('Address: ${loan['address']}')),
                        ListTile(title: Text('Occupation: ${loan['occupation']}')),
                        ListTile(title: Text('Income: ₹${loan['monthly_income']}')),
                        ListTile(title: Text('Aadhaar Number: ${loan['aadhaar_number']}')),
                        ListTile(title: Text('PAN Number: ${loan['pan_number']}')),
                        ListTile(title: Text('Status: ${loan['status']}')),
                        ButtonBar(
                          alignment: MainAxisAlignment.start,
                          children: [
                            if (loan['aadhaar_url'] != null)
                              TextButton(
                                onPressed: () => _openUrl(loan['aadhaar_url']),
                                child: const Text('View Aadhaar'),
                              ),
                            if (loan['pan_url'] != null)
                              TextButton(
                                onPressed: () => _openUrl(loan['pan_url']),
                                child: const Text('View PAN'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
  }
}

