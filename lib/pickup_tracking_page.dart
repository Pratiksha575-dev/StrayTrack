import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dropbox_service.dart'; // Your Dropbox service implementation

class PickupTrackingPage extends StatefulWidget {
  const PickupTrackingPage({super.key});

  @override
  _PickupTrackingPageState createState() => _PickupTrackingPageState();
}

class _PickupTrackingPageState extends State<PickupTrackingPage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DropboxService _dropboxService = DropboxService();

  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _listenToFirestoreUpdates();
  }

  void _listenToFirestoreUpdates() {
    _firestore
        .collection('pickupTracking')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _rows = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return {
            'Serial No': doc.id,
            'Unique ID': data['Unique ID'] ?? '',
            'Dog\'s Photo': data['Dog\'s Photo'] ?? '',
            'Latest Pickup Address': data['Latest Pickup Address'] ?? '',
            'Latest Pickup Date': (data['Latest Pickup Date'] as Timestamp?)?.toDate(),
            'Latest Drop Address': data['Latest Drop Address'] ?? '',
            'Latest Drop Date': (data['Latest Drop Date']as Timestamp?)?.toDate(),
            'Purpose of Pickup': data['Purpose of Pickup'] ?? '',
            'Name of ABC Centre': data['Name of ABC Centre'] ?? '',
            'Driver Name': data['Driver Name'] ?? '',
            'Vehicle Number': data['Vehicle Number'] ?? '',
          };
        }).toList();
      });
    });
  }

  Future<void> _pickImageAndUploadToDropbox(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final dropboxPath = '/pickuptracking/${pickedFile.name}';

      try {
        final dropboxLink =
        await _dropboxService.uploadFile(imageFile.path, dropboxPath);

        if (dropboxLink != null) {
          final documentId = _rows[index]['Serial No'];
          await _firestore.collection('pickupTracking').doc(documentId).update({
            'Dog\'s Photo': dropboxLink,
          });

          setState(() {
            _rows[index]['Dog\'s Photo'] = dropboxLink;
          });
        }
      } catch (e) {
        print('Error uploading to Dropbox: $e');
      }
    }
  }

  Future<bool> _showDeleteDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteFileFromFirestore(int index, String field) async {
    try {
      final row = _rows[index];
      await _firestore.collection('pickupTracking').doc(row['Serial No']).update({
        field: '',
      });
      setState(() {
        _rows[index][field] = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove file reference from Firestore: $e')),
      );
    }
  }

  void _showRecordDialog({Map<String, dynamic>? record}) {
    final isEditing = record != null;
    final TextEditingController uniqueIdController =
    TextEditingController(text: record?['Unique ID'] ?? '');
    final TextEditingController pickupAddressController =
    TextEditingController(text: record?['Latest Pickup Address'] ?? '');
    final TextEditingController dropAddressController =
    TextEditingController(text: record?['Latest Drop Address'] ?? '');
    final TextEditingController purposeController =
    TextEditingController(text: record?['Purpose of Pickup'] ?? '');
    final TextEditingController driverController =
    TextEditingController(text: record?['Driver Name'] ?? '');
    final TextEditingController vehicleController =
    TextEditingController(text: record?['Vehicle Number'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Record' : 'Add New Record'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: uniqueIdController,
                  decoration: const InputDecoration(labelText: 'Unique ID'),
                ),
                TextField(
                  controller: pickupAddressController,
                  decoration:
                  const InputDecoration(labelText: 'Latest Pickup Address'),
                ),
                TextField(
                  controller: dropAddressController,
                  decoration:
                  const InputDecoration(labelText: 'Latest Drop Address'),
                ),
                TextField(
                  controller: purposeController,
                  decoration:
                  const InputDecoration(labelText: 'Purpose of Pickup'),
                ),
                TextField(
                  controller: driverController,
                  decoration: const InputDecoration(labelText: 'Driver Name'),
                ),
                TextField(
                  controller: vehicleController,
                  decoration:
                  const InputDecoration(labelText: 'Vehicle Number'),
                ),
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
                  'Unique ID': uniqueIdController.text.trim(),
                  'Latest Pickup Address': pickupAddressController.text.trim(),
                  'Latest Drop Address': dropAddressController.text.trim(),
                  'Purpose of Pickup': purposeController.text.trim(),
                  'Driver Name': driverController.text.trim(),
                  'Vehicle Number': vehicleController.text.trim(),
                  'Dog\'s Photo': '',
                };

                try {
                  if (isEditing) {
                    await _firestore
                        .collection('pickupTracking')
                        .doc(record!['Serial No'])
                        .update(newRecord);
                  } else {
                    final snapshot =
                    await _firestore.collection('pickupTracking').get();
                    final documentIds = snapshot.docs
                        .map((doc) => int.tryParse(doc.id) ?? 0)
                        .toList();
                    final nextSerialNo = (documentIds.isEmpty
                        ? 0
                        : documentIds.reduce((a, b) => a > b ? a : b)) +
                        1;

                    await _firestore
                        .collection('pickupTracking')
                        .doc(nextSerialNo.toString())
                        .set(newRecord);
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error saving record: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Tracking'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Serial No')),
            DataColumn(label: Text('Unique ID')),
            DataColumn(label: Text('Dog\'s Photo')),
            DataColumn(label: Text('Pickup Address')),
            DataColumn(label: Text('Drop Address')),
            DataColumn(label: Text('Driver Name')),
            DataColumn(label: Text('Vehicle Number')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _rows.map((row) {
            return DataRow(cells: [
              DataCell(Text(row['Serial No'])),
              DataCell(Text(row['Unique ID'])),
              DataCell(
                row['Dog\'s Photo'].isNotEmpty
                    ? Row(
                  children: [
                    Image.network(
                      row['Dog\'s Photo'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmDelete = await _showDeleteDialog();
                        if (confirmDelete) {
                          await _deleteFileFromFirestore(
                              _rows.indexOf(row), 'Dog\'s Photo');
                        }
                      },
                    ),
                  ],
                )
                    : IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () => _pickImageAndUploadToDropbox(
                      _rows.indexOf(row)),
                ),
              ),
              DataCell(Text(row['Latest Pickup Address'])),
              DataCell(Text(row['Latest Drop Address'])),
              DataCell(Text(row['Driver Name'])),
              DataCell(Text(row['Vehicle Number'])),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showRecordDialog(record: row),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmDelete = await _showDeleteDialog();
                        if (confirmDelete) {
                          await _firestore
                              .collection('pickupTracking')
                              .doc(row['Serial No'])
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
