import 'dart:math';
import 'dart:typed_data';

import 'package:wav_io/wav_io.dart';

// ignore: constant_identifier_names
const SPEAKER_FRONT_LEFT =	0x1;
// ignore: constant_identifier_names
const SPEAKER_FRONT_RIGHT =	0x2;
// ignore: constant_identifier_names
const SPEAKER_FRONT_CENTER = 0x4;
// ignore: constant_identifier_names
const SPEAKER_LOW_FREQUENCY =	0x8;
// ignore: constant_identifier_names
const SPEAKER_BACK_LEFT =	0x10;
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
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_DIRECTOUT = 0x0;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_MONO = SPEAKER_FRONT_CENTER;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_STEREO = SPEAKER_FRONT_LEFT|SPEAKER_FRONT_RIGHT;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_QUAD = SPEAKER_FRONT_LEFT|SPEAKER_FRONT_RIGHT|
                            SPEAKER_BACK_LEFT|SPEAKER_BACK_RIGHT;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_SURROUND = SPEAKER_FRONT_LEFT|SPEAKER_FRONT_RIGHT|
                            SPEAKER_FRONT_CENTER|SPEAKER_BACK_CENTER;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_5POINT1 = SPEAKER_FRONT_LEFT|SPEAKER_FRONT_RIGHT|
                            SPEAKER_FRONT_CENTER|SPEAKER_LOW_FREQUENCY|
                            SPEAKER_BACK_LEFT|SPEAKER_BACK_RIGHT;
// ignore: constant_identifier_names
const KSAUDIO_SPEAKER_5POINT1_SURROUND = SPEAKER_FRONT_LEFT|SPEAKER_FRONT_RIGHT|
                            SPEAKER_LOW_FREQUENCY|
                            SPEAKER_SIDE_LEFT|SPEAKER_SIDE_RIGHT;

const speakersOrder = [SPEAKER_FRONT_LEFT,
SPEAKER_FRONT_RIGHT,
SPEAKER_FRONT_CENTER,
SPEAKER_LOW_FREQUENCY,
SPEAKER_BACK_LEFT ,
SPEAKER_BACK_RIGHT,
SPEAKER_FRONT_LEFT_OF_CENTER,
SPEAKER_FRONT_RIGHT_OF_CENTER ,
SPEAKER_BACK_CENTER ,
SPEAKER_SIDE_LEFT ,
SPEAKER_SIDE_RIGHT ,
SPEAKER_TOP_CENTER ,
SPEAKER_TOP_FRONT_LEFT ,
SPEAKER_TOP_FRONT_CENTER ,
SPEAKER_TOP_FRONT_RIGHT ,
SPEAKER_TOP_BACK_LEFT ,
SPEAKER_TOP_BACK_CENTER ,
SPEAKER_TOP_BACK_RIGHT];

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
int countChannelsInMask(int channelMask)
{
  int count = 0;
  for (var x in speakersOrder)
  {
    if ((channelMask & x) == x)
    {
      count++;
    }
  }
  return count;
}

List<T> createMappingOfMasks<T>(int oldMask, int newMask, T Function(int from, int to) createMapping)
{
  int oldCount = 0;
  int newCount = 0;
  List<T> mapping = [];
  for (int i = 0; i< speakersOrder.length; ++i)
  {
    if ((speakersOrder[i] & oldMask ) != 0 && (speakersOrder[i] & newMask ) != 0)
    {
      mapping.add(createMapping(oldCount, newCount));
    }
    if ((speakersOrder[i] & oldMask ) != 0)
    {
      oldCount++;
    }
    if ((speakersOrder[i] & newMask ) != 0)
    {
      newCount++;
    }
  }
  return mapping;
}

