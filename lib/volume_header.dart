import 'dart:typed_data';
import 'types.dart';

/// 2620010E - 7.3.3
class NexradVolumeHeader {
  /// bytes
  static const SIZE = 24;

  /// should be "AR2"
  final String header;
  final int version;

  /// counts up to 999 then resets
  final int extension;
  final int date;
  final int time;

  /// 4 letter Station Name
  final String icao;

  NexradVolumeHeader(ByteData bytes)
      : header = bytes.getNexradString(0, 3),
        version = int.parse(bytes.getNexradString(4, 4)),
        extension =
            int.parse(String.fromCharCodes(bytes.buffer.asUint8List(9, 3))),
        date = bytes.getUint32(12) - 1,
        time = bytes.getUint32(16),
        icao = bytes.getNexradString(20, 4);

  DateTime get dateTime =>
      DateTime.utc(1970, 1, 1 + date).add(Duration(milliseconds: time));

  String toString() =>
      'NexradVolumeHeader{header: $header, version: $version, extension: $extension, date: $dateTime, station: $icao}';
}
