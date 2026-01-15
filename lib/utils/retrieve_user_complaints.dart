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

      if (!userDoc.exists || userDoc.data() == null || !userDoc.data()!.containsKey('complaints')) {
        return [];
      }

      List<dynamic> complaintIds = userDoc.get('complaints');
      if (complaintIds.isEmpty) return [];

      // 2. Fetch reports from the 'reports' collection matching those IDs
      // FIX: Firestore 'whereIn' is limited to 30 items.
      // We chunk the list into groups of 30 to support users with many complaints.
      List<ReportModel> allReports = [];

      for (var i = 0; i < complaintIds.length; i += 30) {
        var end = (i + 30 < complaintIds.length) ? i + 30 : complaintIds.length;
        var chunk = complaintIds.sublist(i, end);

        QuerySnapshot reportSnapshots = await FirebaseFirestore.instance
            .collection('reports')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        var models = reportSnapshots.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList();

        allReports.addAll(models);
      }

      // Sort by timestamp descending (newest first)
      allReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allReports;
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }
}