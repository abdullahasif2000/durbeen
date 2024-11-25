import 'package:flutter/material.dart';
import 'api_service.dart';
import 'CreateSectionScreen.dart';

class ListCoursesScreen extends StatefulWidget {
  final String cohort;

  const ListCoursesScreen({required this.cohort, super.key});

  @override
  _ListCoursesScreenState createState() => _ListCoursesScreenState();
}

class _ListCoursesScreenState extends State<ListCoursesScreen> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;
  Map<String, dynamic>? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _coursesFuture = ApiService().fetchCourses(widget.cohort); // Fetch courses based on cohort
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Courses for ${widget.cohort}',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses found for this cohort.'));
          }

          final courses = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Allow horizontal scrolling for wide tables
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Course Name')),
                      DataColumn(label: Text('Faculty')),

                    ],
                    rows: courses.map((course) {
                      return DataRow(
                        selected: _selectedCourse == course,
                        onSelectChanged: (isSelected) {
                          setState(() {
                            _selectedCourse = isSelected == true ? course : null;
                          });
                        },
                        cells: [
                          DataCell(Text(course['Name'])),
                          DataCell(Text(course['FacultyName'])),

                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_selectedCourse != null) // Display "Proceed" button if a course is selected
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateSectionScreen(
                            cohort: widget.cohort,
                            course: _selectedCourse!['Name'],
                          ),
                        ),
                      );
                    },
                    child: const Text('Proceed with Selected Course'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
