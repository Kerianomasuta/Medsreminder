import 'dart:typed_data';

void triggerPdfDownload(Uint8List bytes, String filename) {
  // No-op on native/tests. On mobile or desktop, native file saving or sharing can be plugged in here.
}
