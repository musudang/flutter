import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'package:intl/intl.dart';

class QnaDetailScreen extends StatelessWidget {
  final Question question;

  const QnaDetailScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q&A Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Asked by ${question.authorName} on ${DateFormat('MMM d, yyyy').format(question.timestamp)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(question.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Answers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('No answers yet. Be the first to answer!'),
            ),
          ],
        ),
      ),
    );
  }
}
