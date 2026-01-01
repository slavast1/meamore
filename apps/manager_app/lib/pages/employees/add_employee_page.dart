import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';

import 'package:meamore_shared/meamore_shared.dart';
import 'package:meamore/services/employees_repository.dart';
import 'package:meamore_shared/utils/validators.dart';
import 'package:meamore/widgets/language_menu_button.dart';

class AddEmployeePage extends StatefulWidget {
  const AddEmployeePage({super.key, required this.shopId});
  final String shopId;

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _idCtrl = TextEditingController(); // logical employeeId (digits only)
  final _phoneCtrl = TextEditingController(); // digits only, mandatory

  bool _saving = false;
  String? _inviteCode;
  String? _error;

  late final EmployeesRepository _repo = EmployeesRepository(shopId: widget.shopId);

  // Native contact picker (opens OS UI)
  final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _generateInviteCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _clearForm() {
    _firstNameCtrl.clear();
    _lastNameCtrl.clear();
    _idCtrl.clear();
    _phoneCtrl.clear();
    setState(() {
      _inviteCode = null;
      _error = null;
    });
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D+'), '');

  void _setNameFromFullName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return;

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) return;

    final first = parts.first.trim();
    final last = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';

    if (first.isNotEmpty) _firstNameCtrl.text = first;
    if (last.isNotEmpty) _lastNameCtrl.text = last;
  }

  Future<void> _pickFromContacts() async {
    final t = AppLocalizations.of(context)!;

    if (kIsWeb) {
      // This plugin is not implemented on web.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Contacts not supported on web'))),
      );
      return;
    }

    try {
      // IMPORTANT: use selectPhoneNumber() so the user picks a phone number
      // and we reliably get selectedPhoneNumber.
      final Contact? contact = await _contactPicker.selectPhoneNumber();
      if (!mounted || contact == null) return;

      final fullName = (contact.fullName ?? '').trim();
      if (fullName.isNotEmpty) {
        _setNameFromFullName(fullName);
      }

      // ✅ Correct fields for this plugin:
      // - selectedPhoneNumber: when using selectPhoneNumber()
      // - phoneNumbers: list (iOS: all numbers; Android: selected number only)
      final phoneRaw =
      (contact.selectedPhoneNumber ?? (contact.phoneNumbers?.isNotEmpty == true ? contact.phoneNumbers!.first : ''))
          .trim();

      final phoneDigits = _digitsOnly(phoneRaw);

      if (phoneDigits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.noPhoneValue)),
        );
        return;
      }

      setState(() {
        _phoneCtrl.text = phoneDigits;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Contacts error: $e'))),
      );
    }
  }

  Future<void> _createEmployee() async {
    final t = AppLocalizations.of(context)!;

    setState(() {
      _saving = true;
      _error = null;
      _inviteCode = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final employeeId = _idCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() {
        _saving = false;
        _error = t.errorFirstLastRequired;
      });
      return;
    }
    if (employeeId.isEmpty) {
      setState(() {
        _saving = false;
        _error = t.errorIdRequired;
      });
      return;
    }
    if (!Validators.isDigitsOnly(employeeId)) {
      setState(() {
        _saving = false;
        _error = t.errorIdDigitsOnly;
      });
      return;
    }
    if (phone.isEmpty) {
      setState(() {
        _saving = false;
        _error = t.errorPhoneRequired;
      });
      return;
    }
    if (!Validators.isDigitsOnly(phone)) {
      setState(() {
        _saving = false;
        _error = t.errorPhoneDigitsOnly;
      });
      return;
    }

    final inviteCode = _generateInviteCode(6);

    try {
      await _repo.createEmployee(
        employeeId: employeeId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        inviteCode: inviteCode,
      );

      setState(() {
        _saving = false;
        _inviteCode = inviteCode;
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().contains('EMPLOYEE_ID_EXISTS')
            ? 'Employee ID already exists.' // (you can add to ARB later)
            : t.errorWithMessage(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.addEmployeeTitle),
        actions: const [LanguageMenuButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _firstNameCtrl,
              decoration: InputDecoration(labelText: t.firstNameLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameCtrl,
              decoration: InputDecoration(labelText: t.lastNameLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(labelText: t.idNumberDigitsOnlyLabel),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(labelText: t.phoneDigitsOnlyLabel),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),

            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _saving ? null : _pickFromContacts,
                icon: const Icon(Icons.contacts),
                // You can localize later (e.g., t.pickFromContacts)
                label: const Text('Pick from contacts'),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _createEmployee,
                    child: _saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(t.create),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _clearForm,
                    child: Text(t.clear),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_inviteCode != null)
              SelectableText(
                '${t.inviteCodeText(_inviteCode!)}\n\n${t.inviteCodeHelp}',
                textAlign: TextAlign.start,
              ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
