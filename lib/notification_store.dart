List<Map<String, dynamic>> taskNotifications = [];
void addNotification(Map<String, dynamic> notif) {
  final exists = taskNotifications.any((n) =>
      n['title'] == notif['title'] &&
      n['description'] == notif['description']);

  if (!exists) {
    taskNotifications.add(notif);
  }
}