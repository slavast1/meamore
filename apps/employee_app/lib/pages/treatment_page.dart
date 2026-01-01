import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:meamore_shared/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer_queue_item.dart';
import '../models/treatment.dart';
import '../services/employee_firestore_service.dart';
import '../storage/employee_identity_store.dart';

class _ServiceItem {
  const _ServiceItem({required this.key, required this.value});

  final String key;
  final num value;

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

class TreatmentPage extends StatefulWidget {
  const TreatmentPage({
    super.key,
    required this.shopId,
    required this.customer,
  });

  final String shopId;
  final CustomerQueueItem customer;

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  String? _employeeId;
  String? _sessionId;

  bool _busy = false;
  bool _changed = false;

  final TextEditingController _dogCtrl = TextEditingController();
  final TextEditingController _breedCtrl = TextEditingController();
  final TextEditingController _ownerCtrl = TextEditingController();
  final TextEditingController _coatCtrl = TextEditingController();

  late final EmployeeFirestoreService _fs =
      EmployeeFirestoreService(shopId: widget.shopId);

  // Service list from Firestore: shops/meamore/services_list/{en|he}
  final List<_ServiceItem> _services = <_ServiceItem>[];
  String? _selectedServiceKey;
  num? _selectedServiceValue;
  bool _servicesLoading = true;
  String? _servicesError;
  String? _loadedLang;

  String _trimOrEmpty(String? s) => (s ?? '').trim();

  bool get _isMobileDevice {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _openPhoneDialer(String phoneNumber) async {
    // Only intended for mobile. Caller should guard.
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Non-fatal: silently ignore if device can't handle tel:.
    }
  }

