import 'package:flutter/material.dart';

import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore/models/edit_employee_result.dart';
import 'package:meamore_shared/utils/validators.dart';

class EditEmployeeDialog extends StatefulWidget {
  const EditEmployeeDialog({
    super.key,
    required this.initialEmployeeId,
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialLegacyName,
    required this.initialPhone,
  });

  final String initialEmployeeId; // docId logical key (read-only)
  final String initialFirstName;
  final String initialLastName;
  final String initialLegacyName;
  final String initialPhone;

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _employeeIdCtrl;
  late final TextEditingController _phoneCtrl;

  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.initialFirstName);
    _lastNameCtrl = TextEditingController(text: widget.initialLastName);
    _employeeIdCtrl = TextEditingController(text: widget.initialEmployeeId);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);

    // Legacy fallback
    if (_firstNameCtrl.text.trim().isEmpty &&
        _lastNameCtrl.text.trim().isEmpty &&
        widget.initialLegacyName.trim().isNotEmpty) {
      _firstNameCtrl.text = widget.initialLegacyName.trim();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _employeeIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final t = AppLocalizations.of(context)!;

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _error = t.errorFirstLastRequired);
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = t.errorPhoneRequired);
      return;
    }
    if (!Validators.isDigitsOnly(phone)) {
      setState(() => _error = t.errorPhoneDigitsOnly);
      return;
    }

    Navigator.pop(
      context,
      EditEmployeeResult(firstName: firstName, lastName: lastName, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(t.editEmployeeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _employeeIdCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: t.idNumberLabel,
              helperText: t.idCannotBeChanged, // add to ARB if not yet
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _firstNameCtrl,
            decoration: InputDecoration(labelText: t.firstNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameCtrl,
            decoration: InputDecoration(labelText: t.lastNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: InputDecoration(labelText: t.phoneDigitsOnlyLabel),
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _submit, child: Text(t.save)),
      ],
    );
  }
}
