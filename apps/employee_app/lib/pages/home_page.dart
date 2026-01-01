import 'package:flutter/material.dart';
import 'package:meamore_shared/app_locale.dart';
import 'package:meamore_shared/l10n/app_localizations.dart';

import '../models/customer_queue_item.dart';
import 'package:meamore_shared/models/employee.dart';
import '../models/treatment.dart';
import '../services/employee_firestore_service.dart';
import '../services/queue_service.dart';
import '../services/treatment_status_service.dart';
import '../storage/employee_identity_store.dart';
import 'treatment_page.dart';

enum _Col { dogName, breed, ownerFullName, treatmentType, employeeName }
enum _QCol { dogName, breed, ownerFullName }
enum _HomeMenu { changeEmployee, langEn, langHe }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.shopId});
  final String shopId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final QueueService _queue = QueueService(shopId: widget.shopId);
  late final TreatmentStatusService _status = TreatmentStatusService(shopId: widget.shopId);
  late final EmployeeFirestoreService _firestore = EmployeeFirestoreService(shopId: widget.shopId);

  List<CustomerQueueItem>? _queueItems; // null = loading
  List<Treatment> _busy = const [];
  List<Treatment> _treatedToday = const [];
  String? _error;

  Employee? _employee;
  String? _employeeId;

  final Set<String> _selectedBusySessionIds = {};
  final Set<String> _selectedTreatedSessionIds = {};
  final Set<String> _selectedDoneByMeSessionIds = {};

  bool _finishingBusy = false;
final Map<_Col, Set<String>?> _busyColumnFilters = {
  for (final c in _Col.values) c: null,
};
final Map<_Col, Set<String>?> _treatedColumnFilters = {
  for (final c in _Col.values) c: null,
};
final Map<_QCol, Set<String>?> _queueColumnFilters = {
  for (final c in _QCol.values) c: null,
};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(String dogName, String breed, String owner) {
    return '${dogName.trim().toLowerCase()}|${breed.trim().toLowerCase()}|${owner.trim().toLowerCase()}';
  }

  // REST appointments provide a stable `id`. Use it as our primary key.
  String _keyFromQueue(CustomerQueueItem q) => q.id;
  String _keyFromTreatment(Treatment t) => t.id;


  String _norm(String s) => s.trim().toLowerCase();
  bool _matchesQueue(CustomerQueueItem q) => true;
bool _matchesTreatment(Treatment t) => true;
String _colValue(Treatment t, _Col col) {
  switch (col) {
    case _Col.dogName:
      return t.dogName;
    case _Col.breed:
      return t.breed;
    case _Col.ownerFullName:
      return t.ownerFullName;
    case _Col.treatmentType:
      return t.treatmentType;
    case _Col.employeeName:
      return t.employeeName;
  }
}

bool _passesColumnFilters(Treatment t, Map<_Col, Set<String>?> filters) {
  for (final col in _Col.values) {
    final selected = filters[col];
    if (selected == null) continue; // no filter on this column
    final v = _colValue(t, col).trim();
    if (!selected.contains(v)) return false;
  }
  return true;
}

bool _passesFiltersExcept(Treatment t, Map<_Col, Set<String>?> filters, _Col except) {
  for (final col in _Col.values) {
    if (col == except) continue;
    final selected = filters[col];
    if (selected == null) continue;
    final v = _colValue(t, col).trim();
    if (!selected.contains(v)) return false;
  }
  return true;
}

List<Treatment> _rowsForBusyFilter(_Col col) {
  return _busy.where((tr) => _matchesTreatment(tr) && _passesFiltersExcept(tr, _busyColumnFilters, col)).toList();
}

List<Treatment> _rowsForTreatedFilter(_Col col) {
  return _treatedToday.where((tr) => _matchesTreatment(tr) && _passesFiltersExcept(tr, _treatedColumnFilters, col)).toList();
}

