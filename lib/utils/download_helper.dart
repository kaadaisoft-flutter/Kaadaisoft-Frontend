import 'dart:typed_data';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as helper;

void downloadBytes(Uint8List bytes, String filename) {
  helper.downloadBytes(bytes, filename);
}
