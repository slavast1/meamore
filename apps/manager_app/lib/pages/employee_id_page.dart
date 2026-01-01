import 'package:flutter/material.dart';
import 'package:meamore_shared/l10n/app_localizations.dart';

class EmployeeIdPage extends StatefulWidget {
  const EmployeeIdPage({
    super.key,
    required this.shopId,
    required this.onSaved,
  });

  final String shopId;
  final void Function(String employeeId) onSaved;

  @override
  State<EmployeeIdPage> createState() => _EmployeeIdPageState();
}

class _EmployeeIdPageState extends State<EmployeeIdPage> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _digitsOnly(String s) => RegExp(r'^\d+$').hasMatch(s);

  void _save() {
    final t = AppLocalizations.of(context)!;
    final id = _ctrl.text.trim();

    if (id.isEmpty) {
      setState(() => _err = t.errorIdRequired);
      return;
    }
    if (!_digitsOnly(id)) {
      setState(() => _err = t.errorIdDigitsOnly);
      return;
    }

    widget.onSaved(id);
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
              decoration: InputDecoration(
                labelText: t.idNumberDigitsOnlyLabel,
                errorText: _err,
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(t.save)),
          ],
        ),
      ),
    );
  }
}
