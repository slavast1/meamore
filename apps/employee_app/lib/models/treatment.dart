import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  Treatment({
    required this.employeeId,
    required this.employeeName,
    required this.treatmentType,
    required this.dogName,
    required this.breed,
    required this.ownerFullName,
    required this.startedAt,
    this.coatCondition,
    this.finishedAt,
    this.sessionId,
  });

  final String employeeId;
  final String employeeName;

  final String treatmentType;
  final String dogName;
  final String breed;
  final String ownerFullName;

  final int? coatCondition; // 1..5 optional
  final DateTime startedAt;
  final DateTime? finishedAt;

  /// Stable identifier for a treatment session.
  final String? sessionId;

  /// Convenience id used by the UI selection.
  String get id => sessionId ?? '';

  factory Treatment.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    DateTime? _toNullableDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final coatRaw = d['coatCondition'];
    final coat = (coatRaw is num) ? coatRaw.toInt() : int.tryParse('${coatRaw ?? ''}');

    return Treatment(
      employeeId: (d['employeeId'] ?? '').toString(),
      employeeName: (d['employeeName'] ?? '').toString(),
      treatmentType: (d['treatmentType'] ?? '').toString(),
      dogName: (d['dogName'] ?? '').toString(),
      breed: (d['breed'] ?? '').toString(),
      ownerFullName: (d['ownerFullName'] ?? '').toString(),
      startedAt: _toDate(d['startedAt']),
      finishedAt: _toNullableDate(d['finishedAt']),
      coatCondition: coat,
      sessionId: d['sessionId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'treatmentType': treatmentType,
        'dogName': dogName,
        'breed': breed,
        'ownerFullName': ownerFullName,
        'coatCondition': coatCondition,
        'startedAt': startedAt,
        'finishedAt': finishedAt,
        'sessionId': sessionId,
      };
}
