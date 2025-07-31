import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReferralLoanPage extends StatefulWidget {
  const ReferralLoanPage({super.key});

  @override
  State<ReferralLoanPage> createState() => _ReferralLoanPageState();
}

class _ReferralLoanPageState extends State<ReferralLoanPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final aadhaarNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  final occupationController = TextEditingController();
  final incomeController = TextEditingController();
  final amountController = TextEditingController(text: '5000');
  final purposeController = TextEditingController();

  File? aadhaarFile;
  File? panFile;
  String? aadhaarFileName;
  String? panFileName;

  double loanAmount = 5000;

  final List<String> loanTypes = [
    'Home Loan',
    'Education Loan',
    'Business Loan',
    'Personal Loan',
    'Vehicle Loan',
    'Medical Loan',
  ];

  final supabase = Supabase.instance.client;

  Future<void> pickFile(bool isAadhaar) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isAadhaar) {
          aadhaarFile = File(result.files.single.path!);
          aadhaarFileName = result.files.single.name;
        } else {
          panFile = File(result.files.single.path!);
          panFileName = result.files.single.name;
        }
      });
    }
  }

  Future<String?> uploadFile(File file, String fileName) async {
    final userId = supabase.auth.currentUser!.id;
    final path = 'documents/$userId/$fileName';
    final storage = supabase.storage.from('documents');

    final response = await storage.upload(path, file, fileOptions: const FileOptions(upsert: true));
    if (response.isEmpty) {
      // Upload success returns empty string per docs
      return storage.getPublicUrl(path);
    }
    return null;
  }

  Future<void> submitLoan() async {
    if (!_formKey.currentState!.validate()) return;

    if (aadhaarFile == null || panFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Aadhaar and PAN files')),
      );
      return;
    }

    if (loanAmount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan amount must be at least ₹5,000')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Loan Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${firstNameController.text} ${lastNameController.text}'),
            Text('Aadhaar: ${aadhaarNumberController.text}'),
            Text('PAN: ${panNumberController.text}'),
            Text('Amount: ₹${amountController.text}'),
            Text('Purpose: ${purposeController.text}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);

    try {
      final aadhaarUrl = await uploadFile(aadhaarFile!, aadhaarFileName ?? 'aadhaar.pdf');
      final panUrl = await uploadFile(panFile!, panFileName ?? 'pan.pdf');

      if (aadhaarUrl == null || panUrl == null) {
        throw Exception('Failed to upload documents');
      }

      final userId = supabase.auth.currentUser!.id;

      // Fetch merchant name from user_profiles table
      final userProfileResponse = await supabase
          .from('user_profiles')
          .select('username')
          .eq('id', userId)
          .single();

      final merchantName = userProfileResponse.data?['username'] ?? 'Unknown';

      // Insert loan record
      final insertResponse = await supabase.from('loans').insert({
        'user_id': userId,
        'referred_by': userId,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'dob': dobController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'aadhaar_number': aadhaarNumberController.text.trim(),
        'pan_number': panNumberController.text.trim(),
        'occupation': occupationController.text.trim(),
        'monthly_income': double.tryParse(incomeController.text.trim()) ?? 0,
        'loan_amount': loanAmount,
        'loan_purpose': purposeController.text.trim(),
        'aadhaar_url': aadhaarUrl,
        'pan_url': panUrl,
      });

      // Notify admin users
      final adminUsersResponse = await supabase
          .from('user_profiles')
          .select('id')
          .eq('sign_up_as', 'NBFC Admin');

      if (adminUsersResponse.error == null) {
        final adminUsers = adminUsersResponse.data as List<dynamic>;
        for (var admin in adminUsers) {
          await supabase.from('notifications').insert({
            'user_id': admin['id'],
            'message': 'Merchant $merchantName referred a new loan.',
            'type': 'loan',
          });
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral loan submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting referral loan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    }

    setState(() => isLoading = false);
  }

  String? _required(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18)); // 18 years ago
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = picked.toIso8601String().split('T').first; // YYYY-MM-DD
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    addressController.dispose();
    aadhaarNumberController.dispose();
    panNumberController.dispose();
    occupationController.dispose();
    incomeController.dispose();
    amountController.dispose();
    purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer a Loan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: _required,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: _required,
              ),
              TextFormField(
                controller: dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  // You could add more date validation here
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: _required,
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: _required,
              ),
              TextFormField(
                controller: aadhaarNumberController,
                decoration: const InputDecoration(labelText: 'Aadhaar Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  final cleaned = value.replaceAll(RegExp(r'\s+'), '');
                  final aadhaarReg = RegExp(r'^\d{12}$');
                  return aadhaarReg.hasMatch(cleaned) ? null : 'Enter valid 12-digit Aadhaar number';
                },
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: panNumberController,
                decoration: const InputDecoration(labelText: 'PAN Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  final panReg = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
                  return panReg.hasMatch(value) ? null : 'Enter valid PAN number (e.g., ABCDE1234F)';
                },
                textCapitalization: TextCapitalization.characters,
              ),
              TextFormField(
                controller: occupationController,
                decoration: const InputDecoration(labelText: 'Occupation'),
                validator: _required,
              ),
              TextFormField(
                controller: incomeController,
                decoration: const InputDecoration(labelText: 'Monthly Income'),
                keyboardType: TextInputType.number,
                validator: _required,
              ),

              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Loan Amount (₹5,000 - ₹65,000)', style: TextStyle(fontSize: 16)),
              ),
              Slider(
                value: loanAmount,
                min: 5000,
                max: 65000,
                divisions: 13,
                label: '₹${loanAmount.toInt()}',
                onChanged: (value) {
                  setState(() {
                    loanAmount = value;
                    amountController.text = value.toInt().toString();
                  });
                },
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Loan Purpose'),
                items: loanTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    purposeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select a loan purpose';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(aadhaarFileName ?? 'Upload Aadhaar (PDF)'),
                      onPressed: () => pickFile(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: Text(panFileName ?? 'Upload PAN (PDF)'),
                      onPressed: () => pickFile(false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitLoan,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Referral'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




// ✅ You can now copy/paste this into ApplyLoanPage with just one change:
// Remove the `referred_by` field in the `loan` map when inserting
// I can send that version next if you'd like!

