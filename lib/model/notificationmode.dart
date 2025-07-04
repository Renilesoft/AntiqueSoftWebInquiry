class NotificationItem {
  final String id;
  final String title;
  final String itemDescription;
  final String quantity;
  final String timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.itemDescription,
    required this.quantity,
    required this.timestamp,
    this.isRead = false,
  });
}