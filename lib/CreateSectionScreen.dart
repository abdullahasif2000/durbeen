import 'package:flutter/material.dart';

class CreateSectionScreen extends StatelessWidget {
  final String cohort;
  final String course;
  const CreateSectionScreen({required this.cohort, required this.course, super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController sectionController = TextEditingController();

    void createSection() {
      String section = sectionController.text.trim();

      if (section.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section name cannot be empty')),
        );
        return;
      }

      // Debugging: Print the cohort, course, and section details
      print("Cohort: $cohort, Course: $course, Section: $section");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Section "$section" created successfully!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Section',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Cohort: $cohort\nCourse: $course',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: sectionController,
              decoration: const InputDecoration(
                labelText: 'Section Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createSection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Create Section',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
