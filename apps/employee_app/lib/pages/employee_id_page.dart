import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meamore_shared/l10n/app_localizations.dart';

import '../storage/employee_identity_store.dart';

class EmployeeIdPage extends StatefulWidget {
  const EmployeeIdPage({super.key});

  @override
  State<EmployeeIdPage> createState() => _EmployeeIdPageState();
}

class _EmployeeIdPageState extends State<EmployeeIdPage> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _valid(String s) => RegExp(r'^\d+$').hasMatch(s.trim());

  String? _shopIdFromRouteArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    return (args is String && args.trim().isNotEmpty) ? args.trim() : null;
  }

  Future<bool> _employeeExists({required String shopId, required String employeeId}) async {
    final ref = FirebaseFirestore.instance.doc('shops/$shopId/employees/$employeeId');
    final snap = await ref.get();
    return snap.exists;
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final id = _ctrl.text.trim();

    if (!_valid(id)) {
      setState(() => _error = t.errorEmployeeIdDigitsOnly);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      final shopId = _shopIdFromRouteArgs();
      if (shopId != null) {
        final exists = await _employeeExists(shopId: shopId, employeeId: id);
        if (!exists) {
          if (!mounted) return;
          setState(() {
            _error = t.errorEmployeeNotFound;
            _saving = false;
          });
          return;
        }
      }

      await EmployeeIdentityStore().setEmployeeId(id);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = t.errorEmployeeLoadFailed;
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.employeeSetupTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.employeeIdLabel,
                helperText: t.employeeIdHelp,
                errorText: _error,
              ),
              enabled: !_saving,
              onSubmitted: (_) {
                if (!_saving) _save();
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.continueAction),
            ),
          ],
        ),
      ),
    );
  }
}
