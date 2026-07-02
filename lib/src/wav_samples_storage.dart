import 'dart:math';
import 'dart:typed_data';

import 'package:wav_io/src/byte_data_24bit.dart';

/// The format of the WAV audio data on disk.
enum FormatType {
  /// Unsigned 8-bit PCM.
  pcm8,
  /// Signed 16-bit PCM.
  pcm16,
  /// Signed 24-bit PCM.
  pcm24,
  /// Signed 32-bit PCM.
  pcm32,
  /// 32-bit IEEE Floating-Point.
  float32,
  /// 64-bit IEEE Floating-Point.
  float64
}

/// The internal representation / storage type of audio samples in memory.
enum StorageType {
  /// Samples stored as [Uint8List] (range 0 to 255).
  uint8,
  /// Samples stored as [Int16List] (range -32768 to 32767).
  int16,
  /// Samples stored as [Int32List] (range -2147483648 to 2147483647).
  int32,
  /// Samples stored as [Float32List] (range -1.0 to 1.0).
  float32,
  /// Samples stored as [Float64List] (range -1.0 to 1.0).
  float64
}

/// Defines how a channel from a source audio storage is mapped to a target channel,
/// including sample offset, length, and scaling factor.
class ChannelMapping {
  /// The source channel index.
  int fromChannel;
  /// The target channel index.
  int toChannel;
  /// The starting offset in the source channel.
  int offsetSource;
  /// The number of samples to map.
  int length;
  /// The starting offset in the target channel.
  int offsetOutput;
  /// The amplitude scaling factor applied to mapped samples.
  double scale;

  ChannelMapping(this.fromChannel, this.toChannel, this.offsetSource,
      this.length, this.offsetOutput,
      [this.scale = 1.0]);
}

/// Contains an input storage source and a list of channel mappings to apply.
class MixingInfo {
  /// The source audio samples storage.
  IWavSamplesStorage input;
  /// The list of channel mappings from the input storage.
  List<ChannelMapping> channelMappings;

  MixingInfo(this.input, this.channelMappings);
}

/// An abstract interface representing audio samples storage in memory.
abstract class IWavSamplesStorage {
  IWavSamplesStorage(this.samplesPerChannel, this.channels);

  /// Number of audio samples per channel.
  int samplesPerChannel;

  /// Number of audio channels.
  int channels;

  static final Random _rGen = Random();

  /// Total number of samples per channel.
  int get length => samplesPerChannel;

  /// Converts the underlying samples storage to 32-bit floating point storage.
  ///
  /// If [forceDuplication] is true, a new instance is guaranteed to be returned
  /// even if the storage is already in float32.
  Float32Storage convertToFloat32({bool forceDuplication = false});

  /// Converts the underlying samples storage to 64-bit floating point storage.
  ///
  /// If [forceDuplication] is true, a new instance is guaranteed to be returned
  /// even if the storage is already in float64.
  Float64Storage convertToFloat64({bool forceDuplication = false});

  /// Converts the underlying samples storage to signed 16-bit integer storage.
  ///
  /// [enableDithering] controls whether triangular probability density function
  /// dithering is applied to reduce quantization distortion.
  /// If [forceDuplication] is true, a new instance is guaranteed to be returned.
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false});

  /// Converts the underlying samples storage to signed 32-bit integer storage.
  ///
  /// If [forceDuplication] is true, a new instance is guaranteed to be returned.
  Int32Storage convertToInt32({bool forceDuplication = false});

  /// Converts the underlying samples storage to unsigned 8-bit integer storage.
  ///
  /// [enableDithering] controls whether triangular probability density function
  /// dithering is applied to reduce quantization distortion.
  /// If [forceDuplication] is true, a new instance is guaranteed to be returned.
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false});

  /// Mixes samples from the provided `mixInfo` list into a newly allocated
  /// storage block of `totalLength` and `numChannels`.
  /// It expects `mixInfo` to describe how different input channels are mapped,
  /// offset, scaled, and added into the resulting storage's channels.
  /// It silently ignores mapping entries with scales that are completely out of
  /// range or extremely close to zero, channels that are out of bounds, and input
  /// storage types that do not match the expected underlying type.
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo);

  /// Writes the underlying samples data into [data] as bytes, conforming to
  /// the specified endianness and [bytesPerSample].
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample);

  static void _int16ListToFloat32(Int16List list, Float32List out) {
    int length = list.length;
    final double multiplier = 1 / (1 << 15);
    for (int i = 0; i < length; ++i) {
      out[i] = list[i] * multiplier;
    }
  }

  static void _int16ListToFloat64(Int16List list, Float64List out) {
    int length = list.length;
    final double multiplier = 1 / (1 << 15);
    for (int i = 0; i < length; ++i) {
      out[i] = list[i] * multiplier;
    }
  }

  static void _int32ListToFloat32(Int32List list, Float32List out) {
    int length = list.length;
    final double multiplier = 1 / (1 << 31);
    for (int i = 0; i < length; ++i) {
      out[i] = list[i] * multiplier;
    }
  }

  static void _int32ListToFloat64(Int32List list, Float64List out) {
    int length = list.length;
    final double multiplier = 1 / (1 << 31);
    for (int i = 0; i < length; ++i) {
      out[i] = list[i] * multiplier;
    }
  }

  static void _int32ListToInt16(
      Int32List list, Int16List out, bool enableDithering) {
    int length = list.length;
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] = ((list[i] +
                    0x7FFF +
                    _rGen.nextInt(0x10000) -
                    _rGen.nextInt(0x10000)) >>
                16)
            .clamp(-32768, 32767);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = ((list[i] + 0x7FFF) >> 16).clamp(-32768, 32767);
      }
    }
  }

  static void _int16ListToInt32(Int16List list, Int32List out) {
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      out[i] = list[i] << 16;
    }
  }

  static void _float32ListToInt16(
      Float32List list, Int16List out, bool enableDithering) {
    int length = list.length;
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 32768.0 + (_rGen.nextDouble() - _rGen.nextDouble()))
            .round()
            .clamp(-32768, 32767);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 32768.0).round().clamp(-32768, 32767);
      }
    }
  }

  static void _float32ListToInt32(Float32List list, Int32List out) {
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] * 2147483648).round().clamp(-2147483648, 2147483647);
    }
  }

  static void _float64ListToInt16(
      Float64List list, Int16List out, bool enableDithering) {
    final int length = list.length;
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 32768.0 + (_rGen.nextDouble() - _rGen.nextDouble()))
            .round()
            .clamp(-32768, 32767);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 32768.0).round().clamp(-32768, 32767);
      }
    }
  }

  static void _float64ListToInt32(Float64List list, Int32List out) {
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] * 2147483648).round().clamp(-2147483648, 2147483647);
    }
  }

  static void _uint8ListToFloat32(Uint8List list, Float32List out) {
    int length = list.length;
    final double multiplier = 1 / 128.0;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] - 128) * multiplier;
    }
  }

  static void _uint8ListToFloat64(Uint8List list, Float64List out) {
    int length = list.length;
    final double multiplier = 1 / 128.0;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] - 128) * multiplier;
    }
  }

  static void _uint8ListToInt16(Uint8List list, Int16List out) {
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] - 128) << 8;
    }
  }

  static void _uint8ListToInt32(Uint8List list, Int32List out) {
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      out[i] = (list[i] - 128) << 24;
    }
  }

  static void _int16ListToUint8(
      Int16List list, Uint8List out, bool enableDithering) {
    int length = list.length;
    const int domainShift = 128 << 8;
    const int roundConst = (1 << 7) - 1;
    const int totalShift = roundConst + domainShift; //0x807F
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] = (((list[i] +
                    totalShift +
                    _rGen.nextInt(0x100) -
                    _rGen.nextInt(0x100)) >>
                8))
            .clamp(0, 255);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = ((list[i] + totalShift) >> 8).clamp(0, 255);
      }
    }
  }

  static void _int32ListToUint8(
      Int32List list, Uint8List out, bool enableDithering) {
    int length = list.length;
    const int domainShift = 128 << 24;
    const int roundConst = (1 << 23) - 1;
    const int totalShift = roundConst + domainShift; //0x807FFFF
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] = (((list[i] +
                    totalShift +
                    _rGen.nextInt(0x1000000) -
                    _rGen.nextInt(0x1000000)) >>
                24))
            .clamp(0, 255);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = (((list[i] + totalShift) >> 24)).clamp(0, 255);
      }
    }
  }

  static void _float32ListToUint8(
      Float32List list, Uint8List out, bool enableDithering) {
    final int length = list.length;
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] =
            (list[i] * 128.0 + 128 + (_rGen.nextDouble() - _rGen.nextDouble()))
                .round()
                .clamp(0, 255);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 128 + 128).round().clamp(0, 255);
      }
    }
  }

  static void _float64ListToUint8(
      Float64List list, Uint8List out, bool enableDithering) {
    int length = list.length;
    if (enableDithering) {
      for (int i = 0; i < length; ++i) {
        out[i] =
            (list[i] * 128.0 + 128 + (_rGen.nextDouble() - _rGen.nextDouble()))
                .round()
                .clamp(0, 255);
      }
    } else {
      for (int i = 0; i < length; ++i) {
        out[i] = (list[i] * 128 + 128).round().clamp(0, 255);
      }
    }
  }
}

/// Storage for audio samples represented as unsigned 8-bit integers (PCM 8-bit format).
///
/// Under this storage, values range from 0 to 255, where 128 represents silence (zero amplitude).
class Uint8Storage extends IWavSamplesStorage {
  /// The audio samples data list per channel.
  final List<Uint8List> samplesData;

  /// Creates a new empty [Uint8Storage] with the specified length and channels.
  Uint8Storage(super.samplesPerChannel, super.channels)
      : samplesData =
            List.generate(channels, (index) => Uint8List(samplesPerChannel));

  /// Creates a new [Uint8Storage] by copying data from the given lists of samples.
  Uint8Storage.fromSamples(
      super.samplesPerChannel, super.channels, List<Uint8List> sourceSamples)
      : samplesData = List.generate(
            channels, (index) => Uint8List.fromList(sourceSamples[index]));

  /// Parses bytes from [data] to reconstruct a [Uint8Storage] instance.
  factory Uint8Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ channels;
    var storage = Uint8Storage(samplesPerChannel, channels);
    List<Uint8List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getUint8(currentDataOffset);
        currentDataOffset += 1;
      }
    }
    return storage;
  }

  @override
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample) {
    if (bytesPerSample != 1) throw ArgumentError("Unexpected bytesPerSample");
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        data.setUint8(currentDataOffset, samplesData[ch][s]);
        currentDataOffset += 1;
      }
    }
  }

  /// Helper to mix together 8-bit unsigned integer samples.
  static IWavSamplesStorage mixTogetherU8(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    var storage = Uint8Storage(totalLength, numChannels);
    var samplesData = storage.samplesData;
    for (var ch in samplesData) {
      ch.fillRange(0, totalLength, 128);
    }
    for (var m in mixInfo) {
      if (m.input is! Uint8Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0 || inChannelIndex >= m.input.channels) {
          continue;
        }
        int outChannelIndex = chm.toChannel;
        if (outChannelIndex < 0 || outChannelIndex >= numChannels) {
          continue;
        }
        var inputChannel =
            (m.input as Uint8Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[outChannelIndex];
        double scale = chm.scale;
        if (scale.abs() > 128 || scale.abs() < (1 / 128)) {
          continue;
        }
        if (scale == 0) {
          continue;
        }
        if (scale == 1) {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (inputChannel[chm.offsetSource + s] -
                        128 +
                        outputChannel[chm.offsetOutput + s] -
                        128 +
                        128)
                    .clamp(0, 255);
          }
        } else {
          int intScale = (scale * (1 << 16)).toInt();
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (((inputChannel[chm.offsetSource + s] - 128) * intScale >> 16) +
                        outputChannel[chm.offsetOutput + s] -
                        128 +
                        128)
                    .clamp(0, 255);
          }
        }
      }
    }
    return storage;
  }

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    return mixTogetherU8(totalLength, numChannels, mixInfo);
  }

  @override
  Float32Storage convertToFloat32({bool forceDuplication = false}) {
    Float32Storage storage = Float32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._uint8ListToFloat32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Int16Storage storage = Int16Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._uint8ListToInt16(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Int32Storage convertToInt32({bool forceDuplication = false}) {
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._uint8ListToInt32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Float64Storage convertToFloat64({bool forceDuplication = false}) {
    Float64Storage storage = Float64Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._uint8ListToFloat64(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false}) {
    if (forceDuplication) {
      return Uint8Storage.fromSamples(samplesPerChannel, channels, samplesData);
    }
    return this;
  }
}

/// Storage for audio samples represented as signed 16-bit integers (PCM 16-bit format).
///
/// Under this storage, values range from -32768 to 32767, where 0 represents silence.
class Int16Storage extends IWavSamplesStorage {
  /// The audio samples data list per channel.
  final List<Int16List> samplesData;

  /// Creates a new empty [Int16Storage] with the specified length and channels.
  Int16Storage(super.samplesPerChannel, super.channels)
      : samplesData =
            List.generate(channels, (index) => Int16List(samplesPerChannel));

  /// Creates a new [Int16Storage] by copying data from the given lists of samples.
  Int16Storage.fromSamples(
      super.samplesPerChannel, super.channels, List<Int16List> sourceSamples)
      : samplesData = List.generate(
            channels, (index) => Int16List.fromList(sourceSamples[index]));

  /// Parses bytes from [data] to reconstruct an [Int16Storage] instance.
  factory Int16Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 2);
    Int16Storage storage = Int16Storage(samplesPerChannel, channels);
    List<Int16List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getInt16(currentDataOffset, numEndianess);
        currentDataOffset += 2;
      }
    }
    return storage;
  }

  @override
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample) {
    if (bytesPerSample != 2) throw ArgumentError("Unexpected bytesPerSample");
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        data.setInt16(currentDataOffset, samplesData[ch][s], numEndianess);
        currentDataOffset += 2;
      }
    }
  }

  /// Helper to mix together 16-bit signed integer samples.
  static IWavSamplesStorage mixTogetherI16(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    Int16Storage storage = Int16Storage(totalLength, numChannels);
    var samplesData = storage.samplesData;
    for (var m in mixInfo) {
      if (m.input is! Int16Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0 || inChannelIndex >= m.input.channels) {
          continue;
        }
        int outChannelIndex = chm.toChannel;
        if (outChannelIndex < 0 || outChannelIndex >= numChannels) {
          continue;
        }
        var inputChannel =
            (m.input as Int16Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[outChannelIndex];
        double scale = chm.scale;
        if (scale.abs() > 32768 || scale.abs() < (1 / 32768)) {
          continue;
        }
        if (scale == 0) {
          continue;
        }
        if (scale == 1) {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (inputChannel[chm.offsetSource + s] +
                        outputChannel[chm.offsetOutput + s])
                    .clamp(-32768, 32767);
          }
        } else {
          int intScale = (scale * (1 << 32)).toInt();
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                ((inputChannel[chm.offsetSource + s] * intScale >> 32) +
                        outputChannel[chm.offsetOutput + s])
                    .clamp(-32768, 32767);
          }
        }
      }
    }
    return storage;
  }

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    return mixTogetherI16(totalLength, numChannels, mixInfo);
  }

  @override
  Float32Storage convertToFloat32({bool forceDuplication = false}) {
    Float32Storage storage = Float32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int16ListToFloat32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false}) {
    if (forceDuplication) {
      return Int16Storage.fromSamples(samplesPerChannel, channels, samplesData);
    }
    return this;
  }

  @override
  Int32Storage convertToInt32({bool forceDuplication = false}) {
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int16ListToInt32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Float64Storage convertToFloat64({bool forceDuplication = false}) {
    Float64Storage storage = Float64Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int16ListToFloat64(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Uint8Storage storage = Uint8Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int16ListToUint8(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }
}

/// Storage for audio samples represented as signed 32-bit integers (PCM 24-bit or 32-bit formats).
///
/// Under this storage, values range from -2147483648 to 2147483647, where 0 represents silence.
/// It uses SIMD ([Int32x4List]) for performance optimizations.
class Int32Storage extends IWavSamplesStorage {
  /// The underlying SIMD data block.
  final List<Int32x4List> simdData;

  /// The audio samples data list per channel, backed by the SIMD list.
  late final List<Int32List> samplesData;

  /// Creates a new empty [Int32Storage] with the specified length and channels.
  Int32Storage(super.samplesPerChannel, super.channels)
      : simdData = List.generate(
            channels, (index) => Int32x4List((samplesPerChannel + 3) ~/ 4)) {
    samplesData = List.generate(
        channels,
        (index) => Int32List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }

  /// Creates a new [Int32Storage] by copying data from the given lists of SIMD samples.
  Int32Storage.fromSamples(super.samplesPerChannel, super.channels,
      List<Int32x4List> sourceSimdSamples)
      : simdData = List.generate(channels,
            (index) => Int32x4List.fromList(sourceSimdSamples[index])) {
    samplesData = List.generate(
        channels,
        (index) => Int32List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }
  factory Int32Storage.fromBytes32(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 4);
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    List<Int32List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        int val = data.getInt32(currentDataOffset, numEndianess);
        samplesData[ch][s] = val;
        currentDataOffset += 4;
      }
    }
    return storage;
  }

  factory Int32Storage.fromBytes24(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 3);
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    List<Int32List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        int val = data.getInt24(currentDataOffset, numEndianess) << 8;
        samplesData[ch][s] = val;
        currentDataOffset += 3;
      }
    }
    return storage;
  }
  @override
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample) {
    int currentDataOffset = 0;
    if (bytesPerSample == 3) {
      for (int s = 0; s < samplesPerChannel; ++s) {
        for (int ch = 0; ch < channels; ++ch) {
          data.setInt24(
              currentDataOffset, samplesData[ch][s] >> 8, numEndianess);
          currentDataOffset += 3;
        }
      }
    } else if (bytesPerSample == 4) {
      for (int s = 0; s < samplesPerChannel; ++s) {
        for (int ch = 0; ch < channels; ++ch) {
          data.setInt32(currentDataOffset, samplesData[ch][s], numEndianess);
          currentDataOffset += 4;
        }
      }
    } else {
      throw ArgumentError("Unexpected bytesPerSample");
    }
  }

  static IWavSamplesStorage mixTogetherI32(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    Int32Storage storage = Int32Storage(totalLength, numChannels);
    var samplesData = storage.samplesData;
    for (var m in mixInfo) {
      if (m.input is! Int32Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0 || inChannelIndex >= m.input.channels) {
          continue;
        }
        int outChannelIndex = chm.toChannel;
        if (outChannelIndex < 0 || outChannelIndex >= numChannels) {
          continue;
        }
        var inputChannel =
            (m.input as Int32Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[outChannelIndex];
        double scale = chm.scale;
        if (scale.abs() > 2147483648 || scale.abs() < (1 / 2147483648)) {
          continue;
        }
        if (scale == 0) {
          continue;
        }
        if (scale == 1) {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (inputChannel[chm.offsetSource + s] +
                        outputChannel[chm.offsetOutput + s])
                    .clamp(-2147483648, 2147483647);
          }
        } else {
          if (scale.abs() > 1) {
            for (int s = 0; s < actualLength; ++s) {
              outputChannel[chm.offsetOutput + s] =
                  ((inputChannel[chm.offsetSource + s] * scale) +
                          outputChannel[chm.offsetOutput + s])
                      .truncate()
                      .clamp(-2147483648, 2147483647);
            }
          } else {
            int intScale = (scale * (1 << 32)).toInt();
            for (int s = 0; s < actualLength; ++s) {
              outputChannel[chm.offsetOutput + s] =
                  (((inputChannel[chm.offsetSource + s] * intScale) >> 32) +
                          outputChannel[chm.offsetOutput + s])
                      .clamp(-2147483648, 2147483647);
            }
          }
        }
      }
    }
    return storage;
  }

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    return mixTogetherI32(totalLength, numChannels, mixInfo);
  }

  @override
  Float32Storage convertToFloat32({bool forceDuplication = false}) {
    Float32Storage storage = Float32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int32ListToFloat32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Int16Storage storage = Int16Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int32ListToInt16(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }

  @override
  Int32Storage convertToInt32({bool forceDuplication = false}) {
    if (forceDuplication) {
      return Int32Storage.fromSamples(samplesPerChannel, channels, simdData);
    }
    return this;
  }

  @override
  Float64Storage convertToFloat64({bool forceDuplication = false}) {
    Float64Storage storage = Float64Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int32ListToFloat64(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Uint8Storage storage = Uint8Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._int32ListToUint8(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }
}

/// Storage for audio samples represented as 64-bit IEEE floating-point numbers.
///
/// Under this storage, values normally range from -1.0 to 1.0, where 0.0 represents silence.
/// It uses SIMD ([Float64x2List]) for performance optimizations.
class Float64Storage extends IWavSamplesStorage {
  /// The underlying SIMD data block.
  final List<Float64x2List> simdData;

  /// The audio samples data list per channel, backed by the SIMD list.
  late final List<Float64List> samplesData;

  /// Creates a new empty [Float64Storage] with the specified length and channels.
  Float64Storage(super.samplesPerChannel, super.channels)
      : simdData = List.generate(
            channels, (index) => Float64x2List((samplesPerChannel + 1) ~/ 2)) {
    samplesData = List.generate(
        channels,
        (index) => Float64List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }

  /// Creates a new [Float64Storage] by copying data from the given lists of SIMD samples.
  Float64Storage.fromSamples(super.samplesPerChannel, super.channels,
      List<Float64x2List> sourceSimdSamples)
      : simdData = List.generate(channels,
            (index) => Float64x2List.fromList(sourceSimdSamples[index])) {
    samplesData = List.generate(
        channels,
        (index) => Float64List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }

  /// Parses bytes from [data] to reconstruct a [Float64Storage] instance.
  factory Float64Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 8);
    Float64Storage storage = Float64Storage(samplesPerChannel, channels);
    List<Float64List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getFloat64(currentDataOffset, numEndianess);
        currentDataOffset += 8;
      }
    }
    return storage;
  }

  @override
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample) {
    if (bytesPerSample != 8) throw ArgumentError("Unexpected bytesPerSample");
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        data.setFloat64(currentDataOffset, samplesData[ch][s], numEndianess);
        currentDataOffset += 8;
      }
    }
  }

  /// Helper to mix together 64-bit floating point samples.
  static IWavSamplesStorage mixTogetherF64(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    Float64Storage storage = Float64Storage(totalLength, numChannels);
    var samplesData = storage.samplesData;
    for (var m in mixInfo) {
      if (m.input is! Float64Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0 || inChannelIndex >= m.input.channels) {
          continue;
        }
        int outChannelIndex = chm.toChannel;
        if (outChannelIndex < 0 || outChannelIndex >= numChannels) {
          continue;
        }
        var inputChannel =
            (m.input as Float64Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[outChannelIndex];
        double scale = chm.scale;
        if (scale == 0) {
          continue;
        }
        _mixFloat64Simd(inputChannel, outputChannel, chm.offsetSource,
            chm.offsetOutput, actualLength, scale);
      }
    }
    return storage;
  }

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    return mixTogetherF64(totalLength, numChannels, mixInfo);
  }

  @override
  Float64Storage convertToFloat64({bool forceDuplication = false}) {
    if (forceDuplication) {
      return Float64Storage.fromSamples(samplesPerChannel, channels, simdData);
    }
    return this;
  }

  @override
  Float32Storage convertToFloat32({bool forceDuplication = false}) {
    Float32Storage storage = Float32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      storage.samplesData[index].setAll(0, samplesData[index]);
    }
    return storage;
  }

  @override
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Int16Storage storage = Int16Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float64ListToInt16(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }

  @override
  Int32Storage convertToInt32({bool forceDuplication = false}) {
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float64ListToInt32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Uint8Storage storage = Uint8Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float64ListToUint8(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }
}

/// Storage for audio samples represented as 32-bit IEEE floating-point numbers.
///
/// Under this storage, values normally range from -1.0 to 1.0, where 0.0 represents silence.
/// It uses SIMD ([Float32x4List]) for performance optimizations.
class Float32Storage extends IWavSamplesStorage {
  /// The underlying SIMD data block.
  final List<Float32x4List> simdData;

  /// The audio samples data list per channel, backed by the SIMD list.
  late final List<Float32List> samplesData;

  /// Creates a new empty [Float32Storage] with the specified length and channels.
  Float32Storage(super.samplesPerChannel, super.channels)
      : simdData = List.generate(
            channels, (index) => Float32x4List((samplesPerChannel + 3) ~/ 4)) {
    samplesData = List.generate(
        channels,
        (index) => Float32List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }

  /// Creates a new [Float32Storage] by copying data from the given lists of SIMD samples.
  Float32Storage.fromSamples(super.samplesPerChannel, super.channels,
      List<Float32x4List> sourceSimdSamples)
      : simdData = List.generate(channels,
            (index) => Float32x4List.fromList(sourceSimdSamples[index])) {
    samplesData = List.generate(
        channels,
        (index) => Float32List.view(simdData[index].buffer,
            simdData[index].offsetInBytes, samplesPerChannel));
  }

  factory Float32Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 4);
    Float32Storage storage = Float32Storage(samplesPerChannel, channels);
    List<Float32List> samplesData = storage.samplesData;
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getFloat32(currentDataOffset, numEndianess);
        currentDataOffset += 4;
      }
    }
    return storage;
  }
  @override
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample) {
    if (bytesPerSample != 4) throw ArgumentError("Unexpected bytesPerSample");
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        data.setFloat32(currentDataOffset, samplesData[ch][s], numEndianess);
        currentDataOffset += 4;
      }
    }
  }

  static IWavSamplesStorage mixTogetherF32(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    Float32Storage storage = Float32Storage(totalLength, numChannels);
    var samplesData = storage.samplesData;
    for (var m in mixInfo) {
      if (m.input is! Float32Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0 || inChannelIndex >= m.input.channels) {
          continue;
        }
        int outChannelIndex = chm.toChannel;
        if (outChannelIndex < 0 || outChannelIndex >= numChannels) {
          continue;
        }
        var inputChannel =
            (m.input as Float32Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[outChannelIndex];
        double scale = chm.scale;
        if (scale == 0) {
          continue;
        }
        _mixFloat32Simd(inputChannel, outputChannel, chm.offsetSource,
            chm.offsetOutput, actualLength, scale);
      }
    }
    return storage;
  }

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    return mixTogetherF32(totalLength, numChannels, mixInfo);
  }

  @override
  Float32Storage convertToFloat32({bool forceDuplication = false}) {
    if (forceDuplication) {
      return Float32Storage.fromSamples(samplesPerChannel, channels, simdData);
    }
    return this;
  }

  @override
  Float64Storage convertToFloat64({bool forceDuplication = false}) {
    Float64Storage storage = Float64Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      storage.samplesData[index].setAll(0, samplesData[index]);
    }
    return storage;
  }

  @override
  Int16Storage convertToInt16(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Int16Storage storage = Int16Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float32ListToInt16(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }

  @override
  Int32Storage convertToInt32({bool forceDuplication = false}) {
    Int32Storage storage = Int32Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float32ListToInt32(
          samplesData[index], storage.samplesData[index]);
    }
    return storage;
  }

  @override
  Uint8Storage convertToUint8(
      {bool enableDithering = false, bool forceDuplication = false}) {
    Uint8Storage storage = Uint8Storage(samplesPerChannel, channels);
    for (int index = 0; index < channels; ++index) {
      IWavSamplesStorage._float32ListToUint8(
          samplesData[index], storage.samplesData[index], enableDithering);
    }
    return storage;
  }
}

