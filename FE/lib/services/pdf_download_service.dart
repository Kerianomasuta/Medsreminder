import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.js_interop) 'pdf_download_web.dart' as platform;

void downloadPdfFile(List<int> bytes, String filename) {
  final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  platform.triggerPdfDownload(uint8List, filename);
}
