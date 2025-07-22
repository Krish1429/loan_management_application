import 'package:flutter/material.dart';
import '../supabase_client.dart';

class ReferralLoanPage extends StatefulWidget {
  const ReferralLoanPage({super.key});

  @override
  State<ReferralLoanPage> createState() => _ReferralLoanPageState();
}

class _ReferralLoanPageState extends State<ReferralLoanPage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final occupationController = TextEditingController();
  final loanAmountController = TextEditingController();
  final loanPurposeController = TextEditingController();

  bool isLoading = false;

  Future<void> submitReferralLoan() async {
    if (!_formKey.currentState!.validate()) return;

    final merchantId = supabase.auth.currentUser?.id;
    if (merchantId == null) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('loans').insert({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'age': int.tryParse(ageController.text.trim()),
        'occupation': occupationController.text.trim(),
        'loan_amount': double.tryParse(loanAmountController.text.trim()),
        'loan_purpose': loanPurposeController.text.trim(),
        'referred_by': merchantId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral loan submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    occupationController.dispose();
    loanAmountController.dispose();
    loanPurposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a Loan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInput(firstNameController, 'First Name'),
              _buildInput(lastNameController, 'Last Name'),
              _buildInput(phoneController, 'Phone Number', type: TextInputType.phone),
              _buildInput(ageController, 'Age', type: TextInputType.number),
              _buildInput(occupationController, 'Occupation'),
              _buildInput(loanAmountController, 'Loan Amount', type: TextInputType.number),
              _buildInput(loanPurposeController, 'Loan Purpose'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : submitReferralLoan,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Referral'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
