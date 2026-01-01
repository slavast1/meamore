import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:meamore/services/employees_repository.dart';
import 'package:meamore/services/reports/treatments_report_service.dart';
import 'package:meamore/utils/save_bytes/save_bytes.dart';
import 'package:meamore/models/employee_display.dart';
import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore_shared/models/employee.dart';

enum _ReportPeriod { daily, weekly, monthly, quarterly }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.shopId});
  final String shopId;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final EmployeesRepository _repo = EmployeesRepository(shopId: widget.shopId);
  late final TreatmentsReportService _reportService = TreatmentsReportService(shopId: widget.shopId);

  _ReportPeriod _period = _ReportPeriod.daily;
  DateTime _anchorDate = DateTime.now();
  String? _employeeId; // null => all

  Map<String, String> _employeeNameById = const {}; // employeeId -> display name

  bool _loading = false;
  TreatmentsReportData? _report;

  
  String _displayEmployeeName(String employeeId, String employeeName) {
    final name = employeeName.trim().isNotEmpty ? employeeName.trim() : (_employeeNameById[employeeId]?.trim() ?? '');
    if (name.isNotEmpty) return name;
    return AppLocalizations.of(context)!.noNameValue;
  }

  Future<Map<String, String>> _fetchEmployeeNameById() async {
    final snap = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('employees')
        .get();

    String buildName(Map<String, dynamic> d) {
      final first = (d['firstName'] ?? '').toString().trim();
      final last = (d['lastName'] ?? '').toString().trim();
      final full = ('$first $last').trim();
      if (full.isNotEmpty) return full;
      // fallbacks sometimes used in older schemas
      final display = (d['displayName'] ?? d['name'] ?? d['fullName'] ?? '').toString().trim();
      return display;
    }

    final map = <String, String>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final id = (d['employeeId'] ?? doc.id).toString().trim();
      final name = buildName(d);
      if (id.isNotEmpty && name.isNotEmpty) map[id] = name;
    }
    return map;
  }

  TreatmentsReportData _applyEmployeeNames(TreatmentsReportData data) {
    // Fill employeeName in rows and summaries from _employeeNameById when empty.
    final rows = data.rows
        .map((r) => TreatmentReportRow(
              employeeId: r.employeeId,
              employeeName: _displayEmployeeName(r.employeeId, r.employeeName),
              dogName: r.dogName,
              breed: r.breed,
              ownerName: r.ownerName,
              treatmentType: r.treatmentType,
              coatCondition: r.coatCondition,
              startedAt: r.startedAt,
              endedAt: r.endedAt,
            ))
        .toList();

    final summaries = data.summaries.map((s) {
      final out = EmployeeReportSummary(
        employeeId: s.employeeId,
        employeeName: _displayEmployeeName(s.employeeId, s.employeeName),
      );
      out.count = s.count;
      out.totalMinutes = s.totalMinutes;
      return out;
    }).toList();

    return TreatmentsReportData(
      rangeStart: data.rangeStart,
      rangeEnd: data.rangeEnd,
      employeeIdFilter: data.employeeIdFilter,
      rows: rows,
      summaries: summaries,
      totalMinutes: data.totalMinutes,
    );
  }

