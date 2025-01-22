import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'message_bubble.dart';

class EmployeeVoiceChatScreen extends StatefulWidget {
  final String employeeId;
  final String chatPartnerId;
  final String chatPartnerName;
  final bool isAnonymousChat;

  const EmployeeVoiceChatScreen({
    Key? key,
    required this.employeeId,
    required this.chatPartnerId,
    required this.chatPartnerName,
    required this.isAnonymousChat,
  }) : super(key: key);

  @override
  _EmployeeVoiceChatScreenState createState() => _EmployeeVoiceChatScreenState();
}

class _EmployeeVoiceChatScreenState extends State<EmployeeVoiceChatScreen> with TickerProviderStateMixin {
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
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _setupChatId();
    _fetchEmployeeName();
    _initializeRecorder();
    _lottieController = AnimationController(vsync: this);
  }

  void _setupChatId() {
    final sortedIds = [widget.employeeId, widget.chatPartnerId]..sort();
    _chatId = widget.isAnonymousChat
        ? 'anonymous_${sortedIds.join('_')}'
        : sortedIds.join('_');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    _lottieController.dispose();
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
      _lottieController.repeat();
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
      _lottieController.stop();
      await _uploadVoiceMessage();
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _uploadVoiceMessage() async {
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        final ref = FirebaseStorage.instance
            .ref()
            .child('voice_messages')
            .child('${DateTime.now().millisecondsSinceEpoch}.aac');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        _sendVoiceMessage(url);
      } catch (e) {
        print('Error uploading voice message: $e');
      }
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

  void _deleteMessage(String messageId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unsend Message'),
          content: Text('Are you sure you want to unsend this message? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Unsend'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
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
          0,
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
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 40,
                height: 40,
                child: _isRecording
                    ? Lottie.asset(
                  'assets/anim/recording-anim.json',
                  controller: _lottieController,
                  onLoaded: (composition) {
                    _lottieController.duration = composition.duration;
                  },
                )
                    : Icon(Icons.mic, color: AppTheme.primaryRed),
              ),
            ),
            SizedBox(width: 8),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatPartnerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.isAnonymousChat ? 'Anonymous Chat' : 'Regular Chat',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
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

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
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
                    final previousMessage = index < messages.length - 1
                        ? messages[index + 1].data() as Map<String, dynamic>
                        : null;
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
                          senderName: message['senderName'],
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

