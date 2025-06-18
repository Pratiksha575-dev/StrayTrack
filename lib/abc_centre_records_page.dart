import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseasedDogInfo {
  String diseaseType;
  int count;
  Map<String,int> localities;

  DiseasedDogInfo({
    required this.diseaseType,
    required this.count,
    required this.localities,
  });

  Map<String, dynamic> toJson() => {
    'diseaseType': diseaseType,
    'count': count,
    'localities': localities,
  };

  static DiseasedDogInfo fromJson(Map<String, dynamic> json) => DiseasedDogInfo(
    diseaseType: json['diseaseType'],
    count: json['count'],
    localities: Map<String,int>.from(json['localities']),
  );
}

class ABCRecord {
  String documentId;
  String centreName;
  String address;
  int capacity;
  int currentLoad;
  List<DiseasedDogInfo> diseasedDogs;
  int healthyDogCount;

  ABCRecord({
    required this.documentId,
    required this.centreName,
    required this.address,
    required this.capacity,
    required this.currentLoad,
    required this.diseasedDogs,
    required this.healthyDogCount,
  });

  // Calculate total diseased dog count
  int get totalDiseasedDogCount {
    return diseasedDogs.fold(0, (sum, dog) => sum + dog.count);
  }

  Map<String, dynamic> toJson() => {
    'centreName': centreName,
    'address': address,
    'capacity': capacity,
    'currentLoad': currentLoad,
    'diseasedDogs': diseasedDogs.map((dog) => dog.toJson()).toList(),
    'healthyDogCount': healthyDogCount,
  };

  static ABCRecord fromJson(String documentId, Map<String, dynamic> json) => ABCRecord(
    documentId: documentId,
    centreName: json['centreName'],
    address: json['address'],
    capacity: json['capacity'],
    currentLoad: json['currentLoad'],
    diseasedDogs: (json['diseasedDogs'] as List)
        .map((dog) => DiseasedDogInfo.fromJson(dog))
        .toList(),
    healthyDogCount: json['healthyDogCount'],
  );
}

class ABCRecordsPage extends StatefulWidget {
  const ABCRecordsPage({super.key});

  @override
  _ABCRecordsPageState createState() => _ABCRecordsPageState();
}

