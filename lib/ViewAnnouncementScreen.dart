import 'package:flutter/material.dart';

class ViewAnnouncementScreen extends StatelessWidget {
  const ViewAnnouncementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Announcements'),
        backgroundColor: Colors.orange[700],
      ),
      body: Center(
        child: const Text(
          'List of Announcements',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}