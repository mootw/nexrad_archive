import 'dart:typed_data';
import 'package:nexrad_archive/ldm_record.dart';
import 'package:nexrad_archive/types.dart';

enum WaveformType {
  Contiguous_Surveillance,
  Contiguous_Doppler_w_Ambiguity_Resolution,
  Contiguous_Doppler_wo_Ambiguity_Resolution,
  Batch,
  Staggered_Pulse_Pair
}

/// VCP metadata, basically volume scan information.
/// each volume should have one of these messages to properly
/// reconstruct the scans of the volume.
/// 2620002W - 3.2.4.12 Table XI Volume Coverage Pattern Data (Message Types 5 & 7)
class NexradMessage5 extends NexradMessage {
  final int messageSize;
  final int patternNumber;
  final int numberOfElevationCuts;

  late final List<NexradElevationAngle> elevationAngles;

  NexradMessage5(super.header, super.bytes)
      : messageSize = bytes.getNexradInteger2(halfwordHighByte(1)),
        patternNumber = bytes.getNexradInteger2(halfwordHighByte(3)),
        numberOfElevationCuts = bytes.getNexradInteger2(halfwordHighByte(4)) {
    elevationAngles = List.generate(
      numberOfElevationCuts,
      (index) => NexradElevationAngle(
        ByteData.view(
          bytes.buffer,
          bytes.offsetInBytes +
              halfwordHighByte(12) +
              (index * NexradElevationAngle.NUMBER_OF_E_VALUES * 2),
        ),
      ),
      growable: false,
    );
  }
}

/// Subset of 3.2.4.12 of NexradMessage5
class NexradElevationAngle {
  /// 2620002W - Number_of_E_Values
  static int NUMBER_OF_E_VALUES = 23; // half-words length

  final double elevationAngleDeg;

  /// useful for determining the type of scan
  final WaveformType waveformType;

  final double azimuthRateDegRate; // per second

  /// Sector 1 Azimuth Clockwise Edge Angle (denotes start angle)
  final double edgeAngleDeg;

  final int dopplerPrfNumber;
  final int dopplerPrfPulseCountRadial;

  NexradElevationAngle(ByteData bytes)
      : elevationAngleDeg = bytes.getAngleDataFormat(halfwordHighByte(1)),
        waveformType =
            switch (bytes.getNexradInteger1(halfwordHighByte(2) + 1)) {
          1 => WaveformType.Contiguous_Surveillance,
          2 => WaveformType.Contiguous_Doppler_w_Ambiguity_Resolution,
          3 => WaveformType.Contiguous_Doppler_wo_Ambiguity_Resolution,
          4 => WaveformType.Batch,
          5 => WaveformType.Staggered_Pulse_Pair,
          _ => throw FormatException(
              "invalid waveformType ${bytes.getNexradInteger1(halfwordHighByte(2) + 1)}",
            ),
        },
        azimuthRateDegRate = bytes.getAngleRateDataFormat(halfwordHighByte(5)),
        edgeAngleDeg = bytes.getAngleDataFormat(halfwordHighByte(12)),
        dopplerPrfNumber = bytes.getNexradInteger2(halfwordHighByte(13)),
        dopplerPrfPulseCountRadial =
            bytes.getNexradInteger2(halfwordHighByte(14));
}
