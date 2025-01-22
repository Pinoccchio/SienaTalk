import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:sienatalk/theme/app_theme.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final FlutterSoundPlayer player;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String senderName;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.player,
    this.onEdit,
    this.onDelete,
    required this.senderName,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isPlaying = false;

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await widget.player.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await widget.player.startPlayer(
        fromURI: widget.message['audioUrl'],
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    }
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
              widget.senderName,
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

