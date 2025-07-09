import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFeedbackPage extends StatefulWidget {
  final User user;

  const UserFeedbackPage({super.key, required this.user});

  @override
  State<UserFeedbackPage> createState() => _UserFeedbackPageState();
}

class _UserFeedbackPageState extends State<UserFeedbackPage> {
  List<Map<String, dynamic>> feedbackList = [];

  @override
  void initState() {
    super.initState();
    loadUserFeedback();
  }

  Future<void> loadUserFeedback() async {
    final feedbacks = await FeedbackService.getUserFeedback(widget.user.uid);
    setState(() {
      feedbackList = feedbacks;
    });
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Feedback')),
      body: ListView.builder(
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final item = feedbackList[index];
          return ListTile(
            title: Text(item['subject']),
            subtitle: Text('${item['category']} - ${item['status']}'),
            trailing: Text(_getPriorityText(item['priority'] ?? 2)),
          );
        },
      ),
    );
  }
}
