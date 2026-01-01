import 'package:flutter/material.dart';
import 'package:meamore_shared/l10n/app_localizations.dart';

import '../services/api_config_service.dart';
import '../services/employee_firestore_service.dart';
import '../services/queue_api.dart';

class TreatmentPage extends StatefulWidget {
  const TreatmentPage({
    super.key,
    required this.shopId,
    required this.employeeId,
    required this.onChangeEmployee,
  });

  final String shopId;
  final String employeeId;
  final VoidCallback onChangeEmployee;

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  late final _cfg = ApiConfigService(shopId: widget.shopId);
  late final _fs = EmployeeFirestoreService(shopId: widget.shopId);

  QueueApi _api = QueueApiSimulator();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _employee;
  List<QueueCustomer> _queue = [];

  QueueCustomer? _selectedCustomer;

  final _dogNameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();

  final _coatCtrl = TextEditingController(); // optional
  String? _treatmentType;
  String? _activeTreatmentId;

  bool _busyAction = false;

  static const treatmentTypes = <String>[
    'Wash',
    'Haircut',
    'Nails',
    'Full Grooming',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _dogNameCtrl.dispose();
    _breedCtrl.dispose();
    _ownerCtrl.dispose();
    _coatCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // read URL from DB (not used yet; switch to real api later)
      await _cfg.fetchQueueApiUrl();

      final emp = await _fs.loadEmployee(widget.employeeId);
      if (emp == null) {
        setState(() {
          _loading = false;
          _error = 'Employee not found';
        });
        return;
      }

      final queue = await _api.fetchQueue();

      setState(() {
        _employee = emp;
        _queue = queue;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyCustomer(QueueCustomer c) {
    _selectedCustomer = c;
    _dogNameCtrl.text = c.dogName;
    _breedCtrl.text = c.breed;
    _ownerCtrl.text = c.ownerFullName;
  }

  int _coatValueOrDefault() {
    // optional manual; default 3 if empty/invalid
    final v = int.tryParse(_coatCtrl.text.trim());
    if (v == null) return 3;
    if (v < 1) return 1;
    if (v > 5) return 5;
    return v;
  }

  String _employeeFullNameOrId() {
    final first = (_employee?['firstName'] ?? '').toString().trim();
    final last = (_employee?['lastName'] ?? '').toString().trim();
    final name = ('$last $first').trim();
    return name.isEmpty ? widget.employeeId : name;
  }

  Future<void> _start() async {
    final t = AppLocalizations.of(context)!;
    if (_busyAction) return;

    final type = _treatmentType;
    if (type == null || type.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Pick treatment type'))),
      );
      return;
    }

    final dogName = _dogNameCtrl.text.trim();
    final breed = _breedCtrl.text.trim();
    final owner = _ownerCtrl.text.trim();

    if (dogName.isEmpty || breed.isEmpty || owner.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Dog/Breed/Owner required'))),
      );
      return;
    }

    setState(() => _busyAction = true);
    try {
      final id = await _fs.startTreatment(
        employeeId: widget.employeeId,
        employeeName: _employeeFullNameOrId(),
        dogName: dogName,
        breed: breed,
        ownerName: owner,
        treatmentType: type,
        coatCondition: _coatValueOrDefault(),
      );

      setState(() {
        _activeTreatmentId = id;
        _busyAction = false;
      });
    } catch (e) {
      setState(() => _busyAction = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage(e.toString()))),
      );
    }
  }

  Future<void> _finish() async {
    final t = AppLocalizations.of(context)!;
    if (_busyAction) return;
    final id = _activeTreatmentId;
    if (id == null) return;

    setState(() => _busyAction = true);
    try {
      await _fs.finishTreatment(employeeId: widget.employeeId, treatmentId: id);
      setState(() {
        _activeTreatmentId = null;
        _busyAction = false;
      });
    } catch (e) {
      setState(() => _busyAction = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.appTitle)),
        body: Center(child: Text(_error!)),
      );
    }

    final isBusy = _activeTreatmentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.appTitle} • ${widget.employeeId}'),
        actions: [
          TextButton(
            onPressed: widget.onChangeEmployee,
            child: const Text('Change ID'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Queue', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (_queue.isEmpty)
              Text(t.notAvailableValue)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _queue.map((c) {
                  final selected = identical(_selectedCustomer, c);
                  return ChoiceChip(
                    label: Text('${c.dogName} (${c.breed})'),
                    selected: selected,
                    onSelected: (_) => setState(() => _applyCustomer(c)),
                  );
                }).toList(),
              ),

            const Divider(height: 32),

            DropdownButtonFormField<String>(
              value: _treatmentType,
              items: treatmentTypes
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: isBusy ? null : (v) => setState(() => _treatmentType = v),
              decoration: InputDecoration(
                labelText: 'Treatment type',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _dogNameCtrl,
              enabled: !isBusy,
              decoration: const InputDecoration(labelText: "Dog's name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedCtrl,
              enabled: !isBusy,
              decoration: const InputDecoration(labelText: "Breed"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerCtrl,
              enabled: !isBusy,
              decoration: const InputDecoration(labelText: "Owner full name"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _coatCtrl,
              enabled: !isBusy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Coat condition (1-5) (optional)",
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (isBusy || _busyAction) ? null : _start,
                    child: _busyAction
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (!isBusy || _busyAction) ? null : _finish,
                    child: const Text('Finish'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text('Status: ${isBusy ? t.statusBusy : t.statusIdle}'),
          ],
        ),
      ),
    );
  }
}
