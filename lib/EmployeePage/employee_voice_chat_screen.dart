import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
  late String _chatId;
  String _employeeName = 'Employee'; // Default to 'Employee' until data is loaded

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId(widget.employeeId, widget.chatPartnerId);
    _fetchEmployeeName(); // Fetch the employee's name
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  void _fetchEmployeeName() async {
    try {
      // Fetch the employee's name from Firestore using the employeeId
      DocumentSnapshot employeeSnapshot = await FirebaseFirestore.instance
          .collection('employees') // Assuming the employee data is stored in the 'employees' collection
          .doc(widget.employeeId)
          .get();

      if (employeeSnapshot.exists) {
        final employeeData = employeeSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _employeeName = '${employeeData['firstName']} ${employeeData['lastName']}';
        });
      }
    } catch (e) {
      print('Error fetching employee name: $e');
    }
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _messageController.clear();
      FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
        'text': text,
        'senderId': widget.employeeId,
        'senderName': _employeeName, // Use the actual employee name
        'isAnonymous': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
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
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
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
        title: Text(widget.chatPartnerName, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet', style: TextStyle(color: AppTheme.primaryRed)));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == widget.employeeId;
                    final previousMessage = index < messages.length - 1 ? messages[index + 1].data() as Map<String, dynamic> : null;
                    final showTimestamp = previousMessage == null ||
                        _shouldShowTimestamp(message['timestamp'], previousMessage['timestamp']);

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        ChatBubble(
                          clipper: ChatBubbleClipper6(
                            nipSize: 0,
                            radius: 16,
                            type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
                          ),
                          alignment: isMe ? Alignment.topRight : Alignment.topLeft,
                          margin: EdgeInsets.only(top: 10),
                          backGroundColor: isMe ? AppTheme.primaryRed : AppTheme.accentYellow,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['isAnonymous'] ? 'Anonymous Student' : message['senderName'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white : AppTheme.primaryRed,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  message['text'],
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(Timestamp? current, Timestamp? previous) {
    if (current == null || previous == null) return true;
    final currentDate = current.toDate();
    final previousDate = previous.toDate();
    return currentDate.difference(previousDate).inMinutes >= 30;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today ${DateFormat.jm().format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat.yMMMd().add_jm().format(date);
    }
  }
}
