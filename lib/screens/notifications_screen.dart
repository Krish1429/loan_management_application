import 'package:flutter/material.dart';
import '../supabase_client.dart';
import 'upload_documents_page.dart'; // Ensure this import exists

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    markAllAsRead(); // Optional: mark all as read when screen opens
  }

  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('notifications')
        .select('id, user_id, message, type, loan_id, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    setState(() {
      notifications = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> markAllAsRead() async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  void handleNotificationTap(Map<String, dynamic> notification) async {
    final loanId = notification['loan_id'];
    final type = notification['type'];

    if (type != 'loan' || loanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Loan ID found for this notification')),
      );
      return;
    }

    try {
      final loan = await supabase
          .from('loans')
          .select('status')
          .eq('id', loanId)
          .maybeSingle();

      if (loan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan not found')),
        );
        return;
      }

      if (loan['status'] == 'approved') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadDocumentsPage(loanId: loanId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This loan is ${loan['status']}. Upload not allowed.'),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking loan status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return GestureDetector(
                      onTap: () => handleNotificationTap(n),
                      child: Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(n['message'] ?? ''),
                          subtitle: Text('Type: ${n['type'] ?? ''}'),
                          trailing: Text(
                            n['created_at']?.toString().substring(0, 10) ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}



