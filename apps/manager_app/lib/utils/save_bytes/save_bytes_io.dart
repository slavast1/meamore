import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveBytesToFileImpl({required Uint8List bytes, required String filename}) async {
  // Save into the app Documents directory so the OS share/save UI can access it.
  // This is the closest cross-platform equivalent to a “Documents” default on
  // Android/iOS without requesting storage permissions.
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