class ListInfo
{
  String name;
  String product;
  String artist;
  String date;
  String comment;
  String genre;
  String trackNumber;
  ListInfo(this.name,this.product,this.artist,this.date,this.comment,this.genre,this.trackNumber);
  int get sizeOnDisk
  {
    int s = [name,product,artist,date,comment,genre,trackNumber].fold<int>(0, (previousValue, element) => previousValue+(element.isNotEmpty && element.codeUnits.every((e) => e>0 && e <=127)?8+roundUp2(element.length+1):0));
    if (s>0)
    {
      s+=4;//for INFO tag
    }
    return s;
  }
  // write the info as the data of List info subchunk (not including the subchunk header)
  int writeToChunk(ByteData data, Endian numEndianess)
  {
    
    var entires = <MapEntry<int,String>>[MapEntry(INAM_ID,name),MapEntry(IPRD_ID,product),
    MapEntry(IART_ID,artist),MapEntry(ICRD_ID,date),
    MapEntry(ICMT_ID,comment),MapEntry(IGNR_ID,genre),
    MapEntry(ITRK_ID,trackNumber)];
    int position = 0;
    for (var entry in entires)
    {
      var codeUnits = entry.value.codeUnits;
      if (entry.value.isNotEmpty && codeUnits.every((e) => e>0 && e <=127))
      {
        data.setUint32(position, entry.key ,Endian.big);
        data.setUint32(position+4, roundUp2(codeUnits.length+1) ,numEndianess);
        data.buffer.asUint8List(data.offsetInBytes+position+8).setRange(0, codeUnits.length,codeUnits);
        position = position + 8 + roundUp2(codeUnits.length+1);
      }
    }
    return position;
  }
  
}

class WavFormat
{
  /// The number of audio channels
  final int numChannels;
  /// bytes per block of sample (with multiple channels)
  final int blockAlign;

  /// The number of bits per sample in the loaded wav file.
  final int validBitsPerSample;

  /// The size in bits of sample container
  final int containerBitsPerSample;
  // Samples per second.
  final int sampleRate;

  int _channelMask;
  int get channelMask => _channelMask;
  set channelMask(int channelMask){
    if (countChannelsInMask(channelMask)!=numChannels)
    {
      throw ArgumentError("channelMask do not match the number of channels present");
    }
    _channelMask = channelMask;
  }
  final FormatType formatType;
  WavFormat(this.numChannels, this.sampleRate, this.blockAlign, this.validBitsPerSample,this.containerBitsPerSample
  ,this.formatType,{int channelMask = 0}):_channelMask = channelMask;
      
}


abstract class IWavContent
{
  /// Total number of samples in each channel. (This is not representing total samples in all channels.)
  int get numSamples => _samplesStorage.samplesPerChannel;
  /// Number of channels
  int get numChannels => format.numChannels;
  int get sampleRate => format.sampleRate;
  int get bitsPerSample => format.containerBitsPerSample;
  ///Returns the duration of the Wav in seconds.
  double get duration => _samplesStorage.samplesPerChannel/format.sampleRate;

  final WavFormat _format;
  WavFormat get format => _format;
  final StorageType storageType;
  final ListInfo? info;
  final IWavSamplesStorage _samplesStorage;
  IWavContent(this._format, this.storageType, this._samplesStorage, {this.info});
  IWavContent _cloneWith(IWavSamplesStorage? samplesStorage, WavFormat? format);

  IWavContent monoToStereo()
  {
    if (numChannels != 1)
    {
      throw StateError("Input is not mono");
    }
    return _cloneWith(
    _samplesStorage.mixTogether(numSamples, 2, [MixingInfo(_samplesStorage,[ChannelMapping(0, 0, 0, numSamples, 0),ChannelMapping(0, 1, 0, numSamples, 0),])]),
    WavFormat(2, sampleRate, 2*(format.containerBitsPerSample~/8), format.validBitsPerSample, format.containerBitsPerSample, format.formatType, channelMask: SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT));
  }
  IWavContent stereoToMono()
  {
    if (numChannels != 2)
    {
      throw StateError("Input is not stereo");
    }
    return _cloneWith(
    _samplesStorage.mixTogether(numSamples, 1, [MixingInfo(_samplesStorage,[ChannelMapping(0, 0, 0, numSamples, 0),ChannelMapping(1, 0, 0, numSamples, 0),])]),
    WavFormat(1, sampleRate, (format.containerBitsPerSample~/8), format.validBitsPerSample, format.containerBitsPerSample, format.formatType, channelMask: SPEAKER_FRONT_CENTER));
  }
  IWavContent toMono()
  {
    return _cloneWith(
    _samplesStorage.mixTogether(numSamples, 1, [MixingInfo(_samplesStorage,
    List.generate(numChannels, (index) => ChannelMapping(index, 0, 0, numSamples, 0))    
    )]),
    WavFormat(1, sampleRate, (format.containerBitsPerSample~/8), format.validBitsPerSample, format.containerBitsPerSample, format.formatType, channelMask: SPEAKER_FRONT_CENTER));
  }
  IWavContent append(IWavContent other)
  {
    if (storageType != other.storageType)
    {
      throw StateError("the appended section is not stored in the same format");
    }
    if (sampleRate != other.sampleRate)
    {
      throw StateError("the appended section has different sample rate");
    }

    if (format.channelMask !=0 && other.format.channelMask !=0)
    {
      
      int outputChannelsMask = format.channelMask|other.format.channelMask;
      int outputChannels = countChannelsInMask(outputChannelsMask);
      List<ChannelMapping> thisMapping = createMappingOfMasks(format.channelMask,outputChannelsMask, (from, to) => ChannelMapping(from,to,0,numSamples,0));
      List<ChannelMapping> otherMapping = createMappingOfMasks(other.format.channelMask,outputChannelsMask, (from, to) => ChannelMapping(from,to,0,other.numSamples,numSamples));
      int newValidBits = min(format.containerBitsPerSample,max(format.validBitsPerSample,other.format.validBitsPerSample));
      return _cloneWith(
    _samplesStorage.mixTogether(numSamples+other.numSamples, outputChannels, [MixingInfo(_samplesStorage,
       thisMapping
    ),MixingInfo(other._samplesStorage,
       otherMapping
    )])
    ,
    WavFormat(outputChannels, sampleRate, outputChannels* (format.containerBitsPerSample~/8), newValidBits,
     format.containerBitsPerSample, format.formatType,channelMask: outputChannelsMask));
    }

    throw StateError("channels mapping mismatch. try to append manually");
  }
  bool get isMono => numChannels == 1;
  bool get isStereo => numChannels == 2;

