import 'package:flutter/material.dart';
import '../supabase_client.dart';

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
    markAllAsRead(); // optional: mark as read on screen open
  }

  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('notifications')
        .select()
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
                    return ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: Text(n['message'] ?? ''),
                      subtitle: Text('Type: ${n['type'] ?? ''}'),
                      trailing: Text(
                        n['created_at']
                            .toString()
                            .substring(0, 10), // date only
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
    );
  }
}

