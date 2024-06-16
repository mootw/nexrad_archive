import 'dart:typed_data';

/// 2620002W - 3.2.1
/// always returns values aligned to the current view offset
extension NexradTypes on ByteData {
  int getNexradInteger1(int offset) => getUint8(offset);
  int getNexradInteger2(int offset) => getUint16(offset);
  int getNexradSInteger2(int offset) => getInt16(offset);
  int getNexradInteger4(int offset) => getUint32(offset);
  double getNexradReal4(int offset) => getFloat32(offset);
  String getNexradString(int start, int length) =>
      String.fromCharCodes(buffer.asUint8List(start + offsetInBytes, length));
}