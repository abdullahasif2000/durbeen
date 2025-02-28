import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'ComplaintHistory.dart';
import 'AddComplaintRemarks.dart';

class OwnComplaints extends StatefulWidget {
  const OwnComplaints({Key? key}) : super(key: key);

  @override
  _OwnComplaintsState createState() => _OwnComplaintsState();
}

class _OwnComplaintsState extends State<OwnComplaints> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;
  String? _email;
  String? _selectedStatus;
  final List<String> _statusOptions = ['InProcess', 'False', 'Resolved'];
  final Set<int> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _loadEmailAndFetchComplaints();
  }

  Future<void> _loadEmailAndFetchComplaints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('Email');

    if (_email != null) {
      await _fetchComplaints('InProcess');
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchComplaints(String status) async {
    setState(() {
      _isLoading = true;
    });

    ApiService apiService = ApiService();
    List<dynamic> complaints = await apiService.fetchOwnComplaints(
      email: _email!,
      status: status,
    );

    // Decode the complaint strings
    for (var complaint in complaints) {
      if (complaint['Complaint'] != null) {
        complaint['Complaint'] = Uri.decodeComponent(complaint['Complaint']);
      }
    }

    setState(() {
      _complaints = complaints;
      _isLoading = false;
    });
  }

  void _toggleCard(int index) {
    setState(() {
      if (_expandedCards.contains(index)) {
        _expandedCards.remove(index);
      } else {
        _expandedCards.add(index);
      }
    });
  }

  void _navigateToHistory(int complaintID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintHistory(complaintID: complaintID),
      ),
    );
  }

  void _onChallengeButtonPressed(String complaintID, String department) {
    final int? id = int.tryParse(complaintID);

    if (id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddComplaintRemarks(
            complaintID: id,
            isReadOnly: true,
            department: department, email: '', name: '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid complaint ID format')),
      );
    }
  }

  bool _canShowChallengeButton(String? resolveDate) {
    if (resolveDate == null || resolveDate.isEmpty) {
      print('ResolveDate is null or empty');
      return false;
    }

    try {

      final DateTime parsedResolveDate =
      DateFormat('dd-MMMM-yyyy h:mm a').parse(resolveDate);
      final DateTime today = DateTime.now();
      final Duration difference = today.difference(parsedResolveDate);

      print('Parsed ResolveDate: $parsedResolveDate, Today: $today, Difference in days: ${difference.inDays}');
      return difference.inDays.abs() <= 2;
    } catch (e) {
      print('Error parsing ResolveDate: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Own Complaints'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Select Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange[700]!),
                ),
              ),
              items: _statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStatus = newValue;
                });
                if (newValue != null) {
                  _fetchComplaints(newValue);
                }
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                ? Center(
              child: Text(
                'No complaints found.',
                style: TextStyle(fontSize: 24, color: Colors.grey[700]),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _complaints.length,
                itemBuilder: (context, index) {
                  final complaint = _complaints[index];
                  final isExpanded = _expandedCards.contains(index);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleCard(index),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${complaint['id'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Complainant ID: ${complaint['ComplainantID'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: Container(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                    'Entry Date', complaint['EntryDate']?.toString()),
                                _buildInfoRow('Resolve Date',
                                    complaint['ResolveDate']?.toString()),
                                _buildStatusRow(complaint['Status']?.toString()),
                                const Divider(),
                                _buildInfoRow(
                                    'Name', complaint['Name']?.toString()),
                                _buildInfoRow(
                                    'Email', complaint['Email']?.toString()),
                                _buildInfoRow(
                                    'Mobile', complaint['Mobile']?.toString()),
                                _buildInfoRow(
                                    'Request Type', complaint['RequestType']?.toString()),
                                _buildInfoRow(
                                    'Department', complaint['Department']?.toString()),
                                const SizedBox(height: 10),
                                Text(
                                  'Complaint:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaint['Complaint']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final complaintId = complaint['id'];
                                        if (complaintId != null) {
                                          final id = int.tryParse(complaintId.toString());
                                          if (id != null) {
                                            _navigateToHistory(id);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Invalid complaint ID format')),
                                            );
                                          }
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.history, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                            'View Complaint History',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (complaint['Status'] == 'Resolved' &&
                                        _canShowChallengeButton(complaint['ResolveDate']?.toString()))
                                      ElevatedButton(
                                        onPressed: () => _onChallengeButtonPressed(
                                          complaint['id'].toString(),
                                          complaint['Department']?.toString() ?? '',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[700],
                                        ),
                                        child: const Text('Challenge'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String? status) {
    Color statusColor = Colors.orange;
    if (status == 'Resolved') statusColor = Colors.green;
    if (status == 'False') statusColor = Colors.red;
    if (status == 'InProcess') statusColor = Colors.yellow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status ?? 'N/A',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
