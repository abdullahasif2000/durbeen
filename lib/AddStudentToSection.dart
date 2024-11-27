import 'package:flutter/material.dart';
import 'api_service.dart'; // Import your ApiService class

class AddStudentToSection extends StatefulWidget {
  final String cohort;
  final List<Map<String, dynamic>> selectedCourses;

  const AddStudentToSection({
    required this.cohort,
    required this.selectedCourses,
    super.key,
  });

  @override
  _AddStudentToSectionState createState() => _AddStudentToSectionState();
}

class _AddStudentToSectionState extends State<AddStudentToSection> {
  String? selectedRollNumber;
  List<Map<String, dynamic>> studentData = [];
  List<String> addedStudents = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<dynamic> data = await ApiService().fetchStudentsByCohort(widget.cohort);

      setState(() {
        studentData = data.map((student) {
          return {
            'roll_number': student['RollNumber'],
            'name': student['Name'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching students: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Students to Section',
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
              const Text(
                'Select a student to add to the section:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: selectedRollNumber,
                  decoration: const InputDecoration(
                    labelText: 'Select student',
                    border: OutlineInputBorder(),
                  ),
                  items: studentData.map((student) {
                    return DropdownMenuItem<String>(
                      value: student['roll_number'],
                      child: Text(
                        '${student['roll_number']} - ${student['name']}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRollNumber = value;
                    });
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedRollNumber != null) {
                    setState(() {
                      addedStudents.add(selectedRollNumber!);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Student added: $selectedRollNumber')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a student')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add Student',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, addedStudents);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