  void exportStorageAsBytes(ByteData data, Endian numEndianess)
  {
    _samplesStorage.writeStorage(data, numEndianess, format.containerBitsPerSample~/8);
  }
  WavContent<Int16Storage> toPcm16()
  {
    return WavContent<Int16Storage>(WavFormat(format.numChannels,format.sampleRate,2*format.numChannels,16,16,FormatType.pcm16,channelMask: format.channelMask),
    StorageType.int16,_samplesStorage.convertToInt16(),info: info);
  }
  WavContent<Int32Storage> toPcm24()
  {
    return WavContent<Int32Storage>(WavFormat(format.numChannels,format.sampleRate,3*format.numChannels,24,24,FormatType.pcm24,channelMask: format.channelMask),
    StorageType.int32,_samplesStorage.convertToInt32(),info: info);
  }
  WavContent<Int32Storage> toPcm32()
  {
    return WavContent<Int32Storage>(WavFormat(format.numChannels,format.sampleRate,4*format.numChannels,32,32,FormatType.pcm32,channelMask: format.channelMask),
    StorageType.int32,_samplesStorage.convertToInt32(),info: info);
  }

  WavContent<Float32Storage> toFloat32()
  {
    return WavContent<Float32Storage>(WavFormat(format.numChannels,format.sampleRate,4*format.numChannels,24,32,FormatType.float32,channelMask: format.channelMask),
    StorageType.float32,_samplesStorage.convertToFloat32(),info: info);
  }
  WavContent<Float64Storage> toFloat64()
  {
    return WavContent<Float64Storage>(WavFormat(format.numChannels,format.sampleRate,8*format.numChannels,53,64,FormatType.float64,channelMask: format.channelMask),
    StorageType.float64,_samplesStorage.convertToFloat64(),info: info);
  }
  IWavContent to(String format)
  {
    switch (format)
    {
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
    throw ArgumentError("unrecognized format string. should be one of i16|i24|i32|f32|f64");
  }
  IWavContent toFormat(FormatType formatType)
  {
    switch (formatType)
    {
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


class WavContent<T extends IWavSamplesStorage> extends IWavContent{
  /// The lists of samples per each audio channel
  T get samplesStorage => _samplesStorage as T;
  static const _storageTypeCheck= <StorageType,Type>{StorageType.int16 :Int16Storage,
  StorageType.int32 :Int32Storage,
  StorageType.float32 :Float32Storage,
  StorageType.float64 :Float64Storage};
  WavContent(super.format, super.storageType, super._samplesStorage,{super.info})
  {
    if (T != _storageTypeCheck[storageType])
    {
      throw ArgumentError("Incompatible storage type");
    }
    if (format.numChannels!= _samplesStorage.channels)
    {
      throw ArgumentError("numChannels in format, do not match numChannels in storage");
    }
  }

  @override
  IWavContent _cloneWith(IWavSamplesStorage? samplesStorage, WavFormat? format)
  {
    return WavContent<T>(format??_format,storageType,samplesStorage??_samplesStorage, info: info);
  }
}

