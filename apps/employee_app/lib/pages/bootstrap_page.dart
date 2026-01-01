import 'package:flutter/material.dart';

import '../storage/employee_identity_store.dart';
import 'employee_id_page.dart';
import 'treatment_page.dart';

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key, required this.shopId});
  final String shopId;

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  final _store = EmployeeIdentityStore();
  String? _employeeId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await _store.loadEmployeeId();
    if (!mounted) return;
    setState(() => _employeeId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (_employeeId == null) {
      return EmployeeIdPage(
        shopId: widget.shopId,
        onSaved: (id) async {
          await _store.continueAction(id);
          if (!mounted) return;
          setState(() => _employeeId = id);
        },
      );
    }

    return TreatmentPage(
      shopId: widget.shopId,
      employeeId: _employeeId!,
      onChangeEmployee: () async {
        await _store.clearEmployeeId();
        if (!mounted) return;
        setState(() => _employeeId = null);
      },
    );
  }
}
