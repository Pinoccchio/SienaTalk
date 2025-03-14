import 'package:flutter/material.dart';

class VoiceMessages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Messages'),
      ),
      body: ListView.builder(
        itemCount: 5, // Replace with actual message count
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('Voice Message ${index + 1}'),
              subtitle: Text('From: John Doe • Duration: 0:30'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      // TODO: Implement voice message playback
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.reply),
                    onPressed: () {
                      // TODO: Implement voice message reply
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.mic),
        onPressed: () {
          // TODO: Implement voice recording
        },
        tooltip: 'Record Voice Message',
      ),
    );
  }
}

