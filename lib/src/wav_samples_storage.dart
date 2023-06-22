import 'dart:math';
import 'dart:typed_data';

import 'package:wav_io/src/byte_data_24bit.dart';

enum FormatType { pcm16, pcm24, pcm32, float32, float64 }

enum StorageType { int16, int32, float32, float64 }

class ChannelMapping {
  int fromChannel;
  int toChannel;
  int offsetSource;
  int length;
  int offsetOutput;
  double scale;
  ChannelMapping(this.fromChannel, this.toChannel, this.offsetSource,
      this.length, this.offsetOutput,
      [this.scale = 1.0]);
}

class MixingInfo {
  IWavSamplesStorage input;
  List<ChannelMapping>
      channelMappings; // for every output channel, tell which input channel should be used.
  MixingInfo(this.input, this.channelMappings);
}

abstract class IWavSamplesStorage {
  IWavSamplesStorage(this.samplesPerChannel);
  int samplesPerChannel;

  //IWavSamplesStorage mixWith(int offset, IWavSamplesStorage other);
  int get channels;
  int get length => samplesPerChannel;
  Float32Storage convertToFloat32();
  Float64Storage convertToFloat64();
  Int16Storage convertToInt16();
  Int32Storage convertToInt32();
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo);
  void writeStorage(ByteData data, Endian numEndianess, int bytesPerSample);

  /*IWavSamplesStorage monoToStereo() {
    if (channels == 1)
    {
      return mixTogether(length, 2, [MixingInfo(this, [ChannelMapping(0, 0, 0, length, 0),ChannelMapping(0, 1, 0, length, 0)])]);
    }
    else throw ArgumentError("wav is not mono");
  }

  
  IWavSamplesStorage stereoToMono() {
    if (channels == 2)
    {
      return mixTogether(length, 1, [MixingInfo(this, [ChannelMapping(0, 0, 0, length, 0),ChannelMapping(1, 0, 0, length, 0)])]);
    }
    else throw ArgumentError("wav is not stereo");
  }*/

  static Float32List _int16ListToFloat32(Int16List list) {
    var fl = Float32List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      fl[i] = list[i] * (1 / (1 << 15));
    }
    return fl;
  }

  static Float64List _int16ListToFloat64(Int16List list) {
    var fl = Float64List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      fl[i] = list[i] * (1 / (1 << 15));
    }
    return fl;
  }

  static Float32List _int32ListToFloat32(Int32List list) {
    var fl = Float32List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      fl[i] = list[i] * (1 / (1 << 31));
    }
    return fl;
  }

  static Float64List _int32ListToFloat64(Int32List list) {
    var fl = Float64List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      fl[i] = list[i] * (1 / (1 << 31));
    }
    return fl;
  }

  static Int16List _int32ListToInt16(Int32List list) {
    var i16 = Int16List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i16[i] = list[i] >> 16;
    }
    return i16;
  }

  static Int32List _int16ListToInt32(Int16List list) {
    var i32 = Int32List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i32[i] = list[i] << 16;
    }
    return i32;
  }

  static Int16List _float32ListToInt16(Float32List list) {
    var i16 = Int16List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i16[i] = (list[i] * 32768).floor().clamp(-32768, 32767);
    }
    return i16;
  }

  static Int32List _float32ListToInt32(Float32List list) {
    var i32 = Int32List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i32[i] = (list[i] * 2147483648).floor().clamp(-2147483648, 2147483647);
    }
    return i32;
  }

  static Int16List _float64ListToInt16(Float64List list) {
    var i16 = Int16List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i16[i] = (list[i] * 32768).floor().clamp(-32768, 32767);
    }
    return i16;
  }

  static Int32List _float64ListToInt32(Float64List list) {
    var i32 = Int32List(list.length);
    int length = list.length;
    for (int i = 0; i < length; ++i) {
      i32[i] = (list[i] * 2147483648).floor().clamp(-2147483648, 2147483647);
    }
    return i32;
  }
}

class Int16Storage extends IWavSamplesStorage {
  final List<Int16List> samplesData;

