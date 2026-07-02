import 'dart:math';
import 'dart:typed_data';

import 'package:wav_io/wav_io.dart';

// ignore: constant_identifier_names
const SPEAKER_FRONT_LEFT = 0x1;
// ignore: constant_identifier_names
const SPEAKER_FRONT_RIGHT = 0x2;
// ignore: constant_identifier_names
const SPEAKER_FRONT_CENTER = 0x4;
// ignore: constant_identifier_names
const SPEAKER_LOW_FREQUENCY = 0x8;
// ignore: constant_identifier_names
const SPEAKER_BACK_LEFT = 0x10;
// ignore: constant_identifier_names
const SPEAKER_BACK_RIGHT = 0x20;
// ignore: constant_identifier_names
const SPEAKER_FRONT_LEFT_OF_CENTER = 0x40;
// ignore: constant_identifier_names
const SPEAKER_FRONT_RIGHT_OF_CENTER = 0x80;
// ignore: constant_identifier_names
const SPEAKER_BACK_CENTER = 0x100;
// ignore: constant_identifier_names
const SPEAKER_SIDE_LEFT = 0x200;
// ignore: constant_identifier_names
const SPEAKER_SIDE_RIGHT = 0x400;
// ignore: constant_identifier_names
const SPEAKER_TOP_CENTER = 0x800;
// ignore: constant_identifier_names
const SPEAKER_TOP_FRONT_LEFT = 0x1000;
// ignore: constant_identifier_names
const SPEAKER_TOP_FRONT_CENTER = 0x2000;
// ignore: constant_identifier_names
const SPEAKER_TOP_FRONT_RIGHT = 0x4000;
// ignore: constant_identifier_names
const SPEAKER_TOP_BACK_LEFT = 0x8000;
// ignore: constant_identifier_names
const SPEAKER_TOP_BACK_CENTER = 0x10000;
// ignore: constant_identifier_names
const SPEAKER_TOP_BACK_RIGHT = 0x20000;

/* channel ordering
1. Front Left - FL
2. Front Right - FR
3. Front Center - FC
4. Low Frequency - LF
5. Back Left - BL
6. Back Right - BR
7. Front Left of Center - FLC
8. Front Right of Center - FRC
9. Back Center - BC
10. Side Left - SL
11. Side Right - SR
12. Top Center - TC
13. Top Front Left - TFL
14. Top Front Center - TFC
15. Top Front Right - TFR
16. Top Back Left - TBL
17. Top Back Center - TBC
18. Top Back Right - TBR
*/
/// Direct out (no mapped speaker positions).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_DIRECTOUT = 0x0;

/// Mono layout (maps to Front Center speaker).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_MONO = SPEAKER_FRONT_CENTER;

/// Stereo layout (maps to Front Left and Front Right speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_STEREO = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;

/// Quadraphonic layout (maps to Front Left, Front Right, Back Left, and Back Right speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_QUAD = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_BACK_LEFT |
    SPEAKER_BACK_RIGHT;

/// Surround layout (maps to Front Left, Front Right, Front Center, and Back Center speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_SURROUND = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_FRONT_CENTER |
    SPEAKER_BACK_CENTER;

/// 5.1 layout (maps to Front Left, Front Right, Front Center, Low Frequency, Back Left, and Back Right speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_5POINT1 = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_FRONT_CENTER |
    SPEAKER_LOW_FREQUENCY |
    SPEAKER_BACK_LEFT |
    SPEAKER_BACK_RIGHT;

/// 5.1 Surround layout (maps to Front Left, Front Right, Low Frequency, Side Left, and Side Right speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_5POINT1_SURROUND = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_LOW_FREQUENCY |
    SPEAKER_SIDE_LEFT |
    SPEAKER_SIDE_RIGHT;

/// 7.1 layout (maps to Front Left, Front Right, Front Center, Low Frequency, Back Left, Back Right, Front Left of Center, and Front Right of Center speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_7POINT1 = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_FRONT_CENTER |
    SPEAKER_LOW_FREQUENCY |
    SPEAKER_BACK_LEFT |
    SPEAKER_BACK_RIGHT |
    SPEAKER_FRONT_LEFT_OF_CENTER |
    SPEAKER_FRONT_RIGHT_OF_CENTER;

/// 7.1 Surround layout (maps to Front Left, Front Right, Front Center, Low Frequency, Back Left, Back Right, Side Left, and Side Right speakers).
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_7POINT1_SURROUND = SPEAKER_FRONT_LEFT |
    SPEAKER_FRONT_RIGHT |
    SPEAKER_FRONT_CENTER |
    SPEAKER_LOW_FREQUENCY |
    SPEAKER_BACK_LEFT |
    SPEAKER_BACK_RIGHT |
    SPEAKER_SIDE_LEFT |
    SPEAKER_SIDE_RIGHT;

const speakersOrder = [
  SPEAKER_FRONT_LEFT,
  SPEAKER_FRONT_RIGHT,
  SPEAKER_FRONT_CENTER,
  SPEAKER_LOW_FREQUENCY,
  SPEAKER_BACK_LEFT,
  SPEAKER_BACK_RIGHT,
  SPEAKER_FRONT_LEFT_OF_CENTER,
  SPEAKER_FRONT_RIGHT_OF_CENTER,
  SPEAKER_BACK_CENTER,
  SPEAKER_SIDE_LEFT,
  SPEAKER_SIDE_RIGHT,
  SPEAKER_TOP_CENTER,
  SPEAKER_TOP_FRONT_LEFT,
  SPEAKER_TOP_FRONT_CENTER,
  SPEAKER_TOP_FRONT_RIGHT,
  SPEAKER_TOP_BACK_LEFT,
  SPEAKER_TOP_BACK_CENTER,
  SPEAKER_TOP_BACK_RIGHT
];

/// Counts the number of speaker channels enabled in the given [channelMask].
int countChannelsInMask(int channelMask) {
  int count = 0;
  for (var x in speakersOrder) {
    if ((channelMask & x) == x) {
      count++;
    }
  }
  return count;
}

/// Creates a channel mapping list mapping source channel indexes to target
/// channel indexes based on standard speaker layout bitmasks.
List<T> createMappingOfMasks<T>(
    int oldMask, int newMask, T Function(int from, int to) createMapping) {
  int oldCount = 0;
  int newCount = 0;
  List<T> mapping = [];
  for (int i = 0; i < speakersOrder.length; ++i) {
    if ((speakersOrder[i] & oldMask) != 0 &&
        (speakersOrder[i] & newMask) != 0) {
      mapping.add(createMapping(oldCount, newCount));
    }
    if ((speakersOrder[i] & oldMask) != 0) {
      oldCount++;
    }
    if ((speakersOrder[i] & newMask) != 0) {
      newCount++;
    }
  }
  return mapping;
}

/// Metadata stored in the LIST INFO chunk of the WAV file.
class ListInfo {
  /// Track/Song title (INAM ID)
  String name;

  /// Album/Product name (IPRD ID)
  String product;

  /// Artist name (IART ID)
  String artist;

  /// Creation date / Year (ICRD ID)
  String date;

  /// Comment or description (ICMT ID)
  String comment;

  /// Genre of the track (IGNR ID)
  String genre;

  /// Track number (ITRK ID)
  String trackNumber;

  ListInfo(this.name, this.product, this.artist, this.date, this.comment,
      this.genre, this.trackNumber);

  /// Computes the overall size of the LIST INFO metadata chunk when written to disk.
  int get sizeOnDisk {
    int s = [name, product, artist, date, comment, genre, trackNumber]
        .fold<int>(
            0,
            (previousValue, element) =>
                previousValue +
                ((element.isNotEmpty &&
                        element.codeUnits.every((e) => e > 0 && e <= 127))
                    ? 8 + roundUp2(element.length + 1)
                    : 0));
    if (s > 0) {
      s += 4; //for INFO tag
    }
    return s;
  }

  /// Writes all valid metadata entries into the provided [data] byte buffer.
  ///
  /// Returns the total bytes written.
  int writeToChunk(ByteData data, Endian numEndianess) {
    var entries = <MapEntry<int, String>>[
      MapEntry(INAM_ID, name),
      MapEntry(IPRD_ID, product),
      MapEntry(IART_ID, artist),
      MapEntry(ICRD_ID, date),
      MapEntry(ICMT_ID, comment),
      MapEntry(IGNR_ID, genre),
      MapEntry(ITRK_ID, trackNumber)
    ];
    int position = 0;
    for (var entry in entries) {
      var codeUnits = entry.value.codeUnits;
      if (entry.value.isNotEmpty && codeUnits.every((e) => e > 0 && e <= 127)) {
        data.setUint32(position, entry.key, Endian.big);
        data.setUint32(
            position + 4, roundUp2(codeUnits.length + 1), numEndianess);
        data.buffer
            .asUint8List(data.offsetInBytes + position + 8)
            .setRange(0, codeUnits.length, codeUnits);
        position = position + 8 + roundUp2(codeUnits.length + 1);
      }
    }
    return position;
  }
}

