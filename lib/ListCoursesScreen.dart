import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
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
  final List<Map<String, dynamic>> _selectedCourses = [];

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
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 8.0, right: 8.0), // Space between AppBar and content
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
                  child: DataTable2(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[700]),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    columnSpacing: 1,
                    horizontalMargin: 5,
                    minWidth: 700,
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    columns: const [
                      DataColumn(label: Text('Sr. No')),
                      DataColumn(label: Text('Course Name')),
                      DataColumn(label: Text('Faculty')),
                    ],
                    rows: List.generate(
                      courses.length,
                          (index) {
                        final course = courses[index];
                        final isSelected = _selectedCourses.contains(course);

                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: (value) {
                            setState(() {
                              if (value == true) {
                                if (!_selectedCourses.contains(course)) {
                                  _selectedCourses.add(course);
                                }
                              } else {
                                _selectedCourses.remove(course);
                              }
                            });
                          },
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(course['Name'], maxLines: 1)),
                            DataCell(Text(course['FacultyName'], maxLines: 1)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (_selectedCourses.isNotEmpty) // Display Proceed button if courses are selected
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateSectionScreen(
                              cohort: widget.cohort,
                              selectedCourses: _selectedCourses, // Pass as List
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Proceed with Selected Courses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
