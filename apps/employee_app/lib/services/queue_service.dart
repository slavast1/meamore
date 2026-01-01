import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/customer_queue_item.dart';
import 'queue_url_config_service.dart';

class QueueService {
  QueueService({
    required this.shopId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String shopId;
  final FirebaseFirestore _db;

  // In-app simulator store (per-shop). Persists for the current app session.
  static final Map<String, List<CustomerQueueItem>> _store = {};

  List<CustomerQueueItem> _ensureSeeded() {
    return _store.putIfAbsent(shopId, () {
      return [
        CustomerQueueItem(id: 'seed-1', dogName: 'Luna', breed: 'Poodle', ownerFullName: 'Noam Levi'),
        CustomerQueueItem(id: 'seed-2', dogName: 'Max', breed: 'Labrador', ownerFullName: 'Dana Cohen'),
        CustomerQueueItem(id: 'seed-3', dogName: 'Bella', breed: 'Mixed', ownerFullName: 'Eitan Bar'),
      ];
    });
  }

  Future<void> addToQueue(CustomerQueueItem item) async {
    final list = _ensureSeeded();
    // Add to the front; duplicates are allowed by requirement.
    list.insert(0, item);
  }

  Future<List<CustomerQueueItem>> fetchQueue() async {
    final useDirect = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final cfg = await QueueUrlConfigService(firestore: _db).fetch(direct: useDirect, shopId: shopId);

    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    // Firestore stores the placeholder as "$currentDate". In Dart strings,
    // we must escape `$` to match it literally.
    final params = cfg.params.replaceAll('\$currentDate', currentDate);
    final fullUrl = _combineUrlAndParams(cfg.url, params);

    final headers = <String, String>{};
    if (useDirect && (cfg.apiKey?.trim().isNotEmpty ?? false)) {
      headers['x-api-key'] = cfg.apiKey!.trim();
    }

    final resp = await http.get(Uri.parse(fullUrl), headers: headers);
    if (resp.statusCode != 200) {
      throw StateError('HTTP ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);
    final List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      final v = decoded['appointments'] ?? decoded['queue'] ?? decoded['items'] ?? decoded['data'];
      if (v is List) {
        items = v;
      } else {
        throw FormatException('Unexpected response shape (expected list).');
      }
    } else {
      throw FormatException('Unexpected response type: ${decoded.runtimeType}');
    }

    return items.map((e) => _queueItemFromJson(e)).whereType<CustomerQueueItem>().toList();
  }

  String _combineUrlAndParams(String url, String params) {
    final base = url.trim();
    var p = params.trim();
    if (p.startsWith('?')) p = p.substring(1);
    if (p.isEmpty) return base;

    final hasQuery = base.contains('?');
    if (!hasQuery) return '$base?$p';

    if (base.endsWith('?') || base.endsWith('&')) return '$base$p';
    return '$base&$p';
  }

  CustomerQueueItem? _queueItemFromJson(dynamic raw) {
    if (raw is! Map) return null;
    final m = raw.cast<String, dynamic>();

    // Stable key from REST API.
    // For the sample payload this is `appointments[].id`.
    final id = (m['id'] ?? '').toString().trim();

    String _firstNonEmpty(List<dynamic> vals) {
      for (final v in vals) {
        final s = (v ?? '').toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    // Some APIs return nested objects. Try common patterns.
    final customer = (m['customer'] is Map) ? (m['customer'] as Map).cast<String, dynamic>() : null;
    final dog = (m['dog'] is Map) ? (m['dog'] as Map).cast<String, dynamic>() : null;

    final dogName = _firstNonEmpty([
      m['dogName'],
      dog?['name'],
      m['petName'],
      m['name'],
    ]);
    final breed = _firstNonEmpty([
      m['breed'],
      dog?['breed'],
      m['dogBreed'],
    ]);
    final ownerFullName = _firstNonEmpty([
      m['ownerFullName'],
      m['ownerName'],
      m['owner'],
      customer?['fullName'],
      customer?['name'],
      m['customerName'],
    ]);

    // Fall back to a computed id if the API didn't provide one.
    // (Keeps selection/updates stable even for legacy payloads.)
    final computedId = _firstNonEmpty([
      id,
      _firstNonEmpty([m['sessionId'], m['key']]),
      '${m['day'] ?? ''}|${m['startTime'] ?? ''}|${m['endTime'] ?? ''}|$ownerFullName|$dogName|$breed',
    ]).trim();

    if (computedId.isEmpty && dogName.isEmpty && breed.isEmpty && ownerFullName.isEmpty) return null;

    String? _pickOptionalString(List<dynamic> vals) {
      for (final v in vals) {
        final s = (v ?? '').toString().trim();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    final mobile = _pickOptionalString([
      // Most common
      m['customerMobile'],
      m['customer_mobile'],
      m['mobile'],
      m['phone'],
      m['customerPhone'],
      m['customer_phone'],
      // Nested
      customer?['mobile'],
      customer?['phone'],
      customer?['customerMobile'],
    ]);

    final serviceTitle = _pickOptionalString([
      m['serviceTitle'],
      m['service_title'],
      m['serviceName'],
      m['service_name'],
      m['service'],
      m['treatmentType'],
      m['treatment_type'],
      m['title'],
      m['name'],
    ]);

    final remark = _pickOptionalString([
      m['remark'],
      m['remarks'],
      m['note'],
      m['notes'],
      m['comment'],
      m['comments'],
    ]);

    return CustomerQueueItem(
      id: computedId,
      dogName: dogName,
      breed: breed,
      ownerFullName: ownerFullName,
      day: (m['day'] ?? m['date'] ?? '').toString().trim().isEmpty
          ? null
          : (m['day'] ?? m['date']).toString(),
      startTime: (m['startTime'] ?? '').toString().trim().isEmpty ? null : m['startTime'].toString(),
      endTime: (m['endTime'] ?? '').toString().trim().isEmpty ? null : m['endTime'].toString(),
      customerMobile: mobile,
      serviceTitle: serviceTitle,
      empName: (m['empName'] ?? m['employeeName'] ?? '').toString().trim().isEmpty
          ? null
          : (m['empName'] ?? m['employeeName']).toString(),
      dogsNumber: (m['dogsNumber'] is num)
          ? (m['dogsNumber'] as num).toInt()
          : int.tryParse('${m['dogsNumber'] ?? ''}'),
      remark: remark,
    );
  }


  Future<void> removeFromQueue(CustomerQueueItem item) async {
    final list = _ensureSeeded();
    list.removeWhere((x) => x.id == item.id);
  }

  Future<void> removeManyFromQueue(Iterable<CustomerQueueItem> items) async {
    for (final item in items) {
      await removeFromQueue(item);
    }
  }

}