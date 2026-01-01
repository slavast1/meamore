import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  Employee({
    required this.id, // docId == logical key
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.status,
    this.legacyName,
    this.idNumber,
    this.employeeIdField,
    this.activeSessionId,
    this.activeStartedAt,
  });

  final String id;

  final String firstName;
  final String lastName;
  final String phone;
  final String status;

  final String? legacyName;       // old "name"
  final String? idNumber;         // field, usually same as id
  final String? employeeIdField;  // field, usually same as id

  final String? activeSessionId;
  final DateTime? activeStartedAt;

  factory Employee.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    DateTime? started;
    final rawStarted = d['activeStartedAt'];
    if (rawStarted is Timestamp) started = rawStarted.toDate();

    return Employee(
      id: doc.id,
      firstName: (d['firstName'] ?? '').toString().trim(),
      lastName: (d['lastName'] ?? '').toString().trim(),
      phone: (d['phone'] ?? d['phoneE164'] ?? '').toString().trim(),
      status: (d['status'] ?? 'unknown').toString().trim(),
      legacyName: d['name']?.toString().trim(),
      idNumber: d['idNumber']?.toString().trim(),
      employeeIdField: d['employeeId']?.toString().trim(),
      activeSessionId: d['activeSessionId']?.toString(),
      activeStartedAt: started,
    );
  }

  String displayName(String noNameValue) {
    if (firstName.isEmpty && lastName.isEmpty) {
      final ln = (legacyName ?? '').trim();
      return ln.isEmpty ? noNameValue : ln;
    }
    final name = '$lastName $firstName'.trim();
    return name.isEmpty ? noNameValue : name;
  }

  String get logicalEmployeeId => id;
  String get idNumberOrLogical => (idNumber == null || idNumber!.isEmpty) ? id : idNumber!;
}
