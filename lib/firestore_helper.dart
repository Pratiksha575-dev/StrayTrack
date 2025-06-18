import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch data from Firestore
  Future<List<Map<String, dynamic>>> fetchDogsRecords() async {
    QuerySnapshot querySnapshot = await _firestore.collection('dogs').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Add new record to Firestore
  Future<void> addDogRecord(Map<String, dynamic> data) async {
    await _firestore.collection('dogs').add(data);
  }

  // Update existing record in Firestore
  Future<void> updateDogRecord(String docId, Map<String, dynamic> data) async {
    await _firestore.collection('dogs').doc(docId).update(data);
  }
}
