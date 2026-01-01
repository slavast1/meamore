import 'dart:typed_data';

import 'save_bytes_stub.dart'
    if (dart.library.html) 'save_bytes_web.dart'
    if (dart.library.io) 'save_bytes_io.dart';

/// Saves bytes to a file.
///
/// - On web: triggers a browser download.
/// - On IO platforms: writes to the system temp directory.
Future<String> saveBytesToFile({required Uint8List bytes, required String filename}) {
  return saveBytesToFileImpl(bytes: bytes, filename: filename);
}