(DateTime start, DateTime end) _computeRange(DateTime anchor, _ReportPeriod period) {
    DateTime start;
    DateTime end;

    switch (period) {
      case _ReportPeriod.daily:
        start = DateTime(anchor.year, anchor.month, anchor.day);
        end = start.add(const Duration(days: 1));
        break;
      case _ReportPeriod.weekly:
        // Week starts Monday
        final weekday = anchor.weekday; // Mon=1..Sun=7
        start = DateTime(anchor.year, anchor.month, anchor.day).subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case _ReportPeriod.monthly:
        start = DateTime(anchor.year, anchor.month, 1);
        end = (anchor.month == 12)
            ? DateTime(anchor.year + 1, 1, 1)
            : DateTime(anchor.year, anchor.month + 1, 1);
        break;
      case _ReportPeriod.quarterly:
        final q = ((anchor.month - 1) ~/ 3); // 0..3
        final startMonth = q * 3 + 1;
        start = DateTime(anchor.year, startMonth, 1);
        final endMonth = startMonth + 3;
        end = endMonth > 12 ? DateTime(anchor.year + 1, endMonth - 12, 1) : DateTime(anchor.year, endMonth, 1);
        break;
    }

    return (start, end);
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().padLeft(4, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _anchorDate = picked;
      _report = null; // filters changed => clear preview
    });
  }

  Future<void> _generatePreview() async {
    final t = AppLocalizations.of(context)!;
    final (start, end) = _computeRange(_anchorDate, _period);

    setState(() {
      _loading = true;
      _report = null;
    });

    try {
      _employeeNameById = await _fetchEmployeeNameById();

      final data = await _reportService.fetchReportData(
        rangeStart: start,
        rangeEnd: end,
        employeeId: _employeeId,
      );

      if (!mounted) return;
      setState(() => _report = _applyEmployeeNames(data));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel() async {
    final t = AppLocalizations.of(context)!;
    final data = _report;
    if (data == null) return;

    try {
      // Filename rules:
      // - Daily:   meamore-report-dd-mm-yyyy.xlsx
      // - Period:  meamore-report-dd-mm-yyyy_dd-mm-yyyy.xlsx
      final start = data.rangeStart;
      final endInclusive = data.rangeEnd.subtract(const Duration(days: 1));
      final sameDay = start.year == endInclusive.year &&
          start.month == endInclusive.month &&
          start.day == endInclusive.day;

      final fileName = sameDay
          ? 'meamore-report-${_fmtDmy(start)}.xlsx'
          : 'meamore-report-${_fmtDmy(start)}_${_fmtDmy(endInclusive)}.xlsx';

      // IMPORTANT: On web, the `excel` package may trigger a download by itself.
      // The service will either:
      //   - download the file directly (returns null bytes), OR
      //   - return bytes (we download it once via saveBytesToFile).
      final bytes = await _reportService.exportToExcel(
        data,
        filename: fileName,
        isWeb: kIsWeb,
      );

      if (bytes != null) {
        final savedPath = await saveBytesToFile(bytes: bytes, filename: fileName);

        // Mobile (Android/iOS): open the system share/save sheet so the user can
        // choose “Save to Files” / Drive / WhatsApp etc. We first save into the
        // app Documents directory, so “Save” flows default to a documents-style
        // location.
        if (!kIsWeb) {
          await Share.shareXFiles(
            [XFile(savedPath)],
            subject: fileName,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.reportSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage(e.toString()))),
      );
    }
  }

  Widget _resultsArea(AppLocalizations t) {
    final report = _report;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (report == null) {
      return const SizedBox.shrink();
    }

    if (report.rows.isEmpty) {
      return Center(child: Text(t.reportNoTreatmentsInRange));
    }

    return ListView(
      children: [
        _SummaryCard(report: report),
        const SizedBox(height: 16),
        _EmployeeSummaryTable(report: report),
        const SizedBox(height: 16),
        _TreatmentsTable(report: report),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final (start, end) = _computeRange(_anchorDate, _period);
    final hasData = (_report?.rows.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(t.reportsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<_ReportPeriod>(
                    value: _period,
                    decoration: InputDecoration(labelText: t.reportPeriodLabel),
                    items: [
                      DropdownMenuItem(value: _ReportPeriod.daily, child: Text(t.reportPeriodDaily)),
                      DropdownMenuItem(value: _ReportPeriod.weekly, child: Text(t.reportPeriodWeekly)),
                      DropdownMenuItem(value: _ReportPeriod.monthly, child: Text(t.reportPeriodMonthly)),
                      DropdownMenuItem(value: _ReportPeriod.quarterly, child: Text(t.reportPeriodQuarterly)),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _period = v ?? _ReportPeriod.daily;
                        _report = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: t.reportDateLabel,
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(_fmtDate(_anchorDate)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            InputDecorator(
              decoration: InputDecoration(
                labelText: t.reportRangeLabel,
                border: const OutlineInputBorder(),
              ),
              child: Text('${_fmtDate(start)}  →  ${_fmtDate(end.subtract(const Duration(days: 1)))}'),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repo.streamAll(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const [];
                final employees = docs.map(Employee.fromDoc).toList()
                  ..sort((a, b) => a.displayName(t.noNameValue).compareTo(b.displayName(t.noNameValue)));

                return DropdownButtonFormField<String?>(
                  value: _employeeId,
                  decoration: InputDecoration(labelText: t.employeesTitle),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(t.reportAllEmployeesOption),
                    ),
                    ...employees.map((e) {
                      final employeeId = e.logicalEmployeeId.trim();
                      final name = EmployeeDisplay.name(e, t);
                      return DropdownMenuItem<String?>(
                        value: employeeId,
                        child: Text(name),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() {
                    _employeeId = v;
                    _report = null;
                  }),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _generatePreview,
                    icon: const Icon(Icons.analytics),
                    label: Text(t.reportGenerateAction),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (!_loading && hasData) ? _exportExcel : null,
                    icon: const Icon(Icons.table_view),
                    label: Text(t.reportGenerateExcelAction),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(child: _resultsArea(t)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});
  final TreatmentsReportData report;

  @override
  Widget build(BuildContext context) {
    final total = report.totalTreatments;
    final minutes = report.totalMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _Metric(title: 'Treatments', value: total.toString()),
            _Metric(title: 'Total minutes', value: minutes.toString()),
            _Metric(title: 'Employees', value: report.summaries.length.toString()),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelMedium),
        Text(value, style: theme.textTheme.headlineSmall),
      ],
    );
  }
}

class _EmployeeSummaryTable extends StatelessWidget {
  const _EmployeeSummaryTable({required this.report});
  final TreatmentsReportData report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Employee')),
              DataColumn(label: Text('Treatments'), numeric: true),
              DataColumn(label: Text('Total Minutes'), numeric: true),
            ],
            rows: report.summaries
                .map(
                  (s) => DataRow(
                    cells: [
                      DataCell(Text(s.employeeName)),
                      DataCell(Text(s.count.toString())),
                      DataCell(Text(s.totalMinutes.toString())),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _TreatmentsTable extends StatelessWidget {
  const _TreatmentsTable({required this.report});
  final TreatmentsReportData report;

  @override
  Widget build(BuildContext context) {
    final source = _TreatmentsDataSource(report.rows);
    return Card(
      child: PaginatedDataTable(
        header: const Text('Treatments'),
        rowsPerPage: 10,
        showFirstLastButtons: true,
        columns: const [
          DataColumn(label: Text('Ended')),
          DataColumn(label: Text('Minutes'), numeric: true),
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Dog')),
          DataColumn(label: Text('Breed')),
          DataColumn(label: Text('Owner')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Coat')),
        ],
        source: source,
      ),
    );
  }
}

class _TreatmentsDataSource extends DataTableSource {
  _TreatmentsDataSource(this._rows);

  final List<TreatmentReportRow> _rows;

  String _endedDate(TreatmentReportRow r) {
    final dt = r.endedAt;
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= _rows.length) return null;
    final r = _rows[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(_endedDate(r))),
        DataCell(Text(r.durationMinutes.toString())),
        DataCell(Text(r.employeeName)),
        DataCell(Text(r.dogName)),
        DataCell(Text(r.breed)),
        DataCell(Text(r.ownerName)),
        DataCell(Text(r.treatmentType)),
        DataCell(Text(r.coatCondition?.toString() ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rows.length;

  @override
  int get selectedRowCount => 0;
}
