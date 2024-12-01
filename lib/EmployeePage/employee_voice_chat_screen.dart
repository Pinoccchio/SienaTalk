import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';

class EmployeeVoiceChatScreen extends StatefulWidget {
  final String employeeId;
  final String chatPartnerId;
  final String chatPartnerName;

  EmployeeVoiceChatScreen({
    required this.employeeId,
    required this.chatPartnerId,
    required this.chatPartnerName,
  });

  @override
  _EmployeeVoiceChatScreenState createState() => _EmployeeVoiceChatScreenState();
}

class _EmployeeVoiceChatScreenState extends State<EmployeeVoiceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId(widget.employeeId, widget.chatPartnerId);
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _messageController.clear();
      FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
        'text': text,
        'senderId': widget.employeeId,
        'senderName': 'Employee',
        'isAnonymous': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Send a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: AppTheme.pureWhite),
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.chatPartnerName}'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ChatMessage(
                      text: message['text'],
                      isAnonymous: message['isAnonymous'],
                      sender: message['senderName'],
                      isEmployee: message['senderId'] == widget.employeeId,
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          _buildTextComposer(),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isAnonymous;
  final String sender;
  final bool isEmployee;

  ChatMessage({
    required this.text,
    required this.isAnonymous,
    required this.sender,
    required this.isEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: isEmployee ? 50.0 : 10.0),
      child: Row(
        mainAxisAlignment: isEmployee ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isEmployee && !isAnonymous) ...[
            CircleAvatar(
              backgroundColor: AppTheme.accentYellow,
              child: Text(
                sender[0].toUpperCase(),
                style: TextStyle(color: AppTheme.primaryRed),
              ),
            ),
            SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              decoration: BoxDecoration(
                color: isEmployee ? AppTheme.primaryRed : AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isEmployee ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous ? 'Anonymous' : sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEmployee ? AppTheme.pureWhite : AppTheme.primaryRed,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    text,
                    style: TextStyle(
                      color: isEmployee ? AppTheme.pureWhite : AppTheme.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
