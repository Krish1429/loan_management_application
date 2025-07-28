import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadDocumentsPage extends StatefulWidget {
  final String loanId;

  const UploadDocumentsPage({super.key, required this.loanId});

  @override
  State<UploadDocumentsPage> createState() => _UploadDocumentsPageState();
}

class _UploadDocumentsPageState extends State<UploadDocumentsPage> {
  final List<String> requiredDocs = [
    "Aadhaar front image",
    "Aadhaar back image",
    "Salary Slip",
    "PAN front",
    "Bank statement",
    "Invoice",
    "Appraisal Slip",
    "Address Proof",
    "EB/Gas/Tax Bill",
    "Gold Product Live Photo",
  ];

  final Map<String, PlatformFile?> selectedFiles = {};
  bool isApproved = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoanStatus();
  }

  Future<void> checkLoanStatus() async {
    try {
      final loan = await Supabase.instance.client
          .from('loans')
          .select('status')
          .eq('id', widget.loanId)
          .maybeSingle();

      if (loan != null && loan['status'] == 'approved') {
        setState(() {
          isApproved = true;
          isLoading = false;
        });
      } else {
        setState(() {
          isApproved = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isApproved = false;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking loan status')),
      );
    }
  }

  Future<void> pickFile(String docType) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() => selectedFiles[docType] = result.files.first);
    }
  }

  Future<void> uploadAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final storage = Supabase.instance.client.storage;
    const bucket = 'documents'; // Ensure bucket exists in Supabase

    try {
      for (final entry in selectedFiles.entries) {
        final docType = entry.key;
        final file = entry.value;
        if (file == null) continue;

        final filePath =
            'merchant_uploads/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final fileBytes = File(file.path!).readAsBytesSync();

        await storage
            .from(bucket)
            .uploadBinary(filePath, fileBytes, fileOptions: FileOptions(upsert: true));
        final publicUrl = storage.from(bucket).getPublicUrl(filePath);

        await Supabase.instance.client.from('merchant_documents').insert({
          'loan_id': widget.loanId,
          'merchant_id': user.id,
          'document_type': docType,
          'file_url': publicUrl,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents uploaded successfully')),
      );

      Navigator.pop(context); // or navigate elsewhere
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading documents: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A171E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isApproved) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A171E),
        appBar: AppBar(title: const Text('Upload Documents')),
        body: const Center(
          child: Text(
            'Loan is not approved.\nYou cannot upload documents.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF1A171E),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final doc in requiredDocs)
            Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(doc, style: const TextStyle(color: Colors.white)),
                subtitle: selectedFiles[doc] != null
                    ? Text(selectedFiles[doc]!.name,
                        style: const TextStyle(color: Colors.greenAccent))
                    : const Text("No file selected",
                        style: TextStyle(color: Colors.white70)),
                trailing: IconButton(
                  icon: const Icon(Icons.upload_file,
                      color: Colors.deepPurpleAccent),
                  onPressed: () => pickFile(doc),
                ),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: uploadAll,
            child: const Text("Submit Documents"),
          ),
        ],
      ),
    );
  }
}