/// Represents the format specifications of a WAV file.
class WavFormat {
  /// The number of audio channels.
  final int numChannels;

  /// Bytes per block of sample (summed across all channels for a single sample frame).
  final int blockAlign;

  /// The number of valid bits per sample in the loaded WAV file (e.g. 24 bits inside a 32-bit container).
  final int validBitsPerSample;

  /// The physical size in bits of the sample container (e.g. 8, 16, 24, 32, 64).
  final int containerBitsPerSample;

  // Samples per second.
  int _sampleRate;

  /// Gets the sample rate (samples per second).
  int get sampleRate => _sampleRate;

  /// Sets the sample rate. Throws [ArgumentError] if the rate is out of bounds.
  set sampleRate(int sampleRate) {
    if (sampleRate < 1 || sampleRate >= (1 << 31)) {
      throw ArgumentError(
          "sampleRate does not match the supported range of this library");
    }
    _sampleRate = sampleRate;
  }

  int _channelMask;

  /// Gets the speaker configuration layout mask.
  int get channelMask => _channelMask;

  /// Sets the speaker configuration layout mask. Throws [ArgumentError] if it doesn't match the channel count.
  set channelMask(int channelMask) {
    if (countChannelsInMask(channelMask) != numChannels) {
      throw ArgumentError(
          "channelMask does not match the number of channels present");
    }
    _channelMask = channelMask;
  }

  /// The generic format type (PCM or IEEE Float and bit depth).
  final FormatType formatType;

  WavFormat(this.numChannels, this._sampleRate, this.blockAlign,
      this.validBitsPerSample, this.containerBitsPerSample, this.formatType,
      {int channelMask = 0})
      : _channelMask = channelMask;
}

/// An abstract class representing WAV audio file content.
///
/// Contains information about the format, metadata (LIST INFO), and
/// provides methods to perform common format conversions and channel mixing.
abstract class IWavContent {
  /// Total number of samples in each channel. (This does not represent total samples across all channels.)
  int get numSamples => _samplesStorage.samplesPerChannel;

  /// Number of audio channels.
  int get numChannels => format.numChannels;

  /// Sample rate (samples per second).
  int get sampleRate => format._sampleRate;

  /// The channelMask telling the assigned speaker position for each channel.
  int get channelMask => format._channelMask;

  /// Number of bits per sample container (e.g. 16, 24, 32).
  int get bitsPerSample => format.containerBitsPerSample;

  /// Returns the duration of the WAV content in seconds.
  double get duration => _samplesStorage.samplesPerChannel / format.sampleRate;

  final WavFormat _format;

  /// The format descriptor of this WAV file content.
  WavFormat get format => _format;

  /// The type of storage structure used in memory.
  final StorageType storageType;

  /// Stores data of the LIST INFO metadata chunk, or null if not present.
  final ListInfo? info;

  final IWavSamplesStorage _samplesStorage;

  IWavContent(this._format, this.storageType, this._samplesStorage,
      {this.info});

  /// Internal cloning helper to duplicate WAV content structure with modified storage/format.
  IWavContent _cloneWith(IWavSamplesStorage? samplesStorage, WavFormat? format);

  /// Updates the sample rate in the format descriptor.
  void setSampleRate(int sampleRate) {
    format.sampleRate = sampleRate;
  }

  /// Reverses the audio samples in-place for all channels in this content.
  void reverse() {
    _samplesStorage.reverse();
  }

  /// Converts a mono (1 channel) WAV content to stereo (2 channels) by cloning the channel.
  ///
  /// Throws [StateError] if the current content is not mono.
  IWavContent monoToStereo() {
    if (numChannels != 1) {
      throw StateError("Input is not mono");
    }
    return _cloneWith(
        _samplesStorage.mixTogether(numSamples, 2, [
          MixingInfo(_samplesStorage, [
            ChannelMapping(0, 0, 0, numSamples, 0),
            ChannelMapping(0, 1, 0, numSamples, 0),
          ])
        ]),
        WavFormat(
            2,
            sampleRate,
            2 * (format.containerBitsPerSample ~/ 8),
            format.validBitsPerSample,
            format.containerBitsPerSample,
            format.formatType,
            channelMask: SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT));
  }

  /// Converts stereo (2 channels) WAV content to mono (1 channel) by mixing them together.
  ///
  /// Throws [StateError] if the current content is not stereo.
  IWavContent stereoToMono() {
    if (numChannels != 2) {
      throw StateError("Input is not stereo");
    }
    return _cloneWith(
        _samplesStorage.mixTogether(numSamples, 1, [
          MixingInfo(_samplesStorage, [
            ChannelMapping(0, 0, 0, numSamples, 0),
            ChannelMapping(1, 0, 0, numSamples, 0),
          ])
        ]),
        WavFormat(
            1,
            sampleRate,
            (format.containerBitsPerSample ~/ 8),
            format.validBitsPerSample,
            format.containerBitsPerSample,
            format.formatType,
            channelMask: SPEAKER_FRONT_CENTER));
  }

  /// Mixes all channels down into a single mono channel.
  IWavContent toMono() {
    return _cloneWith(
        _samplesStorage.mixTogether(numSamples, 1, [
          MixingInfo(
              _samplesStorage,
              List.generate(numChannels,
                  (index) => ChannelMapping(index, 0, 0, numSamples, 0)))
        ]),
        WavFormat(
            1,
            sampleRate,
            (format.containerBitsPerSample ~/ 8),
            format.validBitsPerSample,
            format.containerBitsPerSample,
            format.formatType,
            channelMask: SPEAKER_FRONT_CENTER));
  }

  /// Appends another [IWavContent] section to the end of this content.
  ///
  /// Both sections must have the same [storageType] and [sampleRate].
  /// Throws [StateError] if they cannot be appended due to format mismatch.
  IWavContent append(IWavContent other) {
    if (storageType != other.storageType) {
      throw StateError("the appended section is not stored in the same format");
    }
    if (sampleRate != other.sampleRate) {
      throw StateError("the appended section has different sample rate");
    }

    if (format.channelMask != 0 && other.format.channelMask != 0) {
      int outputChannelsMask = format.channelMask | other.format.channelMask;
      int outputChannels = countChannelsInMask(outputChannelsMask);
      List<ChannelMapping> thisMapping = createMappingOfMasks(
          format.channelMask,
          outputChannelsMask,
          (from, to) => ChannelMapping(from, to, 0, numSamples, 0));
      List<ChannelMapping> otherMapping = createMappingOfMasks(
          other.format.channelMask,
          outputChannelsMask,
          (from, to) =>
              ChannelMapping(from, to, 0, other.numSamples, numSamples));
      int newValidBits = min(format.containerBitsPerSample,
          max(format.validBitsPerSample, other.format.validBitsPerSample));
      return _cloneWith(
          _samplesStorage
              .mixTogether(numSamples + other.numSamples, outputChannels, [
            MixingInfo(_samplesStorage, thisMapping),
            MixingInfo(other._samplesStorage, otherMapping)
          ]),
          WavFormat(
              outputChannels,
              sampleRate,
              outputChannels * (format.containerBitsPerSample ~/ 8),
              newValidBits,
              format.containerBitsPerSample,
              format.formatType,
              channelMask: outputChannelsMask));
    }

    throw StateError("channels mapping mismatch. try to append manually");
  }

  /// Returns `true` if this is a mono track.
  bool get isMono => numChannels == 1;

  /// Returns `true` if this is a stereo track.
  bool get isStereo => numChannels == 2;

  /// Writes the sample storage contents to [data] byte data.
  void exportStorageAsBytes(ByteData data, Endian numEndianess) {
    _samplesStorage.writeStorage(
        data, numEndianess, format.containerBitsPerSample ~/ 8);
  }

  /// Converts this WAV content to unsigned 8-bit PCM format.
  WavContent<Uint8Storage> toPcm8() {
    return WavContent<Uint8Storage>(
        WavFormat(format.numChannels, format.sampleRate, 1 * format.numChannels,
            8, 8, FormatType.pcm8,
            channelMask: format.channelMask),
        StorageType.uint8,
        _samplesStorage.convertToUint8(),
        info: info);
  }

  /// Converts this WAV content to signed 16-bit PCM format.
  WavContent<Int16Storage> toPcm16() {
    return WavContent<Int16Storage>(
        WavFormat(format.numChannels, format.sampleRate, 2 * format.numChannels,
            16, 16, FormatType.pcm16,
            channelMask: format.channelMask),
        StorageType.int16,
        _samplesStorage.convertToInt16(),
        info: info);
  }

  /// Converts this WAV content to signed 24-bit PCM format.
  WavContent<Int32Storage> toPcm24() {
    return WavContent<Int32Storage>(
        WavFormat(format.numChannels, format.sampleRate, 3 * format.numChannels,
            24, 24, FormatType.pcm24,
            channelMask: format.channelMask),
        StorageType.int32,
        _samplesStorage.convertToInt32(),
        info: info);
  }

  /// Converts this WAV content to signed 32-bit PCM format.
  WavContent<Int32Storage> toPcm32() {
    return WavContent<Int32Storage>(
        WavFormat(format.numChannels, format.sampleRate, 4 * format.numChannels,
            32, 32, FormatType.pcm32,
            channelMask: format.channelMask),
        StorageType.int32,
        _samplesStorage.convertToInt32(),
        info: info);
  }

  /// Converts this WAV content to 32-bit IEEE float format.
  WavContent<Float32Storage> toFloat32() {
    return WavContent<Float32Storage>(
        WavFormat(format.numChannels, format.sampleRate, 4 * format.numChannels,
            24, 32, FormatType.float32,
            channelMask: format.channelMask),
        StorageType.float32,
        _samplesStorage.convertToFloat32(),
        info: info);
  }

  /// Converts this WAV content to 64-bit IEEE float format.
  WavContent<Float64Storage> toFloat64() {
    return WavContent<Float64Storage>(
        WavFormat(format.numChannels, format.sampleRate, 8 * format.numChannels,
            53, 64, FormatType.float64,
            channelMask: format.channelMask),
        StorageType.float64,
        _samplesStorage.convertToFloat64(),
        info: info);
  }

  /// Converts this WAV content to the format specified by the given format string name
  /// (`u8`, `i16`, `i24`, `i32`, `f32`, `f64`).
  IWavContent to(String format) {
    switch (format) {
      case 'u8':
        return toPcm8();
      case 'i16':
        return toPcm16();
      case 'i24':
        return toPcm24();
      case 'i32':
        return toPcm32();
      case 'f32':
        return toFloat32();
      case 'f64':
        return toFloat64();
    }
    throw ArgumentError(
        "unrecognized format string. should be one of u8|i16|i24|i32|f32|f64");
  }

  /// Converts this WAV content to the specified [FormatType].
  IWavContent toFormat(FormatType formatType) {
    switch (formatType) {
      case FormatType.pcm8:
        return toPcm8();
      case FormatType.pcm16:
        return toPcm16();
      case FormatType.pcm24:
        return toPcm24();
      case FormatType.pcm32:
        return toPcm32();
      case FormatType.float32:
        return toFloat32();
      case FormatType.float64:
        return toFloat64();
    }
  }
}

/// Concrete implementation of [IWavContent] parameterized by the sample storage type [T].
class WavContent<T extends IWavSamplesStorage> extends IWavContent {
  /// Gets the concrete sample storage container instance.
  T get samplesStorage => _samplesStorage as T;

  static const _storageTypeCheck = <StorageType, Type>{
    StorageType.uint8: Uint8Storage,
    StorageType.int16: Int16Storage,
    StorageType.int32: Int32Storage,
    StorageType.float32: Float32Storage,
    StorageType.float64: Float64Storage
  };

  WavContent(super.format, super.storageType, super._samplesStorage,
      {super.info}) {
    if (T != _storageTypeCheck[storageType]) {
      throw ArgumentError("Incompatible storage type");
    }
    if (format.numChannels != _samplesStorage.channels) {
      throw ArgumentError(
          "numChannels in format does not match numChannels in storage");
    }
  }

  @override
  IWavContent _cloneWith(
      IWavSamplesStorage? samplesStorage, WavFormat? format) {
    return WavContent<T>(
        format ?? _format, storageType, samplesStorage ?? _samplesStorage,
        info: info);
  }
}