class _ABCRecordsPageState extends State<ABCRecordsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
  }



  Future<void> _deleteRecord(ABCRecord record) async {
    try {
      // Delete the record from Firestore
      await _firestore.collection('abc_records').doc(record.documentId).delete();

      // Update the UI by removing the record from the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: $e')),
      );
    }
  }


  void _showRecordDialog({ABCRecord? record}) {
    final TextEditingController centreNameController =
    TextEditingController(text: record?.centreName ?? '');
    final TextEditingController addressController =
    TextEditingController(text: record?.address ?? '');
    final TextEditingController capacityController =
    TextEditingController(text: record?.capacity.toString() ?? '');
    final TextEditingController currentLoadController =
    TextEditingController(text: record?.currentLoad.toString() ?? '');
    final TextEditingController healthyDogCountController =
    TextEditingController(text: record?.healthyDogCount.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(record == null ? 'Add New Record' : 'Edit Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: centreNameController,
                  decoration: const InputDecoration(labelText: 'Centre Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: currentLoadController,
                  decoration: const InputDecoration(labelText: 'Current Load'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: healthyDogCountController,
                  decoration: const InputDecoration(labelText: 'Healthy Dog Count'),
                  keyboardType: TextInputType.number,
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
                final centreName = centreNameController.text.trim();
                final address = addressController.text.trim();
                final capacity = int.tryParse(capacityController.text) ?? 0;
                final currentLoad = int.tryParse(currentLoadController.text) ?? 0;
                final healthyDogCount =
                    int.tryParse(healthyDogCountController.text) ?? 0;

                if (centreName.isNotEmpty && address.isNotEmpty) {
                  try {
                    if (record == null) {
                      // Add a new record
                      final snapshot = await _firestore.collection('abc_records').get();
                      final documentIds = snapshot.docs.map((doc) => int.tryParse(doc.id) ?? 0).toList();
                      final nextSerialNo = (documentIds.isEmpty ? 0 : documentIds.reduce((a, b) => a > b ? a : b)) + 1;
                      final newDocRef = _firestore.collection('abc_records').doc(nextSerialNo.toString());
                      final newRecord = ABCRecord(
                        documentId: newDocRef.id,
                        centreName: centreName,
                        address: address,
                        capacity: capacity,
                        currentLoad: currentLoad,
                        diseasedDogs: [],
                        healthyDogCount: healthyDogCount,
                      );
                      await newDocRef.set(newRecord.toJson());
                      print('New Record Added to Firestore');
                    } else {
                      // Edit the existing record
                      await _firestore
                          .collection('abc_records')
                          .doc(record.documentId)
                          .update({
                        'centreName': centreName,
                        'address': address,
                        'capacity': capacity,
                        'currentLoad': currentLoad,
                        'healthyDogCount': healthyDogCount,
                      });
                      print('Record Updated in Firestore');
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  } catch (e) {
                    print('Firestore Write Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving record: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDiseasedDogsDialog(BuildContext context, List<DiseasedDogInfo> diseasedDogs, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Diseased Dog Details'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Disease Type')),
                          DataColumn(label: Text('Count')),
                          DataColumn(label: Text('Localities')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: diseasedDogs.map((dog) {
                          final index = diseasedDogs.indexOf(dog);
                          return DataRow(
                            cells: [
                              DataCell(Text(dog.diseaseType)),
                              DataCell(Text(dog.count.toString())),
                              DataCell(Text(dog.localities.entries
                                  .map((entry) => '${entry.key}: ${entry.value}')
                                  .join(', '))),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _editDiseasedDogDialog(
                                          context,
                                          diseasedDogs,
                                          setState,
                                          documentId,
                                          index: index,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        setState(() {
                                          diseasedDogs.removeAt(index);
                                        });

                                        // Update Firestore
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('abc_records')
                                              .doc(documentId)
                                              .update({
                                            'diseasedDogs': diseasedDogs.map((dog) => dog.toJson()).toList(),
                                          });
                                        } catch (e) {
                                          print('Error deleting diseased dog: $e');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _editDiseasedDogDialog(context, diseasedDogs, setState, documentId);
                      },
                      child: const Text('Add New Diseased Dog'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editDiseasedDogDialog(
      BuildContext context,
      List<DiseasedDogInfo> diseasedDogs,
      StateSetter setState,
      String documentId, {
        int? index,
      }) {
    final TextEditingController diseaseTypeController = TextEditingController();
    final TextEditingController countController = TextEditingController();
    final Map<String, int> localitiesMap = {};

    if (index != null) {
      final existingDog = diseasedDogs[index];
      diseaseTypeController.text = existingDog.diseaseType;
      countController.text = existingDog.count.toString();
      localitiesMap.addAll(existingDog.localities);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, dialogSetState) {
          return AlertDialog(
            title: Text(index == null ? 'Add Diseased Dog' : 'Edit Diseased Dog'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: diseaseTypeController,
                    decoration: const InputDecoration(labelText: 'Disease Type'),
                  ),
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(labelText: 'Count'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  const Text('Localities'),
                  Column(
                    children: localitiesMap.entries.map((entry) {
                      return ListTile(
                        title: Text('${entry.key} (${entry.value})'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            dialogSetState(() {
                              localitiesMap.remove(entry.key);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final TextEditingController localityNameController = TextEditingController();
                      final TextEditingController localityCountController = TextEditingController();

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Add Locality'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: localityNameController,
                                  decoration: const InputDecoration(labelText: 'Locality Name'),
                                ),
                                TextField(
                                  controller: localityCountController,
                                  decoration: const InputDecoration(labelText: 'Count'),
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final locality = localityNameController.text.trim();
                                  final count = int.tryParse(localityCountController.text) ?? 0;

                                  if (locality.isNotEmpty && count > 0) {
                                    dialogSetState(() {
                                      localitiesMap[locality] = count;
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Add Locality'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final diseaseType = diseaseTypeController.text.trim();
                  final count = int.tryParse(countController.text) ?? 0;

                  if (diseaseType.isNotEmpty && count > 0) {
                    setState(() {
                      if (index != null) {
                        diseasedDogs[index] = DiseasedDogInfo(
                          diseaseType: diseaseType,
                          count: count,
                          localities: localitiesMap,
                        );
                      } else {
                        diseasedDogs.add(DiseasedDogInfo(
                          diseaseType: diseaseType,
                          count: count,
                          localities: localitiesMap,
                        ));
                      }
                    });

                    try {
                      await FirebaseFirestore.instance
                          .collection('abc_records')
                          .doc(documentId)
                          .update({
                        'diseasedDogs': diseasedDogs.map((dog) => dog.toJson()).toList(),
                      });
                    } catch (e) {
                      print('Error updating diseased dogs: $e');
                    }
                  }

                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ABC Records')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('abc_records')
            .orderBy(FieldPath.documentId)
            .snapshots(), // Listen for real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data?.docs
              .map((doc) => ABCRecord.fromJson(doc.id, doc.data() as Map<String, dynamic>))
              .toList() ?? [];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20.0,
              columns: const [
                DataColumn(label: Text('S.No')),
                DataColumn(label: Text('Centre Name')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Capacity')),
                DataColumn(label: Text('Current Load')),
                DataColumn(label: Text('Healthy Dogs')),
                DataColumn(label: Text('Diseased Dogs')),
                DataColumn(label: Text('Edit')),
                DataColumn(label: Text('Delete')),
              ],
              rows: records.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(record.centreName)),
                    DataCell(Text(record.address)),
                    DataCell(Text(record.capacity.toString())),
                    DataCell(Text(record.currentLoad.toString())),
                    DataCell(Text(record.healthyDogCount.toString())),
                    DataCell(
                      GestureDetector(
                        onTap: () => _showDiseasedDogsDialog(
                            context, record.diseasedDogs, record.documentId),
                        child: Text(
                          record.totalDiseasedDogCount.toString(),
                          style: const TextStyle(
                              color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showRecordDialog(record: record),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await _deleteRecord(record);
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}