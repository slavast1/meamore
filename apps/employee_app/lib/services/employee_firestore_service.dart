import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/treatment.dart';
import 'package:meamore_shared/models/employee.dart';

class EmployeeFirestoreService {
  EmployeeFirestoreService({
    required this.shopId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String shopId;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _empRef(String employeeId) =>
      _db.doc('shops/$shopId/employees/$employeeId').withConverter(
            fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
            toFirestore: (m, _) => m,
          );

  CollectionReference<Map<String, dynamic>> get _treatments =>
      _db.collection('shops/$shopId/treatments');

  Future<String> startTreatment({
    required Treatment treatment,
    String? sessionIdOverride,
  }) async {
    final override = sessionIdOverride?.trim();
    final sessionRef = (override != null && override.isNotEmpty)
        ? _treatments.doc(override)
        : _treatments.doc();

    final sessionId = sessionRef.id;

    final batch = _db.batch();

    batch.set(sessionRef, {
      ...treatment.toJson(),
      'sessionId': sessionId,
      'status': 'busy',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_empRef(treatment.employeeId), {
      'status': 'busy',
      'activeSessionId': sessionId,
      'activeStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return sessionId;
  }

  Future<void> finishTreatment({
    required String employeeId,
    required String sessionId,
  }) async {
    final batch = _db.batch();
    // Use a concrete timestamp so the document immediately matches
    // "treated today" queries (serverTimestamp can be temporarily null
    // in the local cache until the server round-trip completes).
    final now = Timestamp.fromDate(DateTime.now());

    batch.update(_treatments.doc(sessionId), {
      'finishedAt': now,
      'status': 'idle',
      'updatedAt': now,
    });

    batch.update(_empRef(employeeId), {
      'status': 'idle',
      'activeSessionId': FieldValue.delete(),
      'activeStartedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<Employee?> fetchEmployee(String employeeId) async {
    final snap = await _db.doc('shops/$shopId/employees/$employeeId').get();
    if (!snap.exists) return null;
    return Employee.fromDoc(snap);
  }

}
