import 'package:flutter/material.dart';
import '../../supabase_client.dart';

class ReferredLoansScreen extends StatefulWidget {
  const ReferredLoansScreen({super.key});

  @override
  State<ReferredLoansScreen> createState() => _ReferredLoansScreenState();
}

class _ReferredLoansScreenState extends State<ReferredLoansScreen> {
  List<Map<String, dynamic>> referredLoans = [];
  Map<String, String> merchantNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReferredLoans();
  }

  Future<void> fetchReferredLoans() async {
    final response = await supabase
        .from('loans')
        .select()
        .not('referred_by', 'is', null)
        .order('created_at', ascending: false);

    final loans = List<Map<String, dynamic>>.from(response);

    // Collect referred merchant IDs
    final referredIds = loans
        .map((loan) => loan['referred_by'])
        .where((id) => id != null)
        .toSet()
        .toList();

    if (referredIds.isNotEmpty) {
      final merchantData = await supabase
          .from('user_profiles')
          .select('id, username')
          .in_('id', referredIds);

      merchantNames = {
        for (var m in merchantData) m['id']: m['username']
      };
    }

    setState(() {
      referredLoans = loans;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : referredLoans.isEmpty
            ? const Center(child: Text('No referred loan applications'))
            : ListView.builder(
                itemCount: referredLoans.length,
                itemBuilder: (context, index) {
                  final loan = referredLoans[index];
                  final refName = merchantNames[loan['referred_by']] ?? 'Unknown';

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text('${loan['first_name']} ${loan['last_name']}'),
                          ),
                          const Chip(
                            label: Text('Referred', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹${loan['loan_amount']} - ${loan['loan_purpose']}'),
                          Text('Referred by: $refName', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
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
