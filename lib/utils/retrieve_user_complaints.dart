import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fetchIncident.dart';

class RetrieveUserComplaints {

  static Future<List<ReportModel>> fetch(String userId) async {
    try {
      // 1. Get the user's list of complaint IDs
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if user exists or has the 'complaints' key
      if (!userDoc.exists || userDoc.data() == null || !userDoc.data()!.containsKey('complaints')) {
        return [];
      }

      List<dynamic> complaintIds = userDoc.get('complaints');
      if (complaintIds.isEmpty) return [];

      // 2. Fetch reports from the 'reports' collection matching those IDs
      // Note: whereIn is limited to 30 items per query
      QuerySnapshot reportSnapshots = await FirebaseFirestore.instance
          .collection('reports')
          .where(FieldPath.documentId, whereIn: complaintIds)
          .get();

      return reportSnapshots.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }


}