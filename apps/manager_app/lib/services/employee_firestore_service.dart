import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeFirestoreService {
  EmployeeFirestoreService({required this.shopId});

  final String shopId;

  DocumentReference<Map<String, dynamic>> employeeRef(String employeeId) =>
      FirebaseFirestore.instance.doc('shops/$shopId/employees/$employeeId');

  CollectionReference<Map<String, dynamic>> get treatmentsCol =>
      FirebaseFirestore.instance.collection('shops/$shopId/treatments');

  Future<Map<String, dynamic>?> loadEmployee(String employeeId) async {
    final snap = await employeeRef(employeeId).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  Future<String> startTreatment({
    required String employeeId,
    required String employeeName,
    required String dogName,
    required String breed,
    required String ownerName,
    required String treatmentType,
    required int coatCondition, // 1..5
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final treatmentDoc = treatmentsCol.doc();
    batch.set(treatmentDoc, {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'dogName': dogName,
      'breed': breed,
      'ownerName': ownerName,
      'treatmentType': treatmentType,
      'coatCondition': coatCondition,
      'startedAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });

    batch.update(employeeRef(employeeId), {
      'status': 'busy',
      'activeSessionId': treatmentDoc.id,
      'activeStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return treatmentDoc.id;
  }

  Future<void> finishTreatment({
    required String employeeId,
    required String treatmentId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final treatmentDoc = treatmentsCol.doc(treatmentId);
    batch.update(treatmentDoc, {
      'endedAt': FieldValue.serverTimestamp(),
    });

    batch.update(employeeRef(employeeId), {
      'status': 'idle',
      'activeSessionId': null,
      'activeStartedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
