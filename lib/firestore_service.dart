import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save or update dog record
  Future<void> saveOrUpdateDogRecord(String serialNo, Map<String, dynamic> dogData) async {
    try {
      DocumentReference docRef = _db.collection('dogs_records').doc(serialNo);
      await docRef.set(dogData, SetOptions(merge: true)); // Merge ensures existing fields are updated
      print("Document saved or updated successfully.");
    } catch (e) {
      print("Error saving/updating document: $e");
    }
  }

  /// Update specific field for a dog record
  Future<void> updateDogRecordField(String serialNo, String field, dynamic value) async {
    try {
      DocumentReference docRef = _db.collection('dogs_records').doc(serialNo);
      await docRef.update({field: value});
      print("Field '$field' updated successfully for document $serialNo.");
    } catch (e) {
      print("Error updating field '$field': $e");
    }
  }

  /// Fetch all dog records
  Future<List<Map<String, dynamic>>> fetchAllDogRecords() async {
    try {
      QuerySnapshot snapshot = await _db.collection('dogs_records').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching documents: $e");
      return [];
    }
  }

  /// Fetch a single dog record
  Future<Map<String, dynamic>?> fetchDogRecord(String serialNo) async {
    try {
      DocumentSnapshot doc = await _db.collection('dogs_records').doc(serialNo).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("Document $serialNo does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching document: $e");
      return null;
    }
  }
}
