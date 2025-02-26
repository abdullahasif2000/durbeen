import 'package:flutter/material.dart';

class CreateAnnouncementScreen extends StatelessWidget {
  const CreateAnnouncementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: Colors.orange[700],
      ),
      body: Center(
        child: const Text(
          'Create Announcement',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}