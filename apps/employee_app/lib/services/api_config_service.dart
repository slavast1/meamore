import 'package:cloud_firestore/cloud_firestore.dart';

class ApiConfigService {
  ApiConfigService({required this.shopId});

  final String shopId;

  DocumentReference<Map<String, dynamic>> get _cfg =>
      FirebaseFirestore.instance.doc('shops/$shopId/config/app');

  Future<String?> fetchQueueApiUrl() async {
    final snap = await _cfg.get();
    final d = snap.data() ?? {};
    final raw = (d['queueApiUrl'] ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }
}