void _mixFloat32Simd(Float32List inputChannel, Float32List outputChannel,
    int offsetSource, int offsetOutput, int actualLength, double scale) {
  int s = 0;
  if (actualLength >= 32 && offsetSource % 4 == offsetOutput % 4) {
    int alignOffset = (4 - (offsetSource % 4)) % 4;
    int preLoop = min(alignOffset, actualLength);
    for (; s < preLoop; ++s) {
      if (scale == 1) {
        outputChannel[offsetOutput + s] =
            inputChannel[offsetSource + s] + outputChannel[offsetOutput + s];
      } else {
        outputChannel[offsetOutput + s] =
            (inputChannel[offsetSource + s] * scale) +
                outputChannel[offsetOutput + s];
      }
    }

    int simdLength = (actualLength - s) ~/ 4;
    if (simdLength > 0) {
      var inSimd = Float32x4List.view(inputChannel.buffer,
          inputChannel.offsetInBytes + (offsetSource + s) * 4, simdLength);
      var outSimd = Float32x4List.view(outputChannel.buffer,
          outputChannel.offsetInBytes + (offsetOutput + s) * 4, simdLength);
      if (scale == 1) {
        for (int i = 0; i < simdLength; ++i) {
          outSimd[i] = inSimd[i] + outSimd[i];
        }
      } else {
        var simdScale = Float32x4.splat(scale);
        for (int i = 0; i < simdLength; ++i) {
          outSimd[i] = (inSimd[i] * simdScale) + outSimd[i];
        }
      }
      s += simdLength * 4;
    }
  }

  for (; s < actualLength; ++s) {
    if (scale == 1) {
      outputChannel[offsetOutput + s] =
          inputChannel[offsetSource + s] + outputChannel[offsetOutput + s];
    } else {
      outputChannel[offsetOutput + s] =
          (inputChannel[offsetSource + s] * scale) +
              outputChannel[offsetOutput + s];
    }
  }
}

