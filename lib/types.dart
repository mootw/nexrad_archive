import 'dart:typed_data';

/// To calculate halfword locations:
/// halfword_position * 2 - 2 (higher byte [use this for 2 byte values]),
/// halfword_position * 2 - 1 (lower byte)
int halfwordHighByte(int pos) => pos * 2 - 2;

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
  double getAngleDataFormat(int start) =>
      angleDataFormat(buffer.asUint8List(start + offsetInBytes, 2));
  double getAngleRateDataFormat(int start) =>
      angleRateDataFormat(buffer.asUint8List(start + offsetInBytes, 2));
}

/// Shift starting on the right side moving left
bool checkBit(int byte, int bit) => (byte & (1 << bit)) != 0;

/// 2620002W - 3.2.4.3 Table III-A Angle Data Format
double angleDataFormat(List<int> bytes) {
  assert(bytes.length == 2);

  final double value = (checkBit(bytes[0], 7) ? 180 : 0) +
      (checkBit(bytes[0], 6) ? 90 : 0) +
      (checkBit(bytes[0], 5) ? 45 : 0) +
      (checkBit(bytes[0], 4) ? 22.5 : 0) +
      (checkBit(bytes[0], 3) ? 11.25 : 0) +
      (checkBit(bytes[0], 2) ? 5.625 : 0) +
      (checkBit(bytes[0], 1) ? 2.8125 : 0) +
      (checkBit(bytes[0], 0) ? 1.40625 : 0) +
      (checkBit(bytes[1], 7) ? 0.70313 : 0) +
      (checkBit(bytes[1], 6) ? 0.35156 : 0) +
      (checkBit(bytes[1], 5) ? 0.17578 : 0) +
      (checkBit(bytes[1], 4) ? 0.08789 : 0) +
      (checkBit(bytes[1], 3) ? 0.043945 : 0);
  if (value > 90) {
    return value - 360;
  } else {
    return value;
  }
}

/// 3.2.4.12.1 Table XI-D Azimuth and Elevation Rate Data
double angleRateDataFormat(List<int> bytes) {
  assert(bytes.length == 2);

  final double value = (checkBit(bytes[1], 3) ? 0.010986328125 : 0) +
      (checkBit(bytes[1], 4) ? 0.02197265625 : 0) +
      (checkBit(bytes[1], 5) ? 0.0439453125 : 0) +
      (checkBit(bytes[1], 6) ? 0.087890625 : 0) +
      (checkBit(bytes[1], 7) ? 0.17578125 : 0) +
      (checkBit(bytes[0], 0) ? 0.3515625 : 0) +
      (checkBit(bytes[0], 1) ? 0.703125 : 0) +
      (checkBit(bytes[0], 2) ? 1.40625 : 0) +
      (checkBit(bytes[0], 3) ? 2.8125 : 0) +
      (checkBit(bytes[0], 4) ? 5.625 : 0) +
      (checkBit(bytes[0], 5) ? 11.25 : 0) +
      (checkBit(bytes[0], 6) ? 22.5 : 0);
  return checkBit(bytes[0], 7) ? -value : value;
}
