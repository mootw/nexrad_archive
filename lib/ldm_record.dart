import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nexrad_archive/ldm_header.dart';
import 'package:nexrad_archive/message_31.dart';
import 'package:nexrad_archive/message_5.dart';
import 'package:nexrad_archive/nexrad_archive.dart';

/// compressed chunks of data that come from the LDM
class NexradLDMRecord {
  /// exists for legacy reasons, it's empty
  /// source: 2620010E - 7.6
  static const int CTM_HEADER_SIZE = 12;

  /// all message types except 31 require this many bytes
  static const int MESSAGE_SIZE = 2432;

  final ByteData bytes;

  NexradLDMRecord(this.bytes);

  /// decompresses, parses, and returns the message contained in this record
  /// the type will vary depending on the message
  List<NexradMessage> getMessages() {
    return getMessagesFromBytes(decompressBytes());
  }

  /// Decompresses an LDM message accounting for the header
  Uint8List decompressBytes() {
    return BZip2Decoder().decodeBytes(
      bytes.buffer.asUint8List(
        bytes.offsetInBytes + NexradArchiveIIReader.TCM_MESSAGE_SIZE,
        bytes.lengthInBytes,
      ),
    ) as Uint8List;
  }

  /// returns a list of messages from uncompressed LDM record bytes
  /// this is just the message data with no header
  static List<NexradMessage> getMessagesFromBytes(Uint8List decompressedBytes) {
    final messages = <NexradMessage>[];

    int seek = 0;
    while (seek < decompressedBytes.length) {
      final header = NexradMessageHeader(
        ByteData.view(
          decompressedBytes.buffer,
          seek + 0,
          NexradMessageHeader.SIZE,
        ),
      );
      // Create a view that is aligned to the end of the LDM header
      final payload = ByteData.view(
        decompressedBytes.buffer,
        NexradMessageHeader.SIZE + seek,
      );

      switch (header.type) {
        case 31:
          final message = NexradMessage31(header, payload);
          seek += (header.messageSize * 2) -
              (NexradMessageHeader.SIZE - CTM_HEADER_SIZE) +
              NexradMessageHeader.SIZE;
          messages.add(message);
        case 5 || 7:
          final message = NexradMessage5(header, payload);
          seek += MESSAGE_SIZE;
          messages.add(message);
        default:
          seek += MESSAGE_SIZE;
          messages.add(NexradMessageUnimplemented(header, payload));
      }
    }
    return messages;
  }

  @override
  String toString() =>
      'NexradLDMRecord(compressedSize: ${bytes.lengthInBytes})';
}

abstract class NexradMessage {
  final ByteData bytes;
  final NexradMessageHeader header;

  NexradMessage(this.header, this.bytes);

  @override
  String toString() => 'NexradMessage(header: $header)';
}

/// Allows for user detection of unimplemented message types
/// it has no implementation and could be implemented if absolutely needed
class NexradMessageUnimplemented extends NexradMessage {
  NexradMessageUnimplemented(super.header, super.bytes);
}