void _mixFloat64Simd(Float64List inputChannel, Float64List outputChannel,
    int offsetSource, int offsetOutput, int actualLength, double scale) {
  int s = 0;
  if (actualLength >= 32 && offsetSource % 2 == offsetOutput % 2) {
    int alignOffset = (2 - (offsetSource % 2)) % 2;
    int preLoop = min(alignOffset, actualLength);
    for (; s < preLoop; ++s) {
      if (scale == 1) {
        outputChannel[offsetOutput + s] =
            inputChannel[offsetSource + s] + outputChannel[offsetOutput + s];
      } else {
        outputChannel[offsetOutput + s] =
            (inputChannel[offsetSource + s] * scale) +
                outputChannel[offsetOutput + s];
      }
    }

    int simdLength = (actualLength - s) ~/ 2;
    if (simdLength > 0) {
      var inSimd = Float64x2List.view(inputChannel.buffer,
          inputChannel.offsetInBytes + (offsetSource + s) * 8, simdLength);
      var outSimd = Float64x2List.view(outputChannel.buffer,
          outputChannel.offsetInBytes + (offsetOutput + s) * 8, simdLength);
      if (scale == 1) {
        for (int i = 0; i < simdLength; ++i) {
          outSimd[i] = inSimd[i] + outSimd[i];
        }
      } else {
        var simdScale = Float64x2.splat(scale);
        for (int i = 0; i < simdLength; ++i) {
          outSimd[i] = (inSimd[i] * simdScale) + outSimd[i];
        }
      }
      s += simdLength * 2;
    }
  }

  for (; s < actualLength; ++s) {
    if (scale == 1) {
      outputChannel[offsetOutput + s] =
          inputChannel[offsetSource + s] + outputChannel[offsetOutput + s];
    } else {
      outputChannel[offsetOutput + s] =
          (inputChannel[offsetSource + s] * scale) +
              outputChannel[offsetOutput + s];
    }
  }
}
