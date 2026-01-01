import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

/// Report service for finished treatments.
///
/// IMPORTANT: This service returns report *data* for UI preview, and can also
/// export the already-loaded data to Excel.
class TreatmentsReportService {
  TreatmentsReportService({required this.shopId});

  final String shopId;

  CollectionReference<Map<String, dynamic>> get _treatmentsCol =>
      FirebaseFirestore.instance.collection('shops/$shopId/treatments');

  /// Fetches finished treatments in [rangeStart]..[rangeEnd) and optionally
  /// filters by [employeeId].
  Future<TreatmentsReportData> fetchReportData({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    String? employeeId,
  }) async {
    final startTs = Timestamp.fromDate(rangeStart.toUtc());
    final endTs = Timestamp.fromDate(rangeEnd.toUtc());

    // Your Firestore schema uses `finishedAt` as the end timestamp.
    // Some older data may still have `endedAt`, so we query both and merge.
    final emp = employeeId?.trim();

    Future<QuerySnapshot<Map<String, dynamic>>> _runQuery(String endField) {
      Query<Map<String, dynamic>> q = _treatmentsCol
          .where(endField, isGreaterThanOrEqualTo: startTs)
          .where(endField, isLessThan: endTs)
          .orderBy(endField);
      return q.get();
    }

    final snaps = await Future.wait([
      _runQuery('finishedAt'),
      _runQuery('endedAt'),
    ]);

    // Merge + dedupe by document id.
    final byId = <String, TreatmentReportRow>{};
    for (final snap in snaps) {
      for (final d in snap.docs) {
        byId.putIfAbsent(d.id, () => TreatmentReportRow.fromDoc(d.id, d.data()));
      }
    }

    final rows = byId.values.where((r) => r.endedAt != null).toList()
      ..sort((a, b) => (a.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    // Filter by employee on the client to avoid requiring a composite Firestore index.
    final filteredRows = (emp != null && emp.isNotEmpty)
        ? rows.where((r) => r.employeeId == emp).toList()
        : rows;

    // Build summaries
    final summaryByEmployee = <String, EmployeeReportSummary>{};
    int totalMinutes = 0;
    for (final r in filteredRows) {
      final key = r.employeeId.isNotEmpty ? r.employeeId : r.employeeName;
      final s = summaryByEmployee.putIfAbsent(
        key,
        () => EmployeeReportSummary(employeeId: r.employeeId, employeeName: r.employeeName),
      );
      s.count += 1;
      s.totalMinutes += r.durationMinutes;
      totalMinutes += r.durationMinutes;
    }

    final summaries = summaryByEmployee.values.toList()
      ..sort((a, b) {
        final c = a.employeeName.compareTo(b.employeeName);
        return c != 0 ? c : a.employeeId.compareTo(b.employeeId);
      });

    return TreatmentsReportData(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      employeeIdFilter: emp,
      rows: filteredRows,
      summaries: summaries,
      totalMinutes: totalMinutes,
    );
  }

  /// Exports already-loaded [data] to XLSX (Summary + Treatments).
  ///
  /// On web, some versions of the `excel` package may trigger a download as a
  /// side-effect of `save()`. To avoid double downloads, this method either:
  ///   - triggers the download itself with the provided [filename] and returns null, OR
  ///   - returns bytes so the caller can download exactly once.
  Future<Uint8List?> exportToExcel(
    TreatmentsReportData data, {
    required String filename,
    required bool isWeb,
  }) async {
    final excel = Excel.createExcel();

    // Ensure clean sheet names
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Summary') {
      excel.rename(defaultSheet, 'Summary');
    }

    final summarySheet = excel['Summary'];
    final treatmentsSheet = excel['Treatments'];

    // Summary header
    summarySheet.appendRow([
      TextCellValue('Employee'),
      TextCellValue('Treatments'),
      TextCellValue('Total Minutes'),
    ]);

    for (final s in data.summaries) {
      summarySheet.appendRow([
        TextCellValue(s.employeeName.isNotEmpty ? s.employeeName : s.employeeId),
        IntCellValue(s.count),
        IntCellValue(s.totalMinutes),
      ]);
    }

    // Treatments header
    treatmentsSheet.appendRow([
      TextCellValue('Ended Date'),
      TextCellValue('Start'),
      TextCellValue('End'),
      TextCellValue('Minutes'),
      TextCellValue('Employee'),
      TextCellValue('Dog Name'),
      TextCellValue('Breed'),
      TextCellValue('Owner Name'),
      TextCellValue('Treatment Type'),
      TextCellValue('Coat Condition'),
    ]);

    String fmt(DateTime? dt) => dt == null ? '' : dt.toLocal().toIso8601String();

    for (final r in data.rows) {
      treatmentsSheet.appendRow([
        TextCellValue(r.endedAt == null ? '' : r.endedAt!.toLocal().toIso8601String().split('T').first),
        TextCellValue(fmt(r.startedAt)),
        TextCellValue(fmt(r.endedAt)),
        IntCellValue(r.durationMinutes),
        TextCellValue(r.employeeName.isNotEmpty ? r.employeeName : r.employeeId),
        TextCellValue(r.dogName),
        TextCellValue(r.breed),
        TextCellValue(r.ownerName),
        TextCellValue(r.treatmentType),
        TextCellValue(r.coatCondition?.toString() ?? ''),
      ]);
    }

    if (isWeb) {
      // Prefer letting the package handle the download with the correct filename,
      // if supported.
      try {
        // dynamic call to avoid hard dependency on exact method signature.
        (excel as dynamic).save(fileName: filename);
        return null; // downloaded by the package
      } catch (_) {
        // Fallback: try to get raw bytes without triggering a download.
        try {
          final out = (excel as dynamic).encode();
          if (out is Uint8List) return out;
          if (out is List<int>) return Uint8List.fromList(out);
          if (out is List) return Uint8List.fromList(out.cast<int>());
        } catch (_) {
          // ignore
        }
        throw StateError('Failed to export Excel bytes on web');
      }
    }

    final bytes = excel.save();
    if (bytes == null) throw StateError('Failed to generate Excel file');
    return Uint8List.fromList(bytes);
  }
}

class TreatmentsReportData {
  TreatmentsReportData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.employeeIdFilter,
    required this.rows,
    required this.summaries,
    required this.totalMinutes,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String? employeeIdFilter;
  final List<TreatmentReportRow> rows;
  final List<EmployeeReportSummary> summaries;
  final int totalMinutes;

