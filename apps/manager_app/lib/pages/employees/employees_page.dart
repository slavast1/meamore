import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore/models/edit_employee_result.dart';
import 'package:meamore/models/employee_display.dart';
import 'package:meamore/models/employee_sort.dart';
import 'package:meamore/pages/employees/edit_employee_dialog.dart';
import 'package:meamore/pages/employees/employee_status_page.dart';
import 'package:meamore/pages/reports/reports_page.dart';
import 'package:meamore/services/employees_repository.dart';
import 'package:meamore/widgets/language_menu_button.dart';
import 'package:meamore/widgets/status_chip.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key, required this.shopId});
  final String shopId;

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final Set<String> _selected = {};
  late final EmployeesRepository _repo = EmployeesRepository(shopId: widget.shopId);

  void _toggleSelected(String employeeId, bool value) {
    setState(() => value ? _selected.add(employeeId) : _selected.remove(employeeId));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    if (_selected.isEmpty) return;

    final t = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteEmployeesTitle),
        content: Text(t.deleteEmployeesConfirm(_selected.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.delete)),
        ],
      ),
    );

    if (ok != true) return;

    await _repo.deleteMany(_selected);
    setState(() => _selected.clear());
  }

  Future<void> _editSelectedOne(BuildContext context) async {
    if (_selected.length != 1) return;

    final employeeId = _selected.first;

    final snap = await _repo.getOne(employeeId);
    if (!snap.exists) return;

    final employee = Employee.fromDoc(snap);

    final result = await showDialog<EditEmployeeResult>(
      context: context,
      builder: (_) => EditEmployeeDialog(
        initialEmployeeId: employee.logicalEmployeeId,
        initialFirstName: employee.firstName,
        initialLastName: employee.lastName,
        initialLegacyName: employee.legacyName ?? '',
        initialPhone: employee.phone,
      ),
    );

    if (result == null) return;

    await _repo.updateBasicInfo(
      employeeId: employeeId,
      firstName: result.firstName,
      lastName: result.lastName,
      phone: result.phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final canEdit = _selected.length == 1;
    final canDelete = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.employeesTitle),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportsPage(shopId: widget.shopId)),
              );
            },
            icon: const Icon(Icons.table_view),
            tooltip: t.reportsTitle,
          ),
          IconButton(
            onPressed: canEdit ? () => _editSelectedOne(context) : null,
            icon: const Icon(Icons.edit),
            tooltip: t.edit,
          ),
          IconButton(
            onPressed: canDelete ? () => _deleteSelected(context) : null,
            icon: const Icon(Icons.delete),
            tooltip: t.delete,
          ),
          const LanguageMenuButton(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _repo.streamAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(t.errorWithMessage(snapshot.error.toString()), textAlign: TextAlign.start));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final employees = snapshot.data!.docs.map(Employee.fromDoc).toList();
          employees.sort(EmployeeSort.byLastThenFirst);

          if (employees.isEmpty) return Center(child: Text(t.noEmployeesYet));

          return ListView.separated(
            itemCount: employees.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = employees[i];

              final selected = _selected.contains(e.logicalEmployeeId);
              final name = EmployeeDisplay.name(e, t);
//              final statusText = StatusLocalizer.toText(e.status, t);
              final statusText = StatusLocalizer.toText(EmployeeStatus.fromRaw(e.status), t);

              return ListTile(
                leading: Checkbox(
                  value: selected,
                  onChanged: (v) => _toggleSelected(e.logicalEmployeeId, v ?? false),
                ),
                title: Text(name),
                trailing: StatusChip(text: statusText),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmployeeStatusPage(
                        shopId: widget.shopId,
                        employeeId: e.logicalEmployeeId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/addEmployee'),
        tooltip: t.addEmployeeTitle,
        child: const Icon(Icons.add),
      ),
    );
  }
}
