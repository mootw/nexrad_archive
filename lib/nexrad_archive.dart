import 'dart:typed_data';

import 'package:nexrad_archive/ldm_record.dart';
import 'package:nexrad_archive/types.dart';
import 'package:nexrad_archive/volume_header.dart';

/// based on https://www.roc.noaa.gov/WSR88D/PublicDocs/ICDs/2620002W.pdf
/// build 22 (version W)
/// based on https://www.roc.noaa.gov/WSR88D/PublicDocs/ICDs/2620010E.pdf
/// build 12 (version E)
class NexradArchiveIIReader {
  static const TCM_MESSAGE_SIZE = 4; // 3.1.3

  final ByteData bytes;

  NexradArchiveIIReader(this.bytes);

  bool get hasHeader => bytes.getNexradString(0, 6) == "AR2V00";

  NexradVolumeHeader get header => NexradVolumeHeader(
        ByteData.view(bytes.buffer, 0, NexradVolumeHeader.SIZE),
      );

  Stream<NexradLDMRecord> getRecords() async* {
    int seek = hasHeader ? NexradVolumeHeader.SIZE : 0;
    while (seek < bytes.lengthInBytes) {
      /// 2620010E - 7.3.4
      /// the number of bytes can be negative so abs is used
      final compressedSize = bytes.getInt32(seek).abs();

      final record =
          NexradLDMRecord(ByteData.view(bytes.buffer, seek, compressedSize));
      seek += TCM_MESSAGE_SIZE + compressedSize;
      yield record;
    }
  }
}