  int get totalTreatments => rows.length;
}

class TreatmentReportRow {
  TreatmentReportRow({
    required this.employeeId,
    required this.employeeName,
    required this.dogName,
    required this.breed,
    required this.ownerName,
    required this.treatmentType,
    required this.coatCondition,
    required this.startedAt,
    required this.endedAt,
  });

  final String employeeId;
  final String employeeName;
  final String dogName;
  final String breed;
  final String ownerName;
  final String treatmentType;
  final int? coatCondition;
  final DateTime? startedAt;
  final DateTime? endedAt;

  int get durationMinutes {
    if (startedAt == null || endedAt == null) return 0;
    final diff = endedAt!.difference(startedAt!);
    return diff.inMinutes < 0 ? 0 : diff.inMinutes;
  }

  static DateTime? _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  factory TreatmentReportRow.fromDoc(String id, Map<String, dynamic> data) {
    final owner = (data['ownerFullName'] ?? data['ownerName'] ?? '').toString();

    return TreatmentReportRow(
      employeeId: (data['employeeId'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      dogName: (data['dogName'] ?? '').toString(),
      breed: (data['breed'] ?? '').toString(),
      ownerName: owner,
      treatmentType: (data['treatmentType'] ?? '').toString(),
      coatCondition: (data['coatCondition'] is int)
          ? data['coatCondition'] as int
          : int.tryParse((data['coatCondition'] ?? '').toString()),
      startedAt: _tsToDate(data['startedAt']),
      // Your docs use `finishedAt`; some legacy docs use `endedAt`.
      endedAt: _tsToDate(data['finishedAt']) ?? _tsToDate(data['endedAt']),
    );
  }
}

class EmployeeReportSummary {
  EmployeeReportSummary({required this.employeeId, required this.employeeName});

  final String employeeId;
  final String employeeName;
  int count = 0;
  int totalMinutes = 0;
}
