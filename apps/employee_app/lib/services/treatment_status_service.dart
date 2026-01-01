import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/treatment.dart';

/// Reads treatment documents to derive per-dog status.
///
/// Busy = there is at least one treatment document with status == 'busy'.
/// Treated today = there is at least one treatment finished today.
class TreatmentStatusService {
  TreatmentStatusService({required this.shopId});

  final String shopId;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('shops/$shopId/treatments');

  Future<List<Treatment>> fetchOpenTreatments() async {
    final snap = await _col.where('status', isEqualTo: 'busy').get();
    return snap.docs.map((d) => Treatment.fromDoc(d)).toList();
  }

  Future<List<Treatment>> fetchTreatmentsFinishedToday({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _col
        .where('finishedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('finishedAt', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs.map((d) => Treatment.fromDoc(d)).toList();
  }


  Future<void> deleteTreatments(List<String> sessionIds) async {
    for (final id in sessionIds) {
      await _col.doc(id).delete();
    }
  }

}
