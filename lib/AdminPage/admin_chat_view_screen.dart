import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AdminChatViewScreen extends StatefulWidget {
  final String chatId;
  final String studentName;
  final String employeeName;
  final bool isAnonymous;

  const AdminChatViewScreen({
    Key? key,
    required this.chatId,
    required this.studentName,
    required this.employeeName,
    required this.isAnonymous,
  }) : super(key: key);

  @override
  _AdminChatViewScreenState createState() => _AdminChatViewScreenState();
}

class _AdminChatViewScreenState extends State<AdminChatViewScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _togglePlayback(String messageId, String audioUrl) async {
    if (_playingMessageId == messageId) {
      await _player.stopPlayer();
      setState(() => _playingMessageId = null);
    } else {
      if (_playingMessageId != null) {
        await _player.stopPlayer();
      }
      await _player.startPlayer(
        fromURI: audioUrl,
        whenFinished: () => setState(() => _playingMessageId = null),
      );
      setState(() => _playingMessageId = messageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAnonymous
            ? '${widget.studentName} (Anonymous) - ${widget.employeeName}'
            : '${widget.studentName} - ${widget.employeeName}'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages in this chat'));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index].data() as Map<String, dynamic>;
              final messageId = messages[index].id;
              final senderId = message['senderId'] ?? '';
              final isStudent = senderId.startsWith('S');
              final senderName = isStudent
                  ? (widget.isAnonymous ? widget.studentName : 'Student')
                  : widget.employeeName;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  crossAxisAlignment:
                  isStudent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isStudent ? Colors.grey[300] : AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isStudent ? Colors.black : Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (message['type'] == 'text')
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isStudent ? Colors.black : Colors.white,
                              ),
                            )
                          else if (message['type'] == 'audio')
                            ElevatedButton.icon(
                              icon: Icon(
                                _playingMessageId == messageId
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                _playingMessageId == messageId ? 'Pause' : 'Play',
                              ),
                              onPressed: () =>
                                  _togglePlayback(messageId, message['audioUrl']),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isStudent
                                    ? AppTheme.primaryRed
                                    : Colors.white,
                                backgroundColor: isStudent
                                    ? Colors.white
                                    : AppTheme.primaryRed,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatTimestamp(message['timestamp']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat.yMd().add_jm().format(timestamp.toDate());
  }
}

