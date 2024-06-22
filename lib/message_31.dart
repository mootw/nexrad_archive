import 'dart:typed_data';
import 'package:nexrad_archive/ldm_record.dart';
import 'package:nexrad_archive/types.dart';

/// based on table XVII 3.2.4.17 message type 31 in 2620002W
/// starts on page 3-86
class NexradMessage31 extends NexradMessage {
  final String icao;

  final int date;
  final int time;

  /// Radial number within elevation scan
  final int azimuthNumber;

  /// Azimuth angle at which radial data was collected
  final double azimuthAngle;

  /// 1 = 0.5 deg 2 = 1.0 deg
  final int azimuthResolutionSpacing;

  final int radialStatus;

  final int elevationNumber;

  final int cutSectorNumber;

  final double elevationAngle;

  final int dataBlockCount;

  /// basically just physical/scan parameters
  late VolumeDataConstantType volumeDataBlock;

  /// basically just physical/scan parameters
  late RadialDataConstantType radialDataBlock;

  /// generic data blocks. 2620002W - 3.2.4.17.6
  late List<GenericDataMomentType> genericDataBlocks;

  NexradMessage31(super.header, super.bytes)
      : icao = bytes.getNexradString(0, 4),
        time = bytes.getNexradInteger4(4),
        date = bytes.getNexradInteger2(8) - 1,
        azimuthNumber = bytes.getNexradInteger2(10),
        azimuthAngle = bytes.getNexradReal4(12),
        azimuthResolutionSpacing = bytes.getNexradInteger1(20),
        radialStatus = bytes.getNexradInteger1(21),
        elevationNumber = bytes.getNexradInteger1(22),
        cutSectorNumber = bytes.getNexradInteger1(23),
        elevationAngle = bytes.getNexradReal4(24),
        dataBlockCount = bytes.getNexradInteger2(30) {
    // Pointer is offset relative to beginning of
    // Data Header Block (see table XVII-A). Note the Data Header Block for
    // data blocks "VOL", "ELV", and "RAD" must always be present but the
    // pointers are not order or location dependent but shown in this order in
    // Table XVII-A for illustrative and clarity purposes.
    // 3.2.4.17 - 2620002W 3-92

    genericDataBlocks = [];
    for (int blockIndex = 0; blockIndex < dataBlockCount; blockIndex++) {
      const int blockPointerSizeBytes = 4;
      final blockPointer =
          bytes.getNexradInteger4(32 + (blockIndex * blockPointerSizeBytes));
      final blockId = bytes.getNexradString(blockPointer + 1, 3);
      // For now we only parse the data blocks with ID:
      // each block also has a block type. i believe the block name is unique
      // "VEL", "REF", "SW", "RHO", "PHI", "ZDR", "CFP"
      switch (blockId) {
        case "VOL":
          volumeDataBlock = VolumeDataConstantType(
            ByteData.view(bytes.buffer, bytes.offsetInBytes + blockPointer),
          );
        case "RAD":
          radialDataBlock = RadialDataConstantType(
            ByteData.view(bytes.buffer, bytes.offsetInBytes + blockPointer),
          );
        case "REF" || "VEL" || "SW" || "ZDR" || "PHI" || "RHO" || "CFP":
          genericDataBlocks.add(
            GenericDataMomentType(
              ByteData.view(bytes.buffer, bytes.offsetInBytes + blockPointer),
            ),
          );
      }
    }
  }

  /// mapped degree value of azimuthResolutionSpacing
  double get azimuthResolutionSpacingValue =>
      switch (azimuthResolutionSpacing) {
        1 => 0.5,
        2 => 1.0,
        _ => throw Exception("unknown azimuthResolutionSpacing")
      };

  DateTime get dateTime =>
      DateTime.utc(1970, 1, 1 + date).add(Duration(milliseconds: time));
}

abstract class DataBlock {
  final ByteData bytes;

  final String dataMomentType;

  final String dataMomentName;

  DataBlock(this.bytes)
      : dataMomentType = bytes.getNexradString(0, 1),
        dataMomentName = bytes.getNexradString(1, 3);
}

/// 3.2.4.17.3 Table XVII-E Data Block (Volume Data Constant Type)
class VolumeDataConstantType extends DataBlock {
  final int versionNumberMajor;
  final int versionNumberMinor;

