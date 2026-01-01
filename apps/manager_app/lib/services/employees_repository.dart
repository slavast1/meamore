import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeesRepository {
  EmployeesRepository({required this.shopId});

  final String shopId;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .collection('employees');

  DocumentReference<Map<String, dynamic>> doc(String employeeId) => _col.doc(employeeId);

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll() => _col.snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamOne(String employeeId) =>
      doc(employeeId).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getOne(String employeeId) =>
      doc(employeeId).get();

  Future<void> updateBasicInfo({
    required String employeeId,
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    return doc(employeeId).update({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMany(Iterable<String> employeeIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in employeeIds) {
      batch.delete(doc(id));
    }
    await batch.commit();
  }

  /// Creates employee where employeeId == Firestore docId (logical key).
  /// Throws Exception('EMPLOYEE_ID_EXISTS') if already exists.
  Future<void> createEmployee({
    required String employeeId,
    required String firstName,
    required String lastName,
    required String phone,
    required String inviteCode,
  }) async {
    final ref = doc(employeeId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) throw Exception('EMPLOYEE_ID_EXISTS');

      tx.set(ref, {
        'employeeId': employeeId,
        'idNumber': employeeId,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'inviteCode': inviteCode,
        'claimed': false,
        'userUid': null,
        'status': 'idle',
        'activeSessionId': null,
        'activeStartedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