Future<void> _openColumnFilterDialog({
  required String columnLabel,
  required _Col col,
  required bool forBusy,
}) async {
  final filters = forBusy ? _busyColumnFilters : _treatedColumnFilters;
  final rows = forBusy ? _rowsForBusyFilter(col) : _rowsForTreatedFilter(col);

  final values = rows.map((r) => _colValue(r, col).trim()).toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  // If there are no rows, there's nothing meaningful to filter.
  if (values.isEmpty) return;

  final current = filters[col];
  final selectedInitial = current == null ? values.toSet() : {...current};

  final result = await showDialog<Set<String>?>(
    context: context,
    builder: (ctx) {
      final ml = MaterialLocalizations.of(ctx);
      var selected = selectedInitial.toSet();

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final allSelected = selected.length == values.length;

          return AlertDialog(
            title: Text(columnLabel),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    value: allSelected,
                    title: Text(ml.selectAllButtonLabel),
                    onChanged: (v) {
                      setLocal(() {
                        if (v == true) {
                          selected = values.toSet();
                        } else {
                          // keep at least one value selected (Excel doesn't allow an empty selection by default)
                          selected = values.toSet();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1),
                  for (final v in values)
                    CheckboxListTile(
                      value: selected.contains(v),
                      title: Text(v.isEmpty ? '—' : v),
                      onChanged: (checked) {
                        setLocal(() {
                          if (checked == true) {
                            selected.add(v);
                          } else {
                            // prevent empty selection
                            if (selected.length > 1) {
                              selected.remove(v);
                            }
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(ml.cancelButtonLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(values.toSet()),
                child: Text(ml.selectAllButtonLabel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: Text(ml.okButtonLabel),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || result == null) return;

  setState(() {
    // No filter if all values are selected.
    filters[col] = result.length == values.length ? null : result;

    // Prune selections that are no longer visible.
    final busyVisibleIds = _busy.where((tr) => _matchesTreatment(tr) && _passesColumnFilters(tr, _busyColumnFilters)).map((e) => e.id).toSet();
    _selectedBusySessionIds.removeWhere((id) => !busyVisibleIds.contains(id));

    final treatedVisibleIds =
        _treatedToday.where((tr) => _matchesTreatment(tr) && _passesColumnFilters(tr, _treatedColumnFilters)).map((e) => e.id).toSet();
    _selectedTreatedSessionIds.removeWhere((id) => !treatedVisibleIds.contains(id));
  });
}


String _qColValue(CustomerQueueItem q, _QCol col) {
  switch (col) {
    case _QCol.dogName:
      return q.dogName;
    case _QCol.breed:
      return q.breed;
    case _QCol.ownerFullName:
      return q.ownerFullName;
  }
}

bool _passesQueueColumnFilters(CustomerQueueItem q, Map<_QCol, Set<String>?> filters) {
  for (final col in _QCol.values) {
    final selected = filters[col];
    if (selected == null) continue;
    final v = _qColValue(q, col).trim();
    if (!selected.contains(v)) return false;
  }
  return true;
}

bool _passesQueueFiltersExcept(CustomerQueueItem q, Map<_QCol, Set<String>?> filters, _QCol except) {
  for (final col in _QCol.values) {
    if (col == except) continue;
    final selected = filters[col];
    if (selected == null) continue;
    final v = _qColValue(q, col).trim();
    if (!selected.contains(v)) return false;
  }
  return true;
}

List<CustomerQueueItem> _rowsForQueueFilter(_QCol col) {
  final items = _queueItems ?? const <CustomerQueueItem>[];
  return items.where((q) => _passesQueueFiltersExcept(q, _queueColumnFilters, col)).toList();
}

Future<void> _openQueueColumnFilterDialog({
  required String columnLabel,
  required _QCol col,
}) async {
  final rows = _rowsForQueueFilter(col);

  final values = rows.map((r) => _qColValue(r, col).trim()).toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  if (values.isEmpty) return;

  final current = _queueColumnFilters[col];
  final selectedInitial = current == null ? values.toSet() : {...current};

  final result = await showDialog<Set<String>?>(
    context: context,
    builder: (ctx) {
      final ml = MaterialLocalizations.of(ctx);
      var selected = selectedInitial.toSet();

      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final allSelected = selected.length == values.length;

          return AlertDialog(
            title: Text(columnLabel),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(
                    value: allSelected,
                    title: Text(ml.selectAllButtonLabel),
                    onChanged: (v) {
                      setLocal(() {
                        selected = values.toSet();
                      });
                    },
                  ),
                  const Divider(height: 1),
                  for (final v in values)
                    CheckboxListTile(
                      value: selected.contains(v),
                      title: Text(v.isEmpty ? '—' : v),
                      onChanged: (checked) {
                        setLocal(() {
                          if (checked == true) {
                            selected.add(v);
                          } else {
                            if (selected.length > 1) selected.remove(v);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(ml.cancelButtonLabel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(selected),
                child: Text(ml.okButtonLabel),
              ),
            ],
          );
        },
      );
    },
  );

  if (!mounted || result == null) return;

  setState(() {
    _queueColumnFilters[col] = result.length == values.length ? null : result;
  });
}



Widget _headerCellWithFilter({
  required String label,
  required _Col col,
  required bool forBusy,
}) {
  final active =
      (forBusy ? _busyColumnFilters[col] : _treatedColumnFilters[col]) != null;

  return InkWell(
    onTap: () => _openColumnFilterDialog(columnLabel: label, col: col, forBusy: forBusy),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.filter_list,
          size: 18,
          color: active ? Theme.of(context).colorScheme.primary : Colors.black54,
        ),
      ],
    ),
  );
}



  Future<void> _load() async {
    setState(() {
      _queueItems = null;
      _error = null;
    });

    try {
      // Identity + employee
      final employeeId = await EmployeeIdentityStore().getEmployeeId();
      final emp = (employeeId == null) ? null : await _firestore.fetchEmployee(employeeId);

      // Queue + treatment status
      final queueItems = await _queue.fetchQueue();
      final busy = await _status.fetchOpenTreatments();
      final treatedToday = await _status.fetchTreatmentsFinishedToday();

      final busyKeys = busy.map(_keyFromTreatment).toSet();
      final treatedKeys = treatedToday.map(_keyFromTreatment).toSet();

      // Remove dogs that are busy or treated-today from the waiting queue list.
      final filteredQueue = queueItems.where((q) {
        final k = _keyFromQueue(q);
        return !busyKeys.contains(k) && !treatedKeys.contains(k);
      }).toList();

      if (!mounted) return;
      setState(() {
        _employeeId = employeeId;
        _employee = emp;
        _busy = busy;
        _treatedToday = treatedToday;
        _queueItems = filteredQueue;
        _selectedBusySessionIds.clear();
        _selectedTreatedSessionIds.clear();
        _selectedDoneByMeSessionIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _queueItems = const [];
        _busy = const [];
        _treatedToday = const [];
      });
    }
  }

  String _formatDuration(Duration d) {
    final totalMinutes = d.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  String _treatmentTime(Treatment t) {
    final s = t.startedAt;
    final e = t.finishedAt;
    if (s == null || e == null) return '-';
    final d = e.difference(s);
    if (d.isNegative) return '-';
    return _formatDuration(d);
  }

  bool _canFinish(Treatment t) {
    final me = _employeeId;
    if (me == null) return false;
    return t.employeeId == me;
  }

  Future<void> _finishSelectedBusy() async {
    final t = AppLocalizations.of(context)!;
    final me = _employeeId;
    if (me == null) return;

    final ids = _selectedBusySessionIds.toList();
    if (ids.isEmpty) return;

    final byId = {for (final x in _busy) x.id: x};
    final owned = ids.where((id) => byId[id]?.employeeId == me).toList();
    if (owned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Select rows owned by you'))),
      );
      return;
    }

    setState(() => _finishingBusy = true);
    try {
      for (final id in owned) {
        await _firestore.finishTreatment(sessionId: id, employeeId: me);
      }
      if (!mounted) return;
      setState(() {
        _finishingBusy = false;
        _selectedBusySessionIds.clear();
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _finishingBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errorWithMessage('Finish failed: $e'))),
      );
    }
  }

  Future<void> _returnTreatedToQueue() async {
    final ids = _selectedTreatedSessionIds.toList();
    if (ids.isEmpty) return;

    final byId = {for (final x in _treatedToday) x.id: x};
    final picked = ids.map((id) => byId[id]).whereType<Treatment>().toList();
    for (final tr in picked) {
      await _queue.addToQueue(
        CustomerQueueItem(
          id: tr.id,
          dogName: tr.dogName,
          breed: tr.breed,
          ownerFullName: tr.ownerFullName,
        ),
      );
    }

    await _status.deleteTreatments(ids);

    if (!mounted) return;
    setState(() {
      _treatedToday = _treatedToday.where((x) => !ids.contains(x.id)).toList();
      _selectedTreatedSessionIds.clear();
      _selectedDoneByMeSessionIds.removeAll(ids);
    });
    await _load();
  }

  Future<void> _removeFromTreatedToday() async {
    final ids = _selectedTreatedSessionIds.toList();
    if (ids.isEmpty) return;

    try {
      await _status.deleteTreatments(ids);
      if (!mounted) return;
      setState(() {
        _selectedTreatedSessionIds.clear();
        _selectedDoneByMeSessionIds.clear();
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
      );
    }
  }


  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }
  TableRow _headerRow(List<Widget> cells) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: cells
          .map(
            (w) => Padding(
              padding: const EdgeInsets.all(8),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontWeight: FontWeight.w700),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }


  TableRow _cellRow(List<Widget> cells) {
    return TableRow(
      children: cells
          .map(
            (w) {
              // On mobile, Checkbox has a larger minimum tap target. If we use
              // the same padding as text cells, the fixed checkbox column can
              // overflow and distort the table. Keep checkbox cells tighter.
              final isCheckbox = w is Checkbox;
              final padding = isCheckbox
                  ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0)
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
              final child = isCheckbox ? Center(child: w) : w;
              return Padding(padding: padding, child: child);
            },
          )
          .toList(),
    );
  }


Widget _cellText(String v, {int maxLines = 1}) {
  return Text(
    v,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

  bool _isCompactLayout(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Treat phones (even in landscape) as compact to avoid cramped/"distorted"
    // table layouts on Android/iOS.
    return mq.size.shortestSide < 600;
  }

  String _colLabel(AppLocalizations t, _Col col) {
    switch (col) {
      case _Col.dogName:
        return t.dogNameLabel;
      case _Col.breed:
      return t.dogBreedLabel;
      case _Col.ownerFullName:
      return t.dogOwnerNameLabel;
      case _Col.treatmentType:
      return t.treatmentTypeLabel;
      case _Col.employeeName:
        return t.employeesTitle;
    }
  }



  String _qColLabel(AppLocalizations t, _QCol col) {
    switch (col) {
      case _QCol.dogName:
        return t.dogNameLabel;
      case _QCol.breed:
        return t.dogBreedLabel;
      case _QCol.ownerFullName:
        return t.dogOwnerNameLabel;
    }
  }

  Widget _queueFiltersChipsRow(AppLocalizations t) {
    bool active(_QCol c) => _queueColumnFilters[c] != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _QCol.values)
          FilterChip(
            label: Text(_qColLabel(t, c)),
            selected: active(c),
            onSelected: (_) => _openQueueColumnFilterDialog(
              columnLabel: _qColLabel(t, c),
              col: c,
            ),
          ),
      ],
    );
  }

  Widget _filtersChipsRow(AppLocalizations t, {required bool forBusy}) {
    bool active(_Col c) =>
        (forBusy ? _busyColumnFilters[c] : _treatedColumnFilters[c]) != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _Col.values)
          FilterChip(
            label: Text(_colLabel(t, c)),
            selected: active(c),
            onSelected: (_) => _openColumnFilterDialog(
              columnLabel: _colLabel(t, c),
              col: c,
              forBusy: forBusy,
            ),
          ),
      ],
    );
  }

  Widget _selectAllRow({
    required bool enabled,
    required bool? value,
    required VoidCallback? onSelectAll,
  }) {
    final ml = MaterialLocalizations.of(context);
    return Row(
      children: [
        Checkbox(
          tristate: true,
          value: enabled ? value : false,
          onChanged: enabled ? (_) => onSelectAll?.call() : null,
        ),
        Expanded(child: Text(ml.selectAllButtonLabel)),
      ],
    );
  }



  Widget _queueCards(AppLocalizations t, List<CustomerQueueItem> visible) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _queueFiltersChipsRow(t),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = visible[i];
            return Card(
              child: InkWell(
                onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => TreatmentPage(shopId: widget.shopId, customer: c),
            ),
          );
          if (changed == true) {
            await _load();
          }
        },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.dogName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.breed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.ownerFullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addQueueItemDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final dogCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();

    final result = await showDialog<CustomerQueueItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.create),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dogCtrl,
              decoration: InputDecoration(labelText: t.dogNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: breedCtrl,
              decoration: InputDecoration(labelText: t.dogBreedLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ownerCtrl,
              decoration: InputDecoration(labelText: t.dogOwnerNameLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () {
              final item = CustomerQueueItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                dogName: dogCtrl.text.trim(),
                breed: breedCtrl.text.trim(),
                ownerFullName: ownerCtrl.text.trim(),
              );
              Navigator.pop(ctx, item);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    setState(() {
      _queueItems ??= <CustomerQueueItem>[];
      final k = _keyFromQueue(result);
      _queueItems!.removeWhere((q) => _keyFromQueue(q) == k);
      _queueItems!.insert(0, result);
    });
  }

  Widget _queueTable(AppLocalizations t) {
    final items = (_queueItems ?? const <CustomerQueueItem>[])
        .where((q) => _passesQueueColumnFilters(q, _queueColumnFilters))
        .toList();

    if (items.isEmpty) {
      return Text(t.noCustomersInQueue);
    }

    if (_isCompactLayout(context)) {
      return _queueCards(t, items);
    }

    Widget tapCell(Widget child, CustomerQueueItem c) {
      return InkWell(
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => TreatmentPage(shopId: widget.shopId, customer: c),
            ),
          );
          if (changed == true) {
            await _load();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: child,
        ),
      );
    }

    final rows = <TableRow>[
      for (final c in items)
        TableRow(
          children: [
            tapCell(_cellText(c.dogName), c),
            tapCell(_cellText(c.breed), c),
            tapCell(_cellText(c.ownerFullName, maxLines: 2), c),
          ],
        ),
    ];

    final colW = <int, TableColumnWidth>{
      0: const FlexColumnWidth(1.1),
      1: const FlexColumnWidth(1.0),
      2: const FlexColumnWidth(1.6),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _queueFiltersChipsRow(t),
        const SizedBox(height: 10),
        Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).dividerColor),
              outside: BorderSide(color: Theme.of(context).dividerColor),
            ),
            columnWidths: colW,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
      ),
      ],
    );
  }

  Widget _busyCards(AppLocalizations t, List<Treatment> visible) {
    final selectable = visible.where(_canFinish).map((x) => x.id).toList();
    final anySelected = selectable.any(_selectedBusySessionIds.contains);
    final allSelected =
        selectable.isNotEmpty && selectable.every(_selectedBusySessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filtersChipsRow(t, forBusy: true),
        const SizedBox(height: 10),
        _selectAllRow(
          enabled: selectable.isNotEmpty,
          value: headerValue,
          onSelectAll: () {
            setState(() {
              if (headerValue == true) {
                _selectedBusySessionIds.removeAll(selectable);
              } else {
                _selectedBusySessionIds.addAll(selectable);
              }
            });
          },
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final tr = visible[i];
            final canSelect = _canFinish(tr);
            final checked = _selectedBusySessionIds.contains(tr.id);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: canSelect
                          ? (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedBusySessionIds.add(tr.id);
                                } else {
                                  _selectedBusySessionIds.remove(tr.id);
                                }
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.dogName,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.breed,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.ownerFullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.treatmentType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr.employeeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ElevatedButton(
            onPressed:
                (_selectedBusySessionIds.isEmpty || _finishingBusy) ? null : _finishSelectedBusy,
            child: _finishingBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.finishTreatmentAction),
          ),
        ),
      ],
    );
  }

  Widget _treatedCards(AppLocalizations t, List<Treatment> visible) {
    final visibleIds = visible.map((x) => x.id).toList();
    final anySelected = visibleIds.any(_selectedTreatedSessionIds.contains);
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedTreatedSessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filtersChipsRow(t, forBusy: false),
        const SizedBox(height: 10),
        _selectAllRow(
          enabled: visibleIds.isNotEmpty,
          value: headerValue,
          onSelectAll: () {
            setState(() {
              if (headerValue == true) {
                _selectedTreatedSessionIds.removeAll(visibleIds);
              } else {
                _selectedTreatedSessionIds.addAll(visibleIds);
              }
            });
          },
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final tr = visible[i];
            final checked = _selectedTreatedSessionIds.contains(tr.id);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedTreatedSessionIds.add(tr.id);
                          } else {
                            _selectedTreatedSessionIds.remove(tr.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.dogName,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.breed,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.ownerFullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.treatmentType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _treatmentTime(tr),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedTreatedSessionIds.isEmpty ? null : _returnTreatedToQueue,
                child: Text(t.queueTitle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedTreatedSessionIds.isEmpty ? null : _removeFromTreatedToday,
                child: Text(t.delete),
              ),
            ),
          ],
        ),
      ],
    );
  }


  
  List<Widget> _busyHeaderCells(AppLocalizations t, List<String> selectableIds) {
    final anySelected = selectableIds.any(_selectedBusySessionIds.contains);
    final allSelected = selectableIds.isNotEmpty && selectableIds.every(_selectedBusySessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    return [
      Checkbox(
        tristate: true,
        value: selectableIds.isEmpty ? false : headerValue,
        onChanged: selectableIds.isEmpty
            ? null
            : (v) {
                setState(() {
                  if (v == true) {
                    _selectedBusySessionIds.addAll(selectableIds);
                  } else {
                    _selectedBusySessionIds.removeAll(selectableIds);
                  }
                });
              },
      ),
      _headerCellWithFilter(label: t.dogNameLabel, col: _Col.dogName, forBusy: true),
      _headerCellWithFilter(label: t.dogBreedLabel, col: _Col.breed, forBusy: true),
      _headerCellWithFilter(label: t.dogOwnerNameLabel, col: _Col.ownerFullName, forBusy: true),
      _headerCellWithFilter(label: t.treatmentTypeLabel, col: _Col.treatmentType, forBusy: true),
      _headerCellWithFilter(label: t.employeesTitle, col: _Col.employeeName, forBusy: true),
    ];
  }
Widget _busyTable(AppLocalizations t) {
  final visible =
      _busy.where((tr) => _passesColumnFilters(tr, _busyColumnFilters)).toList();

  if (visible.isEmpty) {
    return Text(t.noBusyTreatments);
  }

  if (_isCompactLayout(context)) {
    return _busyCards(t, visible);
  }

  final selectableIds = visible.where(_canFinish).map((x) => x.id).toList();

  final anySelected = selectableIds.any(_selectedBusySessionIds.contains);
  final allSelected =
      selectableIds.isNotEmpty && selectableIds.every(_selectedBusySessionIds.contains);
  final headerValue = allSelected ? true : (anySelected ? null : false);

  final rows = <TableRow>[
    for (final tr in visible)
      _cellRow([
        Checkbox(
          value: _selectedBusySessionIds.contains(tr.id),
          onChanged: _canFinish(tr)
              ? (v) {
                  setState(() {
                    if (v == true) {
                      _selectedBusySessionIds.add(tr.id);
                    } else {
                      _selectedBusySessionIds.remove(tr.id);
                    }
                  });
                }
              : null,
        ),
        _cellText(tr.dogName),
        _cellText(tr.breed),
        _cellText(tr.ownerFullName, maxLines: 2),
        _cellText(tr.treatmentType),
        _cellText(tr.employeeName),
      ]),
  ];

  final colW = <int, TableColumnWidth>{
    // Give checkboxes enough room on mobile platforms (min tap target).
    0: const FixedColumnWidth(56),
    1: const FlexColumnWidth(1.05),
    2: const FlexColumnWidth(1.0),
    3: const FlexColumnWidth(1.35),
    4: const FlexColumnWidth(1.0),
    5: const FlexColumnWidth(0.95),
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Column filters (Excel-like) without header/title cells.
      _filtersChipsRow(t, forBusy: true),
      const SizedBox(height: 10),
      _selectAllRow(
        enabled: selectableIds.isNotEmpty,
        value: selectableIds.isEmpty ? false : headerValue,
        onSelectAll: selectableIds.isEmpty
            ? null
            : () {
                setState(() {
                  if (headerValue == true) {
                    _selectedBusySessionIds.removeAll(selectableIds);
                  } else {
                    _selectedBusySessionIds.addAll(selectableIds);
                  }
                });
              },
      ),
      const SizedBox(height: 6),
      Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).dividerColor),
              outside: BorderSide(color: Theme.of(context).dividerColor),
            ),
            columnWidths: colW,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ElevatedButton(
          onPressed:
              (_selectedBusySessionIds.isEmpty || _finishingBusy) ? null : _finishSelectedBusy,
          child: _finishingBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.finishTreatmentAction),
        ),
      ),
    ],
  );
}





  List<Widget> _treatedHeaderCells(AppLocalizations t, List<String> visibleIds) {
    final anySelected = visibleIds.any(_selectedTreatedSessionIds.contains);
    final allSelected = visibleIds.isNotEmpty && visibleIds.every(_selectedTreatedSessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    return [
      Checkbox(
        tristate: true,
        value: visibleIds.isEmpty ? false : headerValue,
        onChanged: visibleIds.isEmpty
            ? null
            : (v) {
                setState(() {
                  if (v == true) {
                    _selectedTreatedSessionIds.addAll(visibleIds);
                  } else {
                    _selectedTreatedSessionIds.removeAll(visibleIds);
                  }
                });
              },
      ),
      _headerCellWithFilter(label: t.dogNameLabel, col: _Col.dogName, forBusy: false),
      _headerCellWithFilter(label: t.dogBreedLabel, col: _Col.breed, forBusy: false),
      _headerCellWithFilter(label: t.dogOwnerNameLabel, col: _Col.ownerFullName, forBusy: false),
      _headerCellWithFilter(label: t.treatmentTypeLabel, col: _Col.treatmentType, forBusy: false),
      _headerCellWithFilter(label: t.employeesTitle, col: _Col.employeeName, forBusy: false),
      Text(t.treatmentTimeColumn),
    ];
  }
Widget _treatedTodayTable(AppLocalizations t) {
  final visible =
      _treatedToday.where((tr) => _passesColumnFilters(tr, _treatedColumnFilters)).toList();

  if (visible.isEmpty) {
    return Text(t.noTreatedToday);
  }

  if (_isCompactLayout(context)) {
    return _treatedCards(t, visible);
  }

  final visibleIds = visible.map((x) => x.id).toList();

  final anySelected = visibleIds.any(_selectedTreatedSessionIds.contains);
  final allSelected =
      visibleIds.isNotEmpty && visibleIds.every(_selectedTreatedSessionIds.contains);
  final headerValue = allSelected ? true : (anySelected ? null : false);

  final rows = <TableRow>[
    for (final tr in visible)
      _cellRow([
        Checkbox(
          value: _selectedTreatedSessionIds.contains(tr.id),
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedTreatedSessionIds.add(tr.id);
              } else {
                _selectedTreatedSessionIds.remove(tr.id);
              }
            });
          },
        ),
        _cellText(tr.dogName),
        _cellText(tr.breed),
        _cellText(tr.ownerFullName, maxLines: 2),
        _cellText(tr.treatmentType),
        _cellText(tr.employeeName),
        _cellText(_treatmentTime(tr)),
      ]),
  ];

  final colW = <int, TableColumnWidth>{
    // Give checkboxes enough room on mobile platforms (min tap target).
    0: const FixedColumnWidth(56),
    1: const FlexColumnWidth(1.05),
    2: const FlexColumnWidth(1.0),
    3: const FlexColumnWidth(1.35),
    4: const FlexColumnWidth(1.0),
    5: const FlexColumnWidth(0.95),
    6: const FlexColumnWidth(0.75),
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Column filters (Excel-like) without header/title cells.
      _filtersChipsRow(t, forBusy: false),
      const SizedBox(height: 10),
      _selectAllRow(
        enabled: visibleIds.isNotEmpty,
        value: visibleIds.isEmpty ? false : headerValue,
        onSelectAll: visibleIds.isEmpty
            ? null
            : () {
                setState(() {
                  if (headerValue == true) {
                    _selectedTreatedSessionIds.removeAll(visibleIds);
                  } else {
                    _selectedTreatedSessionIds.addAll(visibleIds);
                  }
                });
              },
      ),
      const SizedBox(height: 6),
      Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).dividerColor),
              outside: BorderSide(color: Theme.of(context).dividerColor),
            ),
            columnWidths: colW,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectedTreatedSessionIds.isEmpty ? null : _returnTreatedToQueue,
              child: Text(t.queueTitle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedTreatedSessionIds.isEmpty ? null : _removeFromTreatedToday,
              child: Text(t.delete),
            ),
          ),
        ],
      ),
    ],
  );
}




  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) {
          final tab = DefaultTabController.of(context)!;
          return Scaffold(
        appBar: AppBar(
          title: Text(t.queueTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t.queueTitle),
              Tab(text: t.statusBusy),
              Tab(text: t.treatedTodayTitle),
              Tab(text: t.doneByMeTitle),
            ],
          ),
          actions: [
            PopupMenuButton<_HomeMenu>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                switch (v) {
                  case _HomeMenu.changeEmployee:
                    await EmployeeIdentityStore().clearEmployeeId();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/employeeId', (r) => false);
                    break;
                  case _HomeMenu.langEn:
                    await AppLocale.setEnglish();
                    break;
                  case _HomeMenu.langHe:
                    await AppLocale.setHebrew();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: _HomeMenu.changeEmployee, child: Text(t.changeEmployeeAction)),
                const PopupMenuDivider(),
                PopupMenuItem(value: _HomeMenu.langEn, child: Text(t.english)),
                PopupMenuItem(value: _HomeMenu.langHe, child: Text(t.hebrew)),
              ],
            ),
          ],
        ),
        floatingActionButton: AnimatedBuilder(
          animation: tab,
          builder: (context, _) {
            if (tab.index != 0) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: _queueItems == null
                  ? null
                  : () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => TreatmentPage(
                            shopId: widget.shopId,
                            customer: CustomerQueueItem(
                              id: DateTime.now().microsecondsSinceEpoch.toString(),
                              dogName: '',
                              breed: '',
                              ownerFullName: '',
                            ),
                          ),
                        ),
                      );
                      if (changed == true) {
                        await _load();
                      }
                    },
              child: const Icon(Icons.add),
            );
          },
        ),
        body: SafeArea(
          child: _queueItems == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(t.errorWithMessage(_error!)))
                  : TabBarView(
                      children: [
                        _queueTab(t),
                        _busyTab(t),
                        _treatedTab(t),
                        _doneByMeTab(t),
                      ],
                    ),
        ),
          );
        },
      ),
    );
  }

  Widget _queueTab(AppLocalizations t) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_employee != null) ...[
            Text(
              _employee!.displayName(t.noNameValue),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          _queueTable(t),
        ],
      ),
    );
  }


  Widget _busyTab(AppLocalizations t) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_employee != null) ...[
            Text(
              _employee!.displayName(t.noNameValue),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          _busyTable(t),
        ],
      ),
    );
  }

  Widget _treatedTab(AppLocalizations t) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_employee != null) ...[
            Text(
              _employee!.displayName(t.noNameValue),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          _treatedTodayTable(t),
        ],
      ),
    );
  }

  Future<void> _returnDoneByMeToQueue() async {
    final ids = _selectedDoneByMeSessionIds.toList();
    if (ids.isEmpty) return;

    final byId = {for (final x in _treatedToday) x.id: x};
    final picked = ids.map((id) => byId[id]).whereType<Treatment>().toList();
    for (final tr in picked) {
      await _queue.addToQueue(
        CustomerQueueItem(
          id: tr.id,
          dogName: tr.dogName,
          breed: tr.breed,
          ownerFullName: tr.ownerFullName,
        ),
      );
    }

    await _status.deleteTreatments(ids);

    if (!mounted) return;
    setState(() {
      _treatedToday = _treatedToday.where((x) => !ids.contains(x.id)).toList();
      _selectedDoneByMeSessionIds.clear();
      _selectedTreatedSessionIds.removeAll(ids);
    });
    await _load();
  }

  Future<void> _removeFromDoneByMeToday() async {
    final ids = _selectedDoneByMeSessionIds.toList();
    if (ids.isEmpty) return;

    try {
      await _status.deleteTreatments(ids);
      if (!mounted) return;
      setState(() {
        _selectedDoneByMeSessionIds.clear();
        _selectedTreatedSessionIds.removeAll(ids);
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
      );
    }
  }

  Widget _doneByMeCards(AppLocalizations t, List<Treatment> visible) {
    final visibleIds = visible.map((x) => x.id).toList();
    final anySelected = visibleIds.any(_selectedDoneByMeSessionIds.contains);
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedDoneByMeSessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filtersChipsRow(t, forBusy: false),
        const SizedBox(height: 10),
        _selectAllRow(
          enabled: visibleIds.isNotEmpty,
          value: headerValue,
          onSelectAll: () {
            setState(() {
              if (headerValue == true) {
                _selectedDoneByMeSessionIds.removeAll(visibleIds);
              } else {
                _selectedDoneByMeSessionIds.addAll(visibleIds);
              }
            });
          },
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final tr = visible[i];
            final checked = _selectedDoneByMeSessionIds.contains(tr.id);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedDoneByMeSessionIds.add(tr.id);
                          } else {
                            _selectedDoneByMeSessionIds.remove(tr.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.dogName,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.breed,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.ownerFullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr.treatmentType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _treatmentTime(tr),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.employeeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedDoneByMeSessionIds.isEmpty ? null : _returnDoneByMeToQueue,
                child: Text(t.queueTitle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedDoneByMeSessionIds.isEmpty ? null : _removeFromDoneByMeToday,
                child: Text(t.delete),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneByMeTable(AppLocalizations t) {
    final me = _employeeId;
    final src = (me == null)
        ? const <Treatment>[]
        : _treatedToday.where((tr) => tr.employeeId == me).toList();

    final visible = src.where((tr) => _passesColumnFilters(tr, _treatedColumnFilters)).toList();

    if (visible.isEmpty) {
      return Text(t.noDoneByMeToday);
    }

    if (_isCompactLayout(context)) {
      return _doneByMeCards(t, visible);
    }

    final visibleIds = visible.map((x) => x.id).toList();

    final anySelected = visibleIds.any(_selectedDoneByMeSessionIds.contains);
    final allSelected =
        visibleIds.isNotEmpty && visibleIds.every(_selectedDoneByMeSessionIds.contains);
    final headerValue = allSelected ? true : (anySelected ? null : false);

    final rows = <TableRow>[
      for (final tr in visible)
        _cellRow([
          Checkbox(
            value: _selectedDoneByMeSessionIds.contains(tr.id),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedDoneByMeSessionIds.add(tr.id);
                } else {
                  _selectedDoneByMeSessionIds.remove(tr.id);
                }
              });
            },
          ),
          _cellText(tr.dogName),
          _cellText(tr.breed),
          _cellText(tr.ownerFullName, maxLines: 2),
          _cellText(tr.treatmentType),
          _cellText(tr.employeeName),
          _cellText(_treatmentTime(tr)),
        ]),
    ];

    final colW = <int, TableColumnWidth>{
      0: const FixedColumnWidth(56),
      1: const FlexColumnWidth(1.05),
      2: const FlexColumnWidth(1.0),
      3: const FlexColumnWidth(1.35),
      4: const FlexColumnWidth(1.0),
      5: const FlexColumnWidth(0.95),
      6: const FlexColumnWidth(0.75),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filtersChipsRow(t, forBusy: false),
        const SizedBox(height: 10),
        _selectAllRow(
          enabled: visibleIds.isNotEmpty,
          value: visibleIds.isEmpty ? false : headerValue,
          onSelectAll: visibleIds.isEmpty
              ? null
              : () {
                  setState(() {
                    if (headerValue == true) {
                      _selectedDoneByMeSessionIds.removeAll(visibleIds);
                    } else {
                      _selectedDoneByMeSessionIds.addAll(visibleIds);
                    }
                  });
                },
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: Theme.of(context).dividerColor),
                outside: BorderSide(color: Theme.of(context).dividerColor),
              ),
              columnWidths: colW,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedDoneByMeSessionIds.isEmpty ? null : _returnDoneByMeToQueue,
                child: Text(t.queueTitle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedDoneByMeSessionIds.isEmpty ? null : _removeFromDoneByMeToday,
                child: Text(t.delete),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneByMeTab(AppLocalizations t) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_employee != null) ...[
            Text(
              _employee!.displayName(t.noNameValue),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
          ],
          _doneByMeTable(t),
        ],
      ),
    );
  }

}