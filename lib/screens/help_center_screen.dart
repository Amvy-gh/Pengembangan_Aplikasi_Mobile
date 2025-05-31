import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class HelpCenterScreen extends StatelessWidget {
  HelpCenterScreen({Key? key}) : super(key: key);

  final List<FAQItem> _faqList = [
    FAQItem(
      question: 'How to add new schedule?',
      answer:
          'To add new schedule:\n'
          '1. Go to Schedule tab\n'
          '2. Tap + button\n'
          '3. Fill required information\n'
          '4. Save',
    ),
    FAQItem(
      question: 'How to edit profile?',
      answer:
          'To edit profile:\n'
          '1. Go to Profile tab\n'
          '2. Tap Edit button\n'
          '3. Update information\n'
          '4. Save changes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: _faqList.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text(_faqList[index].question),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_faqList[index].answer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
