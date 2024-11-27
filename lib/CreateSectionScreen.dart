import 'package:flutter/material.dart';
import 'AddStudentToSection.dart';
import 'api_service.dart';

class CreateSectionScreen extends StatefulWidget {
  final String cohort;
  final List<Map<String, dynamic>> selectedCourses;

  const CreateSectionScreen({
    required this.cohort,
    required this.selectedCourses,
    super.key,
  });

  @override
  _CreateSectionScreenState createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final TextEditingController sectionController = TextEditingController();
  List<String> studentRollNumbers = [];
  bool isSectionCreated = false;

  void createSection() {
    String section = sectionController.text.trim();

    if (section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name is required')),
      );
      return;
    }

    setState(() {
      isSectionCreated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Section "$section" created!')),
    );
  }

  // Navigate to AddStudentToSection and update student list after adding students
  void addStudents() async {
    final updatedRollNumbers = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentToSection(
          cohort: widget.cohort,
          selectedCourses: widget.selectedCourses,
        ),
      ),
    );

    if (updatedRollNumbers != null) {
      setState(() {
        studentRollNumbers = updatedRollNumbers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: TextEditingController(text: widget.cohort),
                decoration: const InputDecoration(
                  labelText: 'Cohort',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
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
              Center(
                child: ElevatedButton(
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
              ),
              const SizedBox(height: 20),
              if (isSectionCreated) ...[
                // Button to navigate to AddStudentToSection
                Center(
                  child: ElevatedButton(
                    onPressed: addStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add Students to Section',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Table Layout for displaying the Section Details
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    // Header Row for Cohort, Section Name, and Selected Courses
                    TableRow(
                      decoration: BoxDecoration(color: Colors.orange[50]),
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Cohort: ${widget.cohort}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Section: ${sectionController.text}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Selected Courses:'),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.selectedCourses.map((course) {
                                return Text('- ${course['Name']} (Faculty: ${course['FacultyName']})');
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Empty Row
                    TableRow(children: [SizedBox(), SizedBox()]),
                  ],
                ),

                const SizedBox(height: 20),

                // Student Roll Numbers Table
                if (studentRollNumbers.isNotEmpty) ...[
                  const Text(
                    'Added Students:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(),
                    children: studentRollNumbers.map((rollNumber) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(rollNumber),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
