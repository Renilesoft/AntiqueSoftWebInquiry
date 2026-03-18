import 'package:flutter/material.dart';
import 'package:antiquewebemquiry/Services/notification.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final NotificationService notificationService = NotificationService();
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize notification service
    notificationService.init();
    
    // Set default values
    titleController.text = 'Test Notification';
    bodyController.text = 'This is a test notification from your app';
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> sendTestNotification() async {
    try {
      setState(() {
        statusMessage = 'Sending notification...';
      });

      await notificationService.showLocalNotification(
        title: titleController.text.isNotEmpty ? titleController.text : 'Test Notification',
        body: bodyController.text.isNotEmpty ? bodyController.text : 'This is a test notification',
      );

      setState(() {
        statusMessage = '✅ Notification sent successfully!';
      });

      // Reset message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            statusMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await notificationService.cancelAllNotifications();
      setState(() {
        statusMessage = '✅ All notifications cancelled!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            statusMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notification Test'),
        backgroundColor: const Color(0xFF172B4D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            if (statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: statusMessage.contains('Error') ? Colors.red[100] : Colors.green[100],
                  border: Border.all(
                    color: statusMessage.contains('Error') ? Colors.red : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusMessage,
                  style: TextStyle(
                    color: statusMessage.contains('Error') ? Colors.red[900] : Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Title input
            const Text(
              'Notification Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Enter notification title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Body input
            const Text(
              'Notification Body',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notification body',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 30),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: sendTestNotification,
                icon: const Icon(Icons.notifications_active),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF172B4D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: cancelAllNotifications,
                icon: const Icon(Icons.close),
                label: const Text('Cancel All Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Testing Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Enter a title and body text\n'
                    '2. Tap "Send Test Notification"\n'
                    '3. Notification should appear immediately\n'
                    '4. On Android: Will show in notification center\n'
                    '5. On iOS: Will show as alert or notification\n'
                    '6. Tap notification to see if it responds',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✅ If notification appears = Success!\n'
                    '❌ If no notification = Check phone settings',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}