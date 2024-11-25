import 'package:flutter/material.dart';
import 'api_service.dart';
import 'ListCoursesScreen.dart';

class SelectCohortScreen extends StatefulWidget {
  const SelectCohortScreen({Key? key}) : super(key: key);

  @override
  _SelectCohortScreenState createState() => _SelectCohortScreenState();
}

class _SelectCohortScreenState extends State<SelectCohortScreen> {
  late Future<List<String>> _cohortsFuture;
  String? _selectedCohort; // To hold the currently selected cohort

  @override
  void initState() {
    super.initState();
    _cohortsFuture = fetchCohorts();
  }

  Future<List<String>> fetchCohorts() async {
    try {
      final response = await ApiService().fetchCohorts();
      // Extract only the cohort year and convert to a list of strings
      return response.map<String>((cohort) => cohort['cohort'].toString()).toList();
    } catch (e) {
      throw Exception("Failed to load cohorts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Cohort',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _cohortsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No cohorts available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          } else {
            final cohorts = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Select a Cohort:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _selectedCohort,
                    hint: const Text(
                      'Choose Cohort',
                      style: TextStyle(fontSize: 16),
                    ),
                    items: cohorts.map((cohort) {
                      return DropdownMenuItem<String>(
                        value: cohort,
                        child: Text(
                          cohort,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCohort = value;
                      });
                    },
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          onPressed: _selectedCohort == null
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListCoursesScreen(cohort: _selectedCohort!),
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
