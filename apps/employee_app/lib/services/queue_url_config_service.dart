import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class QueueUrlConfig {
  QueueUrlConfig({
    required this.url,
    required this.params,
    this.apiKey,
  });

  final String url;
  final String params;
  final String? apiKey;
}

/// Reads the queue endpoint configuration from Firestore.
///
/// Root collection: `get_queue_url`
/// Documents:
///  - `getQueueDirect`: used on iOS/Android. Must contain `URL`, `params`, `x-api-key`.
///  - `getQueueServer`: used on web/desktop. Must contain `URL`, `params`.
class QueueUrlConfigService {
  QueueUrlConfigService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<QueueUrlConfig> fetch({required bool direct, required String shopId}) async {
    final docId = kIsWeb ?  'getQueueServer' : 'getQueueDirect';
    final snap = await _db.collection('shops').doc(shopId).collection('get_queue_url').doc(docId).get();

    final d = snap.data();
    if (d == null) {
      throw StateError('Missing Firestore document shops/$shopId/get_queue_url/$docId');
    }

    final url = (d['URL'] ?? '').toString().trim();
    final params = (d['params'] ?? '').toString().trim(); // remove x
   	final apiKey = (d['x-api-key'] ?? '').toString().trim();

    if (url.isEmpty) {
      throw StateError('shops/$shopId/get_queue_url/$docId: field "URL" is empty');
    }
    if (params.isEmpty) {  // remove x
      throw StateError('shops/$shopId/get_queue_url/$docId: field "params" is empty');
    }

    // for testing only
    //final params = 'dueDate=2025-12-28';

    return QueueUrlConfig(
      url: url,
      params: params,
      apiKey: kIsWeb ? null : apiKey,
    );
  }
}