  List<Widget> _buildAppointmentInfo(AppLocalizations t) {
    final serviceTitle = _trimOrEmpty(widget.customer.serviceTitle);
    final mobile = _trimOrEmpty(widget.customer.customerMobile);
    final remark = _trimOrEmpty(widget.customer.remark);
    if (serviceTitle.isEmpty && mobile.isEmpty && remark.isEmpty) {
      return const <Widget>[];
    }

    final rows = <Widget>[];
    if (serviceTitle.isNotEmpty) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.content_cut, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                serviceTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    if (mobile.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.phone, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: _isMobileDevice
                  ? InkWell(
                      onTap: () => _openPhoneDialer(mobile),
                      child: Text(
                        '${t.phoneLabel}: $mobile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text('${t.phoneLabel}: $mobile'),
            ),
          ],
        ),
      );
    }
    if (remark.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(remark)),
          ],
        ),
      );
    }

    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  @override
  void initState() {
    super.initState();
    _dogCtrl.text = widget.customer.dogName;
    _breedCtrl.text = widget.customer.breed;
    _ownerCtrl.text = widget.customer.ownerFullName;
    _loadEmployeeId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode.toLowerCase() == 'he'
        ? 'he'
        : 'en';
    if (_loadedLang != lang) {
      _loadedLang = lang;
      _loadServices(lang);
    }
  }

  @override
  void dispose() {
    _dogCtrl.dispose();
    _breedCtrl.dispose();
    _ownerCtrl.dispose();
    _coatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeId() async {
    final id = await EmployeeIdentityStore().getEmployeeId();
    if (!mounted) return;
    setState(() => _employeeId = id);
  }

  DocumentReference<Map<String, dynamic>> _servicesDoc(String lang) {
    return FirebaseFirestore.instance
        .collection('shops')
        .doc('meamore')
        .collection('services_list')
        .doc(lang);
  }

  Future<void> _loadServices(String lang) async {
    setState(() {
      _servicesLoading = true;
      _servicesError = null;
      _services.clear();
      _selectedServiceKey = null;
      _selectedServiceValue = null;
    });

    try {
      final snap = await _servicesDoc(lang).get();
      final data = snap.data() ?? <String, dynamic>{};
      final rawItems = (data['items'] as List<dynamic>?) ?? const <dynamic>[];

      final parsed = <_ServiceItem>[];
      for (final e in rawItems) {
        if (e is Map) {
          final key = (e['key'] ?? '').toString().trim();
          if (key.isEmpty) continue;
          final valRaw = e['value'];
          num val;
          if (valRaw is num) {
            val = valRaw;
          } else if (valRaw is String) {
            val = num.tryParse(valRaw) ?? 1;
          } else {
            val = 1;
          }
          parsed.add(_ServiceItem(key: key, value: val));
        }
      }

      if (!mounted) return;
      setState(() {
        _services
          ..clear()
          ..addAll(parsed);
        if (_services.isNotEmpty) {
          _selectedServiceKey = _services.first.key;
          _selectedServiceValue = _services.first.value;
        }
        _servicesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _servicesLoading = false;
        _servicesError = e.toString();
      });
    }
  }

  Future<void> _saveServicesToFirestore(String lang, List<_ServiceItem> items) async {
    final ref = _servicesDoc(lang);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(ref, {'items': items.map((e) => e.toJson()).toList()}, SetOptions(merge: true));
    });
  }

  Future<void> _addService() async {
    if (_loadedLang == null) return;
    final t = AppLocalizations.of(context)!;

    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.create),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: t.treatmentTypeLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(t.save)),
        ],
      ),
    );

    final name = result?.trim();
    if (name == null || name.isEmpty) return;

    // Prevent duplicates by key (case-insensitive)
    final exists = _services.any((s) => s.key.toLowerCase() == name.toLowerCase());
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorDogBreedRequired)), // existing generic error; no new strings
      );
      return;
    }

    final updated = List<_ServiceItem>.from(_services)..add(_ServiceItem(key: name, value: 1));
    await _saveServicesToFirestore(_loadedLang!, updated);

    if (!mounted) return;
    setState(() {
      _services
        ..clear()
        ..addAll(updated);
      _selectedServiceKey = name;
      _selectedServiceValue = 1;
    });
  }

  Future<void> _editService() async {
    if (_loadedLang == null) return;
    if (_selectedServiceKey == null) return;

    final t = AppLocalizations.of(context)!;
    final oldKey = _selectedServiceKey!;
    final oldItem = _services.firstWhere((e) => e.key == oldKey, orElse: () => _ServiceItem(key: oldKey, value: _selectedServiceValue ?? 1));

    final ctrl = TextEditingController(text: oldItem.key);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.edit),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: t.treatmentTypeLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(t.save)),
        ],
      ),
    );

    final name = result?.trim();
    if (name == null || name.isEmpty) return;

    final existsOther = _services.any((s) =>
        s.key.toLowerCase() == name.toLowerCase() &&
        s.key.toLowerCase() != oldKey.toLowerCase());
    if (existsOther) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorDogBreedRequired)), // existing generic error; no new strings
      );
      return;
    }

    final updated = _services.map((s) {
      if (s.key == oldKey) {
        return _ServiceItem(key: name, value: s.value);
      }
      return s;
    }).toList();

    await _saveServicesToFirestore(_loadedLang!, updated);

    if (!mounted) return;
    setState(() {
      _services
        ..clear()
        ..addAll(updated);
      _selectedServiceKey = name;
      _selectedServiceValue = oldItem.value;
    });
  }

  Future<void> _start() async {
    final t = AppLocalizations.of(context)!;
    if (_employeeId == null) return;

    final dogName = _dogCtrl.text.trim();
    final ownerName = _ownerCtrl.text.trim();
    if (dogName.isEmpty && ownerName.isEmpty) {
      final lang = Localizations.localeOf(context).languageCode;
      final msg = (lang == 'he')
          ? 'יש להזין שם כלב או שם בעלים.'
          : 'Dog name or owner name is required.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage(msg))),
      );
      return;
    }


    // Coat condition is optional.
    // If provided, it must be within the localized range (1..5).
    final coatText = _coatCtrl.text.trim();
    int? coat;
    if (coatText.isNotEmpty) {
      final coatNum = num.tryParse(coatText);
      if (coatNum == null || coatNum < 1 || coatNum > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errorCoatConditionRange)),
        );
        return;
      }
      coat = coatNum.toInt();
    }

    if (_selectedServiceKey == null) return;

    setState(() => _busy = true);

    try {
      final treatment = Treatment(
        employeeId: _employeeId!,
        employeeName: '',
        treatmentType: _selectedServiceKey!,
        dogName: dogName,
        breed: _breedCtrl.text.trim(),
        ownerFullName: ownerName,
        coatCondition: coat,
        startedAt: DateTime.now(),
      );

      final sessionId = await _fs.startTreatment(
        treatment: treatment,
        sessionIdOverride: widget.customer.id,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = sessionId;
        _busy = false;
        _changed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.treatmentInProgress)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorStartTreatmentFailed)),
      );
    }
  }

  Future<void> _finish() async {
    final t = AppLocalizations.of(context)!;
    if (_employeeId == null || _sessionId == null) return;

    setState(() => _busy = true);

    try {
      await _fs.finishTreatment(employeeId: _employeeId!, sessionId: _sessionId!);
      if (!mounted) return;

      setState(() {
        _busy = false;
        _changed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.treatmentSaved)),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorFinishTreatmentFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final started = _sessionId != null;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.treatmentTypeLabel)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._buildAppointmentInfo(t),
              TextField(
                controller: _dogCtrl,
                enabled: !started,
                decoration: InputDecoration(labelText: t.dogNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _breedCtrl,
                enabled: !started,
                decoration: InputDecoration(labelText: t.dogBreedLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ownerCtrl,
                enabled: !started,
                decoration: InputDecoration(labelText: t.dogOwnerNameLabel),
              ),
              const SizedBox(height: 16),

              if (_servicesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_servicesError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _servicesError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedServiceKey,
                        items: _services
                            .map((x) => DropdownMenuItem(value: x.key, child: Text(x.key)))
                            .toList(),
                        onChanged: started
                            ? null
                            : (v) {
                                final key = v;
                                if (key == null) return;
                                final item = _services.firstWhere((e) => e.key == key);
                                setState(() {
                                  _selectedServiceKey = item.key;
                                  _selectedServiceValue = item.value;
                                });
                              },
                        decoration: InputDecoration(labelText: t.treatmentTypeLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: t.create,
                      onPressed: started ? null : _addService,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: t.edit,
                      onPressed: started || _selectedServiceKey == null ? null : _editService,
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              TextField(
                controller: _coatCtrl,
                keyboardType: TextInputType.number,
                enabled: !started,
                decoration: InputDecoration(labelText: t.coatConditionLabel),
              ),

              const SizedBox(height: 24), // lifted up (no bottom-stuck button)

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : (started ? _finish : _start),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(started ? t.finishTreatmentAction : t.startTreatmentAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}