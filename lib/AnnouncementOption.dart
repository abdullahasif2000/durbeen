import 'package:flutter/material.dart';
import 'CreateAnnouncementScreen.dart';
import 'ViewAnnouncementScreen.dart';

class AnnouncementOptions extends StatelessWidget {
  const AnnouncementOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Options'),
        backgroundColor: Colors.orange[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Announcement Options',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAnnouncementScreen(),
                  ),
                );
              },
              child: const Text('Create Announcement'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewAnnouncementScreen(),
                  ),
                );
              },
              child: const Text('View Announcements'),
            ),
          ],
        ),
      ),
    );
  }
}