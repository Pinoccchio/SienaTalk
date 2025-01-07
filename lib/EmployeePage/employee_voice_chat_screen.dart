import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class EmployeeVoiceChatScreen extends StatefulWidget {
  final String employeeId;
  final String chatPartnerId;
  final String chatPartnerName;

  const EmployeeVoiceChatScreen({
    Key? key,
    required this.employeeId,
    required this.chatPartnerId,
    required this.chatPartnerName,
  }) : super(key: key);

  @override
  _EmployeeVoiceChatScreenState createState() => _EmployeeVoiceChatScreenState();
}

class _EmployeeVoiceChatScreenState extends State<EmployeeVoiceChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _chatId;
  String _employeeName = 'Employee';
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isEditing = false;
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId(widget.employeeId, widget.chatPartnerId);
    _fetchEmployeeName();
    _initializeRecorder();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  void _fetchEmployeeName() async {
    try {
      DocumentSnapshot employeeSnapshot = await FirebaseFirestore.instance
          .collection('employees')
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

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_message.aac';
      await _recorder.startRecorder(toFile: _recordingPath);
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      _uploadVoiceMessage();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _uploadVoiceMessage() async {
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      final ref = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child('${DateTime.now().millisecondsSinceEpoch}.aac');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      _sendVoiceMessage(url);
    }
  }

  void _sendVoiceMessage(String url) {
    FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
      'audioUrl': url,
      'senderId': widget.employeeId,
      'senderName': _employeeName,
      'isAnonymous': false,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'audio',
    });
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _messageController.clear();
      if (_isEditing && _editingMessageId != null) {
        _updateMessage(_editingMessageId!, text);
      } else {
        _sendMessage(text);
      }
      _scrollToBottom();
    }
  }

  void _sendMessage(String text) {
    FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').add({
      'text': text,
      'senderId': widget.employeeId,
      'senderName': _employeeName,
      'isAnonymous': false,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });
  }

  void _updateMessage(String messageId, String newText) {
    FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').doc(messageId).update({
      'text': newText,
      'isEdited': true,
    });
    setState(() {
      _isEditing = false;
      _editingMessageId = null;
    });
  }

  void _deleteMessage(String messageId) {
    FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').doc(messageId).delete();
  }

  void _editMessage(String messageId, String currentText) {
    setState(() {
      _isEditing = true;
      _editingMessageId = messageId;
      _messageController.text = currentText;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              color: AppTheme.primaryRed,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: _isEditing ? 'Edit message...' : 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.send, color: Colors.white),
                onPressed: () => _handleSubmitted(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatPartnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        shape: const RoundedRectangleBorder(
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;
                    final isMe = message['senderId'] == widget.employeeId;
                    final previousMessage = index < messages.length - 1 ? messages[index + 1].data() as Map<String, dynamic> : null;
                    final showTimestamp = previousMessage == null ||
                        _shouldShowTimestamp(message['timestamp'], previousMessage['timestamp']);

                    return Column(
                      children: [
                        if (showTimestamp)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          player: _player,
                          onEdit: isMe ? () => _editMessage(messageId, message['text']) : null,
                          onDelete: isMe ? () => _deleteMessage(messageId) : null,
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

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final FlutterSoundPlayer player;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.player,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isPlaying = false;

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await widget.player.stopPlayer();
    } else {
      await widget.player.startPlayer(
        fromURI: widget.message['audioUrl'],
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: widget.isMe ? AppTheme.primaryRed : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message['isAnonymous'] ? 'Anonymous Student' : widget.message['senderName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            if (widget.message['type'] == 'text')
              Text(
                widget.message['text'],
                style: TextStyle(color: widget.isMe ? Colors.white : Colors.black87),
              )
            else if (widget.message['type'] == 'audio')
              ElevatedButton.icon(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? 'Pause' : 'Play'),
                onPressed: _togglePlayback,
                style: ElevatedButton.styleFrom(
                  foregroundColor: widget.isMe ? AppTheme.primaryRed : Colors.white,
                  backgroundColor: widget.isMe ? Colors.white : AppTheme.primaryRed,
                ),
              ),
            if (widget.isMe && widget.message['type'] == 'text')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: widget.onEdit,
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: widget.onDelete,
                    color: Colors.white,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

