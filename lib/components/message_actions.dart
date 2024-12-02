import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';

class MessageActions extends StatelessWidget {
  final String messageId;
  final String chatId;
  final bool isEmployee;
  final String currentText;

  MessageActions({
    required this.messageId,
    required this.chatId,
    required this.isEmployee,
    required this.currentText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Message Actions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEmployee)
            ListTile(
              leading: Icon(Icons.mark_chat_read),
              title: Text('Mark as Read'),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .doc(messageId)
                    .update({'isRead': true});
                Navigator.of(context).pop();
              },
            ),
          if (isEmployee)
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Message'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditDialog(context);
              },
            ),
          if (isEmployee)
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Message'),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .doc(messageId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController _editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Message'),
        content: TextField(
          controller: _editController,
          decoration: InputDecoration(
            hintText: 'Enter new message',
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .doc(messageId)
                  .update({'text': _editController.text});
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

