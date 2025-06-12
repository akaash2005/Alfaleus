import 'package:flutter/material.dart';
import 'notification_store.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist')),
      body: ListView.builder(
        itemCount: taskNotifications.length,
        itemBuilder: (context, index) {
          final notif = taskNotifications[index];
          return ListTile(
            title: Text(notif['title'] ?? 'No Title'),
            subtitle: Text(notif['description'] ?? ''),
            trailing: Text(notif['timestamp']?.toString() ?? ''),
          );
        },
      ),
    );
  }
}
