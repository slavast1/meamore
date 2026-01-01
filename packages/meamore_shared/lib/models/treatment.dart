import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  Treatment({
    required this.employeeId,
    required this.employeeName,
    required this.dogName,
    required this.breed,
    required this.ownerName,
    required this.treatmentType,
    required this.coatCondition,
    required this.startedAt,
    this.endedAt,
  });

  final String employeeId;
  final String employeeName;

  final String dogName;
  final String breed;
  final String ownerName;
  final String treatmentType;

  /// 1..5
  final int coatCondition;

  final Timestamp startedAt;
  final Timestamp? endedAt;

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'dogName': dogName,
        'breed': breed,
        'ownerName': ownerName,
        'treatmentType': treatmentType,
        'coatCondition': coatCondition,
        'startedAt': startedAt,
        'endedAt': endedAt,
      };
}
