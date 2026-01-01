import 'package:flutter/material.dart';
import 'package:meamore_shared/meamore_shared.dart';

import '../storage/employee_identity_store.dart';

class EnterEmployeeIdPage extends StatefulWidget {
  const EnterEmployeeIdPage({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<EnterEmployeeIdPage> createState() => _EnterEmployeeIdPageState();
}

class _EnterEmployeeIdPageState extends State<EnterEmployeeIdPage> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final id = _ctrl.text.trim();

    if (id.isEmpty || !Validators.isDigitsOnly(id)) {
      setState(() => _error = t.errorIdDigitsOnly);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    await EmployeeIdentityStore().setEmployeeId(id);

    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.idNumberDigitsOnlyLabel),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}
