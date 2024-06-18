import 'dart:typed_data';
import 'package:nexrad_archive/types.dart';

class NexradMessageHeader {
  /// size in bytes of this header
  static const int SIZE = 28;

  /// in half words
  late int messageSize;
  final int redundantChannel;
  final int type;
  final int seq;
  final int date;
  final int time;
  final int numSegments;
  final int segmentNumber;

  /// ignores the first 12 bytes and is based on table II 3.2.4.1 in 2620002W
  NexradMessageHeader(ByteData bytes)
      : messageSize = bytes.getNexradInteger2(12),
        redundantChannel = bytes.getNexradInteger1(14),
        type = bytes.getNexradInteger1(15),
        seq = bytes.getNexradInteger2(16),
        date = bytes.getNexradInteger2(18) - 1,
        time = bytes.getNexradInteger4(20),
        numSegments = bytes.getNexradInteger2(24),
        segmentNumber = bytes.getNexradInteger2(26) {
    if (messageSize == 65535) {
      messageSize = bytes.getNexradInteger4(24);
    }
  }

  DateTime get dateTime =>
      DateTime.utc(1970, 1, 1 + date).add(Duration(milliseconds: time));

  @override
  String toString() =>
      'NexradLDMHeader(messageSize: $messageSize, redundantChannel: $redundantChannel, type: $type, seq: $seq, date: $dateTime, numSegments: $numSegments, segmentNumber: $segmentNumber)';
}
