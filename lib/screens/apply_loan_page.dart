import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class ApplyLoanPage extends StatefulWidget {
  const ApplyLoanPage({super.key});

  @override
  State<ApplyLoanPage> createState() => _ApplyLoanPageState();
}

class _ApplyLoanPageState extends State<ApplyLoanPage> {
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
  final amountController = TextEditingController();
  final purposeController = TextEditingController();

  File? aadhaarFile;
  File? panFile;

  Future<void> pickFile(bool isAadhaar) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isAadhaar) {
          aadhaarFile = File(result.files.single.path!);
        } else {
          panFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<String?> uploadFile(File file, String fileName) async {
    final userId = supabase.auth.currentUser!.id;
    final path = 'documents/$userId/$fileName';
    final storage = supabase.storage.from('documents');

    final response = await storage.upload(path, file, fileOptions: const FileOptions(upsert: true));
    if (response.isEmpty) return null;

    final url = storage.getPublicUrl(path);
    return url;
  }

  Future<void> submitLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (aadhaarFile == null || panFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload Aadhaar and PAN files')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final aadhaarUrl = await uploadFile(aadhaarFile!, 'aadhaar_file');
      final panUrl = await uploadFile(panFile!, 'pan_file');

      await supabase.from('loans').insert({
        'user_id': supabase.auth.currentUser!.id,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'dob': dobController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'aadhaar_number': aadhaarNumberController.text.trim(),
        'pan_number': panNumberController.text.trim(),
        'occupation': occupationController.text.trim(),
        'monthly_income': double.tryParse(incomeController.text.trim()) ?? 0,
        'loan_amount': double.tryParse(amountController.text.trim()) ?? 0,
        'loan_purpose': purposeController.text.trim(),
        'aadhaar_url': aadhaarUrl,
        'pan_url': panUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan request submitted')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error submitting loan: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name'), validator: _required),
              TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name'), validator: _required),
              TextFormField(controller: dobController, decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'), validator: _required),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), validator: _required),
              TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), validator: _required),
              TextFormField(controller: aadhaarNumberController, decoration: const InputDecoration(labelText: 'Aadhaar Number'), validator: _required),
              TextFormField(controller: panNumberController, decoration: const InputDecoration(labelText: 'PAN Number'), validator: _required),
              TextFormField(controller: occupationController, decoration: const InputDecoration(labelText: 'Occupation'), validator: _required),
              TextFormField(controller: incomeController, decoration: const InputDecoration(labelText: 'Monthly Income'), keyboardType: TextInputType.number, validator: _required),
              TextFormField(controller: amountController, decoration: const InputDecoration(labelText: 'Loan Amount'), keyboardType: TextInputType.number, validator: _required),
              TextFormField(controller: purposeController, decoration: const InputDecoration(labelText: 'Loan Purpose'), validator: _required),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickFile(true),
                      icon: const Icon(Icons.file_upload),
                      label: Text(aadhaarFile != null ? 'Aadhaar Uploaded' : 'Upload Aadhaar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => pickFile(false),
                      icon: const Icon(Icons.file_upload),
                      label: Text(panFile != null ? 'PAN Uploaded' : 'Upload PAN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : submitLoan,
                child: isLoading ? const CircularProgressIndicator() : const Text('Submit Loan Application'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    return null;
  }
}
