import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';

class VoiceChatScreen extends StatefulWidget {
  final String studentId;
  final String chatPartnerId;
  final String chatPartnerName;

  VoiceChatScreen({
    required this.studentId,
    required this.chatPartnerId,
    required this.chatPartnerName,
  });

  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isAnonymous = false;
  late String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId(widget.studentId, widget.chatPartnerId);
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort(); // Correctly sorts the IDs.
    return sortedIds.join('_'); // Joins the sorted IDs with an underscore.
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _messageController.clear();
      FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
        'text': text,
        'senderId': widget.studentId,
        'senderName': _isAnonymous ? 'Anonymous' : 'Student',
        'isAnonymous': _isAnonymous,
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
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                hintStyle: TextStyle(color: Colors.grey[600]),
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Text(
                  _isAnonymous ? 'Anonymous' : 'Normal',
                  style: TextStyle(color: AppTheme.pureWhite),
                ),
                Switch(
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                  activeColor: AppTheme.accentYellow,
                ),
              ],
            ),
          ),
        ],
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
                      isStudent: message['senderId'] == widget.studentId,
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
  final bool isStudent;

  ChatMessage({
    required this.text,
    required this.isAnonymous,
    required this.sender,
    required this.isStudent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: isStudent ? 50.0 : 10.0),
      child: Row(
        mainAxisAlignment: isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isStudent && !isAnonymous) ...[
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
                color: isStudent ? AppTheme.primaryRed : AppTheme.accentYellow,
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
                crossAxisAlignment: isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous ? 'Anonymous' : sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isStudent ? AppTheme.pureWhite : AppTheme.primaryRed,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    text,
                    style: TextStyle(
                      color: isStudent ? AppTheme.pureWhite : AppTheme.primaryRed,
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
