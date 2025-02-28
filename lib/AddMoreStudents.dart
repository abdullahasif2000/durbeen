import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'api_service.dart';
import 'package:data_table_2/data_table_2.dart';

class AddMoreStudents extends StatefulWidget {
  final String sectionID;
  final String courseID;
  final String cohort;

  const AddMoreStudents({
    Key? key,
    required this.sectionID,
    required this.courseID,
    required this.cohort,
  }) : super(key: key);

  @override
  _AddMoreStudentsState createState() => _AddMoreStudentsState();
}

class _AddMoreStudentsState extends State<AddMoreStudents> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> mappedStudents = [];
  String? sessionID;
  bool isLoading = true;
  List<String> selectedRollNumbers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    sessionID = prefs.getString('SessionID') ?? '';
    if (sessionID!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SessionID is not available')),
      );
      return;
    }

    await _fetchStudents();
    await _fetchMappedStudents();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents =
      await ApiService().fetchStudentsByCohort(widget.cohort);
      setState(() {
        students = fetchedStudents;
      });
    } catch (e) {
      print('Error fetching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch students')),
      );
    }
  }

  Future<void> _fetchMappedStudents() async {
    if (sessionID == null || sessionID!.isEmpty) return;

    try {
      final fetchedMappedStudents = await ApiService().fetchMappedStudents(
        SessionID: sessionID!,
        CourseID: widget.courseID,
        SectionID: widget.sectionID,
      );
      setState(() {
        mappedStudents = fetchedMappedStudents;
      });
    } catch (e) {
      print('Error fetching mapped students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch mapped students')),
      );
    }
  }

  Future<void> _addStudents() async {
    for (String rollNumber in selectedRollNumbers) {
      // Check for duplicates
      bool isDuplicate = mappedStudents.any((student) => student['RollNumber'] == rollNumber);
      if (isDuplicate) {
        // Show alert for duplicate
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Duplicate Student'),
              content: Text('Student with Roll Number $rollNumber is already added.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        continue;
      }

      // Call the API to add the student
      try {
        bool success = await ApiService().addStudentToSection(
          sessionID: sessionID!,
          courseID: widget.courseID,
          sectionID: widget.sectionID,
          rollNumber: rollNumber,
        );

        if (success) {
          print('Successfully added student: $rollNumber');
        } else {
          print('Failed to add student: $rollNumber');
        }
      } catch (e) {
        print('Error adding student: $e');
      }
    }

    // Refresh the mapped students list after adding
    await _fetchMappedStudents();
    setState(() {
      selectedRollNumbers.clear();
    });
  }

  Future<void> _removeStudent(String rollNumber) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove student with Roll Number $rollNumber?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        bool success = await ApiService().removeStudentFromSection(
          rollNumber: rollNumber,
          sessionID: sessionID!,
          courseID: widget.courseID,
        );

        if (success) {
          print('Successfully removed student: $rollNumber');
          // Refresh the mapped students list after removing
          await _fetchMappedStudents();
        } else {
          print('Failed to remove student: $rollNumber');
        }
      } catch (e) {
        print('Error removing student: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add More Students'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adding students to Section ID: ${widget.sectionID}, Course ID: ${widget.courseID}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              MultiSelectDialogField(
                items: students.map((student) {
                  return MultiSelectItem(
                    student['RollNumber'],
                    '${student['RollNumber']} - ${student['Name']}',
                  );
                }).toList(),
                title: const Text("Select Students"),
                selectedColor: Colors.orange,
                buttonText: const Text("Select Students"),
                onConfirm: (values) {
                  setState(() {
                    selectedRollNumbers = List<String>.from(values);
                  });
                },
                searchable: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addStudents,
                child: const Text('Add Selected Students'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mapped Students:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 800,
                        columns: const [
                          DataColumn(label: Text('Roll Number')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Session ID')),
                          DataColumn(label: Text('Course ID')),
                          DataColumn(label: Text('Section ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: mappedStudents.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(Text(student['RollNumber'] ?? '-')),
                              DataCell(Text(student['Name'] ?? '-')),
                              DataCell(Text(student['SessionID'] ?? '-')),
                              DataCell(Text(student['CourseID'] ?? '-')),
                              DataCell(Text(student['SectionID'] ?? '-')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeStudent(student['RollNumber']),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}