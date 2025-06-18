import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:pratiksha/dropbox_service.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';


class DogsRecordsPage extends StatefulWidget {
  @override
  _DogsRecordsPageState createState() => _DogsRecordsPageState();
}

class _DogsRecordsPageState extends State<DogsRecordsPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _listenToFirestoreUpdates();
  }

  void _listenToFirestoreUpdates() {
    _firestore.collection('dogs_records').orderBy(FieldPath.documentId).snapshots().listen((snapshot) {
      setState(() {
        try {
          _rows = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'Serial No': doc.id,
              'Unique ID Name': data['Unique ID Name'] ?? '',
              'Photo': data['Photo'] ?? '',
              'Breed': data['Breed'] ?? '',
              'Gender': data['Gender'] ?? '',
              'Age': data['Age'] ?? '',
              'Pickup Address': data['Pickup Address'] ?? '',
              'Pickup Date': (data['Pickup Date'] is Timestamp)
                  ? (data['Pickup Date'] as Timestamp).toDate()
                  : null,
              'Drop Address': data['Drop Address'] ?? '',
              'Drop Date': (data['Drop Date'] is Timestamp)
                  ? (data['Drop Date'] as Timestamp).toDate()
                  : null,
              'Medical Records': data['Medical Records'] ?? '',
              'Current Medical Status': data['Current Medical Status'] ?? '',
            };
          }).toList();
        } catch (e) {
          print('Error parsing Firestore data: $e');
        }
      });
    });
  }


  Future<void> _pickImage(int index) async {
    try {
      final row = _rows[index];
      // Check if there is an existing image URL in Firestore
      final existingPhotoUrl = row['Photo'];

      // If there is an existing photo, you can ask the user to confirm deletion
      if (existingPhotoUrl != null && existingPhotoUrl.isNotEmpty) {
        final confirmDelete = await _showDeleteDialog();
        if (!confirmDelete) return;
        await _deleteFileFromFirestore(index, 'Photo');

      }

      // Proceed with picking and uploading the new image
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(child: CircularProgressIndicator()),
        );

        final dropboxService = DropboxService();
        final uploadedUrl = await dropboxService.uploadFile(file.path, '/${path.basename(file.path)}');

        Navigator.of(context).pop();
        if (uploadedUrl != null) {
          await _updateFirestoreData(index, 'Photo', uploadedUrl);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File?'),
        content: Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
  }


  Future<void> _pickMedicalRecord(int index) async {
    try {
      final row = _rows[index];
      // Check if there is an existing medical record
      final existingRecordUrl = row['Medical Records'];

      // If there is an existing medical record, prompt for deletion
      if (existingRecordUrl != null && existingRecordUrl.isNotEmpty) {
        final confirmDelete = await _showDeleteDialog();
        if (!confirmDelete) return; // User canceled the deletion
        await _deleteFileFromFirestore(index, 'Medical Records');
      }

      // Proceed with picking and uploading the new medical record
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['pdf'], // Restrict to PDF files only
        type: FileType.custom,
      );

      if (result != null) {
        final file = File(result.files.single.path!);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(child: CircularProgressIndicator()),
        );

        final dropboxService = DropboxService();
        final uploadedUrl = await dropboxService.uploadFile(file.path, '/medical_records/${path.basename(file.path)}');

        Navigator.of(context).pop();

        if (uploadedUrl != null) {
          await _updateFirestoreData(index, 'Medical Records', uploadedUrl);
        }
      } else {
        // If the user didn't pick a file, show a tooltip
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only PDF files are allowed.')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openMedicalRecord(int index) async {
    try {
      final row = _rows[index];
      final medicalRecordUrl = row['Medical Records'];

      if (medicalRecordUrl == null || medicalRecordUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No medical record available.'))
        );
        return;
      }

      // Set local path
      String localPath = '/storage/emulated/0/Download/${path.basename(medicalRecordUrl)}';

      // Download the file if it doesn't already exist
      final file = File(localPath);
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(medicalRecordUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download file. HTTP Status: ${response.statusCode}');
        }
      }

      // Guess and append file extension if missing
      if (path.extension(localPath).isEmpty) {
        final guessedExtension = '.pdf'; // Change this based on expected file type
        final updatedPath = '$localPath$guessedExtension';
        await file.rename(updatedPath);
        localPath = updatedPath;
      }

      // Open the file
      final result = await OpenFile.open(localPath);
      if (result.type != ResultType.done) {
        throw Exception('Unable to open file: ${result.message}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
      );
    }
  }


  Future<void> _deleteFileFromFirestore(int index, String field) async {
    try {
      final row = _rows[index];
      await _firestore.collection('dogs_records').doc(row['Serial No']).update({
        field: '', // Set the field to an empty string to remove the file URL
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove file reference from Firestore: $e')),
      );
    }
  }




  Future<void> _updateFirestoreData(int index, String field, dynamic value) async {
    try {
      final row = _rows[index];
      await _firestore.collection('dogs_records').doc(row['Serial No']).update({
        field: value,
      });
    } catch (e) {
      print('Error updating Firestore data: $e');
    }
  }



  void _showDogRecordDialog({Map<String, dynamic>? record}) {
    final isEditing = record != null;
    final TextEditingController uniqueIdController = TextEditingController(text: record?['Unique ID Name'] ?? '');
    final TextEditingController breedController = TextEditingController(text: record?['Breed'] ?? '');
    final TextEditingController genderController = TextEditingController(text: record?['Gender'] ?? '');
    final TextEditingController ageController = TextEditingController(text: record?['Age'] ?? '');
    final TextEditingController pickupAddressController = TextEditingController(text: record?['Pickup Address'] ?? '');
    final TextEditingController dropAddressController = TextEditingController(text: record?['Drop Address'] ?? '');
    final TextEditingController statusController = TextEditingController(text: record?['Current Medical Status'] ?? '');

    DateTime? pickupDate;
    DateTime? dropDate;

    // Safely convert Timestamp to DateTime or null if it's not a Timestamp
    if (record?['Pickup Date'] is Timestamp) {
      pickupDate = (record?['Pickup Date'] as Timestamp).toDate();
    }
    if (record?['Drop Date'] is Timestamp) {
      dropDate = (record?['Drop Date'] as Timestamp).toDate();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Record' : 'Add New Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: uniqueIdController, decoration: const InputDecoration(labelText: 'Unique ID Name')),
                    TextField(controller: breedController, decoration: const InputDecoration(labelText: 'Breed')),
                    TextField(controller: genderController, decoration: const InputDecoration(labelText: 'Gender')),
                    TextField(controller: ageController, decoration: const InputDecoration(labelText: 'Age')),
                    TextField(controller: pickupAddressController, decoration: const InputDecoration(labelText: 'Pickup Address')),
                    TextField(controller: dropAddressController, decoration: const InputDecoration(labelText: 'Drop Address')),
                    TextField(controller: statusController, decoration: const InputDecoration(labelText: 'Medical Status')),
                    const SizedBox(height: 16),
                    // Pickup Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pickup Date: ${pickupDate != null ? DateFormat('yyyy-MM-dd').format(pickupDate!) : 'Not Set'}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: pickupDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                pickupDate = picked; // Update the selected pickup date
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    // Drop Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Drop Date: ${dropDate != null ? DateFormat('yyyy-MM-dd').format(dropDate!) : 'Not Set'}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dropDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dropDate = picked; // Update the selected drop date
                              });
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    // Display Selected Date
                    if (pickupDate != null)
                      Text('Selected Pickup Date: ${DateFormat('yyyy-MM-dd').format(pickupDate!)}'),
                    if (dropDate != null)
                      Text('Selected Drop Date: ${DateFormat('yyyy-MM-dd').format(dropDate!)}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final newRecord = {
                      'Unique ID Name': uniqueIdController.text.trim(),
                      'Breed': breedController.text.trim(),
                      'Gender': genderController.text.trim(),
                      'Age': ageController.text.trim(),
                      'Pickup Address': pickupAddressController.text.trim(),
                      // Convert DateTime to Timestamp for Firestore
                      'Pickup Date': pickupDate != null ? Timestamp.fromDate(pickupDate!) : null,
                      'Drop Address': dropAddressController.text.trim(),
                      // Convert DateTime to Timestamp for Firestore
                      'Drop Date': dropDate != null ? Timestamp.fromDate(dropDate!) : null,
                      'Current Medical Status': statusController.text.trim(),
                    };

                    try {
                      if (isEditing) {
                        // Update the existing record in Firestore
                        await FirebaseFirestore.instance
                            .collection('dogs_records')
                            .doc(record!['Serial No']) // Use the same Serial No (document ID)
                            .update(newRecord);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Record updated successfully!')),
                        );
                      } else {
                        // Add a new record to Firestore
                        final snapshot = await FirebaseFirestore.instance.collection('dogs_records').get();
                        final documentIds = snapshot.docs.map((doc) => int.tryParse(doc.id) ?? 0).toList();
                        final nextSerialNo = (documentIds.isEmpty ? 0 : documentIds.reduce((a, b) => a > b ? a : b)) + 1;

                        await FirebaseFirestore.instance.collection('dogs_records').doc(nextSerialNo.toString()).set(newRecord);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Record added successfully!')),
                        );
                      }

                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Error saving record: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving record: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _deleteRow(int index) async {
    try {
      final row = _rows[index];

      // Show a confirmation dialog before deleting
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Are you sure you want to delete this record?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // User cancels
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // User confirms
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      // If the user confirmed, proceed with deletion
      if (shouldDelete == true) {
        await _firestore.collection('dogs_records').doc(row['Serial No']).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted successfully!')),
        );
      }
    } catch (e) {
      print('Error deleting record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dogs Records')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Serial No')),
                  DataColumn(label: Text('Unique ID Name')),
                  DataColumn(label: Text('Photo')),
                  DataColumn(label: Text('Breed')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('Age')),
                  DataColumn(label: Text('Pickup Address')),
                  DataColumn(label: Text('Pickup Date')),
                  DataColumn(label: Text('Drop Address')),
                  DataColumn(label: Text('Drop Date')),
                  DataColumn(label: Text('Medical Records (only pdf)')),
                  DataColumn(label: Text('Current Medical Status')),
                  DataColumn(label: Text('Edit')),
                  DataColumn(label: Text('Delete')),
                ],
                rows: _rows.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['Serial No'])),
                    DataCell(Text(row['Unique ID Name'])),
                    DataCell(
                      row['Photo'] != null && row['Photo'].isNotEmpty
                          ? Row(
                        children: [
                          Image.network(
                            row['Photo'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final confirmDelete = await _showDeleteDialog();
                              if (confirmDelete) {
                                await _deleteFileFromFirestore(_rows.indexOf(row), 'Photo');
                                setState(() {
                                  // Optionally clear the image URL in the UI
                                  row['Photo'] = '';
                                });
                              }
                            },
                          )
                        ],
                      )
                          : Icon(Icons.image_rounded),
                      onTap: () => _pickImage(_rows.indexOf(row)),
                    ),
                    DataCell(Text(row['Breed'])),
                    DataCell(Text(row['Gender'])),
                    DataCell(Text(row['Age'])),
                    DataCell(Text(row['Pickup Address'])),
                    DataCell(Text(row['Pickup Date'] != null
                        ? DateFormat('yyyy-MM-dd').format(row['Pickup Date'])
                        : 'Not Set')),
                    DataCell(Text(row['Drop Address'])),
                    DataCell(Text(row['Drop Date'] != null
                        ? DateFormat('yyyy-MM-dd').format(row['Drop Date'])
                        : 'Not Set')),
                    DataCell(
                      row['Medical Records'] != null && row['Medical Records'].isNotEmpty
                          ? Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              try {
                                final fileUrl = row['Medical Records'];
                                final localPath = '/storage/emulated/0/Download/${path.basename(fileUrl)}';
                                final downloadedFile = File(localPath);

                                // Check if file exists locally; if not, download it
                                if (!await downloadedFile.exists()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Downloading file...')),
                                  );
                                  final response = await http.get(Uri.parse(fileUrl));

                                  // Ensure the HTTP request is successful
                                  if (response.statusCode == 200) {
                                    await downloadedFile.writeAsBytes(response.bodyBytes);
                                  } else {
                                    throw Exception('Failed to download file: ${response.statusCode}');
                                  }
                                }
                                // Open the file after download
                                await _openMedicalRecord(_rows.indexOf(row)); // Pass the index
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            },
                            child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final confirmDelete = await _showDeleteDialog();
                              if (confirmDelete) {
                                // Delete the file reference from Firestore
                                await _deleteFileFromFirestore(_rows.indexOf(row), 'Medical Records');
                                setState(() {
                                  row['Medical Records'] = ''; // Clear the file URL in the UI
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Medical record deleted successfully!')),
                                );
                              }
                            },
                          ),
                        ],
                      )
                          : Icon(Icons.file_upload),
                      onTap: () => _pickMedicalRecord(_rows.indexOf(row)),
                    ),
                    DataCell(Text(row['Current Medical Status'])),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showDogRecordDialog(record:row);
                        },
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteRow(_rows.indexOf(row)), // Pass the index of the row
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDogRecordDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
