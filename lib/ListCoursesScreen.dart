import 'package:flutter/material.dart';
import 'CreateSectionScreen.dart';

class ListCoursesScreen extends StatelessWidget {
  final String cohort;
  const ListCoursesScreen({required this.cohort, super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> courses = ["Math 101", "Physics 202", "Chemistry 303"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Courses for $cohort',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: ListView.builder(
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              courses[index],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSectionScreen(
                    cohort: cohort,
                    course: courses[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