  final double latitude;
  final double longitude;

  /// Height of site base above sea level (meters)
  final int siteHeightM;

  /// Height of feedhorn above ground (meters)
  final int feedHornHeightM;

  final double calibrationConstant;

  /// AKA VCP
  final int volumeCoveragePatternNumber;

  VolumeDataConstantType(super.bytes)
      : versionNumberMajor = bytes.getNexradInteger1(6),
        versionNumberMinor = bytes.getNexradInteger1(7),
        latitude = bytes.getNexradReal4(8),
        longitude = bytes.getNexradReal4(12),
        siteHeightM = bytes.getNexradSInteger2(16),
        feedHornHeightM = bytes.getNexradInteger2(18),
        calibrationConstant = bytes.getNexradReal4(20),
        volumeCoveragePatternNumber = bytes.getNexradInteger2(40);
}

/// 3.2.4.17.5 Table XVII-H Data Block (Radial Data Constant Type)
class RadialDataConstantType extends DataBlock {
  final double unambiguousRangeKm;
  final double noiseLevelHorizontaldBm;
  final double noiseLevelVerticaldBm;
  final double nyquistVelocityMS;
  final double calibrationHorizontaldBZ;
  final double calibrationVerticaldBZ;

  RadialDataConstantType(super.bytes)
      :
        // this value is scaled by 0.1
        unambiguousRangeKm = bytes.getNexradInteger2(6) * 0.1,
        noiseLevelHorizontaldBm = bytes.getNexradReal4(8),
        noiseLevelVerticaldBm = bytes.getNexradReal4(12),
        // this value is scaled by 0.01
        nyquistVelocityMS = bytes.getNexradInteger2(16) * 0.01,
        calibrationHorizontaldBZ = bytes.getNexradReal4(20),
        calibrationVerticaldBZ = bytes.getNexradReal4(24);
}

/// 3.2.4.17.2 Table XVII-B Data Block (Descriptor of Generic Data Moment Type)
class GenericDataMomentType extends DataBlock {
  /// Number of data moment gates for current radial (NG)
  final int dataMomentGateQuantity;

  final double dataMomentRangeKm;

  final double dataMomentSampleIntervalKm;

  final double snrThreshold;

  /// it is either 8 or 16 (DWS)
  final int dataWordSize;

  final double scale;
  final double offset;

  /// Raw value from moments
  /// This is needed because some raw values have special meaning
  ///
  /// (21) For all Reflectivity, Velocity, Spectrum Width, Differential Reflectivity, Differential Phase, and
  /// Correlation Coefficient, integer values N = 0 indicates received signal is below threshold and N = 1
  /// indicates range folded data. Actual data range begins at N = 2
  ///
  /// (30) For Clutter Filter Power Removed, integer value N=0 indicates the clutter filter was not applied.
  /// N=1 indicates point clutter filter was applied. N=2 indicates dual pol variables were filtered but not
  /// single pol moments. Values 3 through 7 are reserved for future use. Actual data range begins at N=8.
  /// 2620002W 3-93
  late List<int> momentsRaw;

  double getScaled(int index) => (momentsRaw[index] - offset) / scale;

  GenericDataMomentType(super.bytes)
      : dataMomentGateQuantity = bytes.getNexradInteger2(8),
        // this is scaled by 0.001
        dataMomentRangeKm = bytes.getNexradInteger2(10) * 0.001,
        // this is scaled by 0.001
        dataMomentSampleIntervalKm = bytes.getNexradInteger2(12) * 0.001,
        // this is scaled by 0.001
        snrThreshold = bytes.getNexradInteger2(16) * 0.125,
        dataWordSize = bytes.getNexradInteger1(19),
        scale = bytes.getNexradReal4(20),
        offset = bytes.getNexradReal4(24) {
    momentsRaw = List.generate(
      dataMomentGateQuantity,
      (index) => switch (dataWordSize) {
        8 => bytes.getNexradInteger1(28 + (index * 1)),
        16 => bytes.getNexradInteger2(28 + (index * 2)),
        _ => throw Exception("invalid dataWordSize $dataWordSize"),
      },
      growable: false,
    );
  }
}