  Int16Storage(this.samplesData, super.samplesPerChannel) {
    if (!samplesData.every((element) => element.length == samplesPerChannel)) {
      throw ArgumentError('not all channels are with the same length');
    }
  }
  factory Int16Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 2);
    List<Int16List> samplesData =
        List.generate(channels, (index) => Int16List(samplesPerChannel));
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getInt16(currentDataOffset, numEndianess);
        currentDataOffset += 2;
      }
    }
    return Int16Storage(samplesData, samplesPerChannel);
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

  @override
  int get channels => samplesData.length;

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    var samplesData =
        List.generate(numChannels, (index) => Int16List(totalLength));
    for (var m in mixInfo) {
      if (m.input is! Int16Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0) {
          continue;
        }
        var inputChannel =
            (m.input as Int16Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[chm.toChannel];
        double scale = chm.scale;
        if (scale.abs() > 16383 || scale.abs() < 0.000061035) {
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
    return Int16Storage(samplesData, totalLength);
  }

  @override
  Float32Storage convertToFloat32() {
    return Float32Storage(
        List<Float32List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int16ListToFloat32(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int16Storage convertToInt16() {
    return Int16Storage(
        List<Int16List>.generate(samplesData.length,
            (index) => Int16List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int32Storage convertToInt32() {
    return Int32Storage(
        List<Int32List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int16ListToInt32(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Float64Storage convertToFloat64() {
    return Float64Storage(
        List<Float64List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int16ListToFloat64(samplesData[index])),
        samplesPerChannel);
  }
}

class Int32Storage extends IWavSamplesStorage {
  final List<Int32List> samplesData;

  Int32Storage(this.samplesData, super.samplesPerChannel) {
    if (!samplesData.every((element) => element.length == samplesPerChannel)) {
      throw ArgumentError('not all channels are with the same length');
    }
  }
  factory Int32Storage.fromBytes32(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 4);
    List<Int32List> samplesData =
        List.generate(channels, (index) => Int32List(samplesPerChannel));
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getInt32(currentDataOffset, numEndianess);
        currentDataOffset += 4;
      }
    }
    return Int32Storage(samplesData, samplesPerChannel);
  }

  factory Int32Storage.fromBytes24(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 3);
    List<Int32List> samplesData =
        List.generate(channels, (index) => Int32List(samplesPerChannel));
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] =
            data.getInt24(currentDataOffset, numEndianess) << 8;
        currentDataOffset += 3;
      }
    }
    return Int32Storage(samplesData, samplesPerChannel);
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

  @override
  int get channels => samplesData.length;

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    var samplesData =
        List.generate(numChannels, (index) => Int32List(totalLength));
    for (var m in mixInfo) {
      if (m.input is! Int32Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0) {
          continue;
        }
        var inputChannel =
            (m.input as Int32Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[chm.toChannel];
        double scale = chm.scale;
        if (scale.abs() > 16383 || scale.abs() < 0.000061035) {
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
          int intScale = (scale * (1 << 16)).toInt();
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                ((inputChannel[chm.offsetSource + s] * intScale >> 16) +
                        outputChannel[chm.offsetOutput + s])
                    .clamp(-2147483648, 2147483647);
          }
        }
      }
    }
    return Int32Storage(samplesData, totalLength);
  }

  @override
  Float32Storage convertToFloat32() {
    return Float32Storage(
        List<Float32List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int32ListToFloat32(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int16Storage convertToInt16() {
    return Int16Storage(
        List<Int16List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int32ListToInt16(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int32Storage convertToInt32() {
    return Int32Storage(
        List<Int32List>.generate(samplesData.length,
            (index) => Int32List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Float64Storage convertToFloat64() {
    return Float64Storage(
        List<Float64List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._int32ListToFloat64(samplesData[index])),
        samplesPerChannel);
  }
}

class Float64Storage extends IWavSamplesStorage {
  final List<Float64List> samplesData;

  Float64Storage(this.samplesData, super.samplesPerChannel) {
    if (!samplesData.every((element) => element.length == samplesPerChannel)) {
      throw ArgumentError('not all channels are with the same length');
    }
  }
  factory Float64Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 8);
    List<Float64List> samplesData =
        List.generate(channels, (index) => Float64List(samplesPerChannel));
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getFloat64(currentDataOffset, numEndianess);
        currentDataOffset += 8;
      }
    }
    return Float64Storage(samplesData, samplesPerChannel);
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

  @override
  int get channels => samplesData.length;

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    var samplesData =
        List.generate(numChannels, (index) => Float64List(totalLength));
    for (var m in mixInfo) {
      if (m.input is! Float64Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0) {
          continue;
        }
        var inputChannel =
            (m.input as Float64Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[chm.toChannel];
        double scale = chm.scale;
        if (scale == 0) {
          continue;
        }
        if (scale == 1) {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (inputChannel[chm.offsetSource + s] +
                    outputChannel[chm.offsetOutput + s]);
          }
        } else {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                ((inputChannel[chm.offsetSource + s] * scale) +
                    outputChannel[chm.offsetOutput + s]);
          }
        }
      }
    }
    return Float64Storage(samplesData, totalLength);
  }

  @override
  Float64Storage convertToFloat64() {
    return Float64Storage(
        List<Float64List>.generate(samplesData.length,
            (index) => Float64List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Float32Storage convertToFloat32() {
    return Float32Storage(
        List<Float32List>.generate(samplesData.length,
            (index) => Float32List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int16Storage convertToInt16() {
    return Int16Storage(
        List<Int16List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._float64ListToInt16(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int32Storage convertToInt32() {
    return Int32Storage(
        List<Int32List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._float64ListToInt32(samplesData[index])),
        samplesPerChannel);
  }
}

class Float32Storage extends IWavSamplesStorage {
  final List<Float32List> samplesData;

  Float32Storage(this.samplesData, super.samplesPerChannel) {
    if (!samplesData.every((element) => element.length == samplesPerChannel)) {
      throw ArgumentError('not all channels are with the same length');
    }
  }

  factory Float32Storage.fromBytes(
      int channels, ByteData data, Endian numEndianess) {
    int samplesPerChannel = data.lengthInBytes ~/ (channels * 4);
    List<Float32List> samplesData =
        List.generate(channels, (index) => Float32List(samplesPerChannel));
    int currentDataOffset = 0;
    for (int s = 0; s < samplesPerChannel; ++s) {
      for (int ch = 0; ch < channels; ++ch) {
        samplesData[ch][s] = data.getFloat32(currentDataOffset, numEndianess);
        currentDataOffset += 4;
      }
    }
    return Float32Storage(samplesData, samplesPerChannel);
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

  @override
  int get channels => samplesData.length;

  @override
  IWavSamplesStorage mixTogether(
      int totalLength, int numChannels, List<MixingInfo> mixInfo) {
    var samplesData =
        List.generate(numChannels, (index) => Float32List(totalLength));
    for (var m in mixInfo) {
      if (m.input is! Float32Storage) {
        continue;
      }
      for (var chm in m.channelMappings) {
        int actualLength = min(chm.length, totalLength - chm.offsetOutput);
        actualLength = min(actualLength, m.input.length - chm.offsetSource);
        int inChannelIndex = chm.fromChannel;
        if (inChannelIndex < 0) {
          continue;
        }
        var inputChannel =
            (m.input as Float32Storage).samplesData[inChannelIndex];
        var outputChannel = samplesData[chm.toChannel];
        double scale = chm.scale;
        if (scale == 0) {
          continue;
        }
        if (scale == 1) {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                (inputChannel[chm.offsetSource + s] +
                    outputChannel[chm.offsetOutput + s]);
          }
        } else {
          for (int s = 0; s < actualLength; ++s) {
            outputChannel[chm.offsetOutput + s] =
                ((inputChannel[chm.offsetSource + s] * scale) +
                    outputChannel[chm.offsetOutput + s]);
          }
        }
      }
    }
    return Float32Storage(samplesData, totalLength);
  }

  @override
  Float32Storage convertToFloat32() {
    return Float32Storage(
        List<Float32List>.generate(samplesData.length,
            (index) => Float32List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Float64Storage convertToFloat64() {
    return Float64Storage(
        List<Float64List>.generate(samplesData.length,
            (index) => Float64List.fromList(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int16Storage convertToInt16() {
    return Int16Storage(
        List<Int16List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._float32ListToInt16(samplesData[index])),
        samplesPerChannel);
  }

  @override
  Int32Storage convertToInt32() {
    return Int32Storage(
        List<Int32List>.generate(
            samplesData.length,
            (index) =>
                IWavSamplesStorage._float32ListToInt32(samplesData[index])),
        samplesPerChannel);
  }
}
