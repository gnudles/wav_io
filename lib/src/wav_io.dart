// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';
import 'dart:convert';

import 'package:wav_io/src/wav_samples_storage.dart';
import 'package:wav_io/src/wav_structure.dart';

import 'package:wav_io/src/result.dart';

//these constants represent the string in Big-Endian.
//Chunk id:

const RIFF_ID = 0x52494646; // 0x52494646 == 'RIFF'

const RIFX_ID = 0x52494658; // 0x52494646 == 'RIFX'
// RIFF forms:

const WAVE_ID = 0x57415645; // 0x57415645 == 'WAVE'

// WAVE subchuncks:

const fmt_ID = 0x666d7420; // 0x666d7420 == 'fmt '

const data_ID = 0x64617461; // 0x64617461 == 'data'

const fact_ID = 0x66616374; // 0x64617461 == 'fact'

const cue_ID = 0x63756520; // 0x666d7420 == 'cue '

const LIST_ID = 0x4c495354; // 0x4c495354 == 'LIST'

const CSET_ID = 0x43534554; // 0x43534554 == 'CSET'

//I haven't found information on the following, but audacity exports floats with
//this chunk.

const PEAK_ID = 0x5045414B; // 0x5045414B == 'PEAK'

//List types:

const INFO_ID = 0x494e464f; // 0x494e464f == 'INFO'

//INFO entries:

const INAM_ID = 0x494e414d; // Name (track title)

const IPRD_ID = 0x49505244; // Product (album title)

const IART_ID = 0x49415254; // Artist

const ICMT_ID = 0x49434d54; // Comment

const ICRD_ID = 0x49435244; // Creation Date (Year)

const IGNR_ID = 0x49474e52; // genre

const ITRK_ID = 0x4954524b; // track number

const WAVE_FORMAT_PCM = 0x0001;

const WAVE_FORMAT_ADPCM = 0x0002;

const WAVE_FORMAT_IEEE_FLOAT = 0x0003;

const WAVE_FORMAT_VSELP = 0x0004; /* Compaq Computer Corp. */

const WAVE_FORMAT_IBM_CVSD = 0x0005; /* IBM Corporation */

const WAVE_FORMAT_ALAW = 0x0006;

const WAVE_FORMAT_MULAW = 0x0007;

const WAVE_FORMAT_EXTENSIBLE = 0xFFFE;

class GUID {
  static Uint8List convert(int timeLow, int timeMid, int timeHiAndVersion,
      int clockSeqHiAndReserved, int clocSeqLow, List<int> list) {
    ByteData data = ByteData(16);
    data.setUint32(0, timeLow, Endian.little);
    data.setUint16(4, timeMid, Endian.little);
    data.setUint16(6, timeHiAndVersion, Endian.little);
    data.setUint8(8, clockSeqHiAndReserved);
    data.setUint8(9, clocSeqLow);
    data.setUint8(10, list[0]);
    data.setUint8(11, list[1]);
    data.setUint8(12, list[2]);
    data.setUint8(13, list[3]);
    data.setUint8(14, list[4]);
    data.setUint8(15, list[5]);
    return data.buffer.asUint8List();
  }

  static bool equal(Uint8List a1, Uint8List a2) {
    for (int i = 0; i < 16; ++i) {
      if (a1[i] != a2[i]) {
        return false;
      }
    }
    return true;
  }
}

final KSDATAFORMAT_SUBTYPE_PCM = GUID.convert(0x00000001, 0x0000, 0x0010, 0x80,
    0x00, [0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71]);
//"00000001-0000-0010-8000-00aa00389b71"

final KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = GUID.convert(0x00000003, 0x0000, 0x0010,
    0x80, 0x00, [0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71]);
//"00000003-0000-0010-8000-00aa00389b71"

enum WavParsingError {
  bufferIsTooSmall,
  notRiffChunk,
  chunkSizeExceedsBuffer,
  riffFormatIsNotWave,
  subChunkExceedsChunkSize,
  chunkSizeDontAlignWithSubChunks,
  noFmtSubChunk,
  noDataSubChunk,
  invalidFmtSizeForPCM,
  invalidFmtSizeForFloat,
  invalidFmtSizeForExtensible,
  unsupportedFormat,
  invalidNumChannels,
  invalidSampleRate,
  invalidByteRate,
  invalidBlockAlign,
  invalidBitsPerSample,
  unsupportedBitsPerSample,
  invalidExtensionSize,
  unsupportedExtension,
  invalidChannelMask,
  invalidDataChunkSize,
  invalidListInfo,
  unrecognizedListType,
  unrecognizedCharFormat,
  multipleDataChunksNotSupported,
  unexpectedError
}


int roundUp2(int x) => (x + 1) & (~1);

/// An interface to retrieve raw WAV header bytes from either memory buffers or files.
abstract class WavHeaderInput {
  /// Reads a 32-bit unsigned integer at [offset] using the specified [endian] byte order.
  int getUint32(int offset, Endian endian);

  /// Returns a [ByteData] view of the raw bytes starting at [offset] for [length] bytes.
  ByteData getByteData(int offset, int length);

  /// The total size of the input source.
  int get length;
}

/// A [WavHeaderInput] implementation wrapping a memory buffer of [ByteData].
class ByteDataHeaderInput implements WavHeaderInput {
  final ByteData data;
  ByteDataHeaderInput(this.data);

  @override
  int getUint32(int offset, Endian endian) => data.getUint32(offset, endian);

  @override
  ByteData getByteData(int offset, int length) =>
      data.buffer.asByteData(data.offsetInBytes + offset, length);

  @override
  int get length => data.lengthInBytes;
}

/// Container representing the parsed header metadata structure of a WAV file.
class ParsedWavHeader {
  final Endian numEndianness;
  final WavFormat format;
  final ListInfo? info;
  final int dataOffset;
  final int dataSize;

  ParsedWavHeader({
    required this.numEndianness,
    required this.format,
    this.info,
    required this.dataOffset,
    required this.dataSize,
  });
}

class SubChunkInfo {
  final int id;
  final int offset;
  final int size;
  SubChunkInfo(this.id, this.offset, this.size);
}

/// Parses the WAV header structure from the given [input] source.
Result<ParsedWavHeader, WavParsingError> parseWavHeader(WavHeaderInput input) {
  if (input.length <= 44) {
    return Result.error(WavParsingError.bufferIsTooSmall);
  }
  final int ckID = input.getUint32(0, Endian.big);
  if (ckID != RIFF_ID && ckID != RIFX_ID) {
    return Result.error(WavParsingError.notRiffChunk);
  }

  final Endian numEndianness = (ckID == RIFF_ID) ? Endian.little : Endian.big;

  final int ckSize = input.getUint32(4, numEndianness);
  if (roundUp2(ckSize) + 8 > input.length) {
    return Result.error(WavParsingError.chunkSizeExceedsBuffer);
  }

  final int fmtId = input.getUint32(8, Endian.big);
  if (fmtId != WAVE_ID) {
    return Result.error(WavParsingError.riffFormatIsNotWave);
  }

  int overallSubChunks = 0;
  final int subChunksTotalSize = ckSize - 4;
  final int subChunksStart = 12;
  bool metDataChunk = false;
  bool metCsetId = false;

  final List<SubChunkInfo> subChunks = [];

  for (int i = 0;
      i < 20 && subChunksTotalSize != overallSubChunks;
      ++i) // maximum of 20 subchunks allowed (to spot corrupted files)
  {
    overallSubChunks = roundUp2(overallSubChunks);
    if (subChunksTotalSize - overallSubChunks < 8) {
      return Result.error(WavParsingError.chunkSizeDontAlignWithSubChunks);
    }
    final int subCkId =
        input.getUint32(subChunksStart + overallSubChunks, Endian.big);
    overallSubChunks += 4;
    final int subCkSize =
        input.getUint32(subChunksStart + overallSubChunks, numEndianness);
    overallSubChunks += 4;
    if (subChunksTotalSize - overallSubChunks < subCkSize) {
      return Result.error(WavParsingError.subChunkExceedsChunkSize);
    }
    if (subCkId == data_ID) {
      if (metDataChunk) {
        return Result.error(WavParsingError.multipleDataChunksNotSupported);
      }
      metDataChunk = true;
    }
    if (subCkId == CSET_ID) {
      metCsetId = true;
    }
    subChunks.add(SubChunkInfo(
        subCkId, subChunksStart + overallSubChunks, subCkSize));
    overallSubChunks += subCkSize;
  }

  if (subChunksTotalSize != overallSubChunks) {
    return Result.error(WavParsingError.chunkSizeDontAlignWithSubChunks);
  }
  if (metDataChunk == false) {
    return Result.error(WavParsingError.noDataSubChunk);
  }

  late final WavFormat wavFormat;
  try {
    final fmtChunk = subChunks.firstWhere((sck) => sck.id == fmt_ID);
    final fmtView = input.getByteData(fmtChunk.offset, fmtChunk.size);
    final result = parseFmt(fmtView, numEndianness);
    if (result.isError) {
      return Result.error(result.error);
    }
    wavFormat = result.unwrap();
  } on StateError {
    return Result.error(WavParsingError.noFmtSubChunk);
  }

  final dataChunk = subChunks.firstWhere((sck) => sck.id == data_ID);
  final int dataOffset = dataChunk.offset;
  final int dataSize = dataChunk.size;

  ListInfo? listInfo;
  if (!metCsetId) // we do not support INFO list other than Ascii encoded
  {
    try {
      final listChunk = subChunks.firstWhere((sck) => sck.id == LIST_ID);
      final listView = input.getByteData(listChunk.offset, listChunk.size);
      final result = parseListChunk(listView, numEndianness);
      if (result.isOk) {
        listInfo = result.unwrap();
      } else {
        if (result.error != WavParsingError.unrecognizedListType &&
            result.error != WavParsingError.unrecognizedCharFormat) {
          return Result.error(result.error);
        }
      }
    } on StateError {
      //LIST chunk is optional
    }
  }

  return Result.ok(ParsedWavHeader(
    numEndianness: numEndianness,
    format: wavFormat,
    info: listInfo,
    dataOffset: dataOffset,
    dataSize: dataSize,
  ));
}

/// Decodes WAV audio from the given [data] byte buffer.
///
/// Returns a [Result] containing the parsed [IWavContent] on success,
/// or a [WavParsingError] on failure.
Result<IWavContent, WavParsingError> loadWav(ByteData data) {
  final input = ByteDataHeaderInput(data);
  final headerResult = parseWavHeader(input);
  if (headerResult.isError) {
    return Result.error(headerResult.error);
  }
  final header = headerResult.unwrap();

  final dataView = input.getByteData(header.dataOffset, header.dataSize);
  final dataResult = parseDataChunk(dataView, header.numEndianness, header.format);
  if (dataResult.isError) {
    return Result.error(dataResult.error);
  }
  final samplesStorage = dataResult.unwrap();

  IWavContent? output;
  const formatToStorageConversion = [
    StorageType.uint8,
    StorageType.int16,
    StorageType.int32,
    StorageType.int32,
    StorageType.float32,
    StorageType.float64
  ];
  final storageType = formatToStorageConversion[header.format.formatType.index];

  if (samplesStorage is Uint8Storage) {
    output = WavContent<Uint8Storage>(
        header.format, storageType, samplesStorage,
        info: header.info);
  } else if (samplesStorage is Int16Storage) {
    output = WavContent<Int16Storage>(
        header.format, storageType, samplesStorage,
        info: header.info);
  } else if (samplesStorage is Int32Storage) {
    output = WavContent<Int32Storage>(
        header.format, storageType, samplesStorage,
        info: header.info);
  } else if (samplesStorage is Float32Storage) {
    output = WavContent<Float32Storage>(
        header.format, storageType, samplesStorage,
        info: header.info);
  } else if (samplesStorage is Float64Storage) {
    output = WavContent<Float64Storage>(
        header.format, storageType, samplesStorage,
        info: header.info);
  }
  if (output != null) {
    return Result.ok(output);
  }
  return Result.error(WavParsingError.unexpectedError);
}

/// Suggests a recommended [FormatType] given a format tag and bits-per-sample depth.
FormatType recommendedFormatType(int wFormatTag, int bitsPerSample) {
  if (wFormatTag == WAVE_FORMAT_PCM) {
    if (bitsPerSample <= 8) {
      return FormatType.pcm8;
    } else if (bitsPerSample <= 16) {
      return FormatType.pcm16;
    } else if (bitsPerSample <= 24) {
      return FormatType.pcm24;
    } else /* bitsPerSample <= 32 */ {
      return FormatType.pcm32;
    }
  } else if (wFormatTag == WAVE_FORMAT_IEEE_FLOAT) {
    if (bitsPerSample <= 32) {
      return FormatType.float32;
    }
    return FormatType.float64;
  }
  return FormatType.float64;
}

Result<WavFormat, WavParsingError> parseFmt(
    ByteData data, Endian numEndianess) {
  int wFormatTag = data.getUint16(0, numEndianess);
  int wFormatTagActual = wFormatTag;
  if (wFormatTag != WAVE_FORMAT_PCM &&
      wFormatTag != WAVE_FORMAT_IEEE_FLOAT &&
      wFormatTag != WAVE_FORMAT_EXTENSIBLE) {
    return Result.error(WavParsingError.unsupportedFormat);
  }
  if ((data.lengthInBytes != 16 && wFormatTag == WAVE_FORMAT_PCM)) {
    return Result.error(WavParsingError.invalidFmtSizeForPCM);
  }
  if (((data.lengthInBytes != 18 && data.lengthInBytes != 16) &&
      wFormatTag == WAVE_FORMAT_IEEE_FLOAT)) {
    return Result.error(WavParsingError.invalidFmtSizeForFloat);
  }
  if ((data.lengthInBytes != 40 && wFormatTag == WAVE_FORMAT_EXTENSIBLE)) {
    return Result.error(WavParsingError.invalidFmtSizeForExtensible);
  }

  int numChannels = data.getUint16(2, numEndianess);
  if (numChannels == 0 || numChannels > 1024) {
    return Result.error(WavParsingError.invalidNumChannels);
  }
  int channelMask = 0;
  if (wFormatTag == WAVE_FORMAT_PCM || wFormatTag == WAVE_FORMAT_IEEE_FLOAT) {
    if (numChannels == 1) {
      channelMask = SPEAKER_FRONT_CENTER;
    } else if (numChannels == 2) {
      channelMask = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
    }
  }

  int sampleRate = data.getUint32(4, numEndianess);
  if (sampleRate == 0) {
    return Result.error(WavParsingError.invalidSampleRate);
  }
  int byteRate = data.getUint32(8, numEndianess); // bytes per second
  int blockAlign = data.getUint16(
      12, numEndianess); //total bytes in all channels for a single sample.
  if (blockAlign == 0) {
    return Result.error(WavParsingError.invalidBlockAlign);
  }

  int bitsPerSample = data.getUint16(14, numEndianess);
  int validBitsPerSample = bitsPerSample;
  if (bitsPerSample == 0 || bitsPerSample > 64) {
    return Result.error(WavParsingError.invalidBitsPerSample);
  }
  int bytesPerSample = blockAlign ~/ numChannels;
  int bytesPerSampleUp = (bitsPerSample + 7) ~/ 8;
  if (blockAlign % numChannels != 0 || bytesPerSample != bytesPerSampleUp) {
    return Result.error(WavParsingError.invalidBlockAlign);
  }
  if (byteRate != blockAlign * sampleRate) {
    return Result.error(WavParsingError.invalidByteRate);
  }

  if (data.lengthInBytes >= 18) {
    int ckExtSize = data.getUint16(16, numEndianess); // should be 22 or 0
    if (ckExtSize + 18 != data.lengthInBytes) {
      return Result.error(WavParsingError.invalidExtensionSize);
    }
    if (wFormatTag == WAVE_FORMAT_EXTENSIBLE) {
      validBitsPerSample = data.getUint16(18, numEndianess);
      if (validBitsPerSample > bitsPerSample) {
        return Result.error(WavParsingError.invalidBitsPerSample);
      }
      channelMask = data.getUint32(20, numEndianess);
      var subFormatGUID = data.buffer.asUint8List(data.offsetInBytes + 24, 16);
      if (GUID.equal(subFormatGUID, KSDATAFORMAT_SUBTYPE_PCM)) {
        wFormatTagActual = WAVE_FORMAT_PCM;
      } else if (GUID.equal(subFormatGUID, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT)) {
        wFormatTagActual = WAVE_FORMAT_IEEE_FLOAT;
      } else {
        return Result.error(WavParsingError.unsupportedExtension);
      }
      if (channelMask != 0 && numChannels != countChannelsInMask(channelMask)) {
        return Result.error(WavParsingError.invalidChannelMask);
      }
    }
  }
  if (wFormatTagActual == WAVE_FORMAT_PCM && bitsPerSample > 32) {
    return Result.error(WavParsingError.invalidBitsPerSample);
  }
  if (wFormatTagActual == WAVE_FORMAT_IEEE_FLOAT &&
      (bitsPerSample != 32 && bitsPerSample != 64)) {
    return Result.error(WavParsingError.invalidBitsPerSample);
  }
  FormatType storageType =
      recommendedFormatType(wFormatTagActual, bitsPerSample);
  return Result.ok(WavFormat(numChannels, sampleRate, blockAlign,
      validBitsPerSample, bytesPerSample * 8, storageType,
      channelMask: channelMask));
}

Result<IWavSamplesStorage, WavParsingError> parseDataChunk(
    ByteData data, Endian numEndianess, WavFormat wavFormat) {
  if (data.lengthInBytes == 0 ||
      data.lengthInBytes % wavFormat.blockAlign != 0) {
    return Result.error(WavParsingError.invalidDataChunkSize);
  }
  if (wavFormat.formatType == FormatType.pcm8 &&
      wavFormat.containerBitsPerSample == 8) {
    return Result.ok(
        Uint8Storage.fromBytes(wavFormat.numChannels, data, numEndianess));
  } else if (wavFormat.formatType == FormatType.pcm16 &&
      wavFormat.containerBitsPerSample == 16) {
    return Result.ok(
        Int16Storage.fromBytes(wavFormat.numChannels, data, numEndianess));
  } else if (wavFormat.formatType == FormatType.pcm32 &&
      wavFormat.containerBitsPerSample == 32) {
    return Result.ok(
        Int32Storage.fromBytes32(wavFormat.numChannels, data, numEndianess));
  } else if (wavFormat.formatType == FormatType.pcm24 &&
      wavFormat.containerBitsPerSample == 24) {
    return Result.ok(
        Int32Storage.fromBytes24(wavFormat.numChannels, data, numEndianess));
  } else if (wavFormat.formatType == FormatType.float32 &&
      wavFormat.containerBitsPerSample == 32) {
    return Result.ok(
        Float32Storage.fromBytes(wavFormat.numChannels, data, numEndianess));
  } else if (wavFormat.formatType == FormatType.float64 &&
      wavFormat.containerBitsPerSample == 64) {
    return Result.ok(
        Float64Storage.fromBytes(wavFormat.numChannels, data, numEndianess));
  }
  return Result.error(WavParsingError.unsupportedFormat);
}

Result<ListInfo, WavParsingError> parseListChunk(
    ByteData data, Endian numEndianess) {
  //Notice: We parse the strings as ascii characters, without regard to CSET Chunk
  int listType = data.getUint32(0, Endian.big);
  if (listType != INFO_ID) {
    return Result.error(WavParsingError.unrecognizedListType);
  }
  int i = 4;
  Map<int, String> infoEntries = {};
  for (; i < data.lengthInBytes - 8;) {
    int id = data.getUint32(i, Endian.big);

    int length = data.getUint32(i + 4, numEndianess);
    if (i + 8 + length > data.lengthInBytes) {
      return Result.error(WavParsingError.invalidListInfo);
    }
    i += 8;

    var characters = data.buffer.asUint8List(data.offsetInBytes + i, length);
    try {
      infoEntries[id] = ascii.decode(
          characters.takeWhile((value) => value != 0).toList(growable: false));
    } on FormatException {
      return Result.error(WavParsingError.unrecognizedCharFormat);
    }
    i += roundUp2(length);
  }
  return Result.ok(ListInfo(
      infoEntries[INAM_ID] ?? "",
      infoEntries[IPRD_ID] ?? "",
      infoEntries[IART_ID] ?? "",
      infoEntries[ICRD_ID] ?? "",
      infoEntries[ICMT_ID] ?? "",
      infoEntries[IGNR_ID] ?? "",
      infoEntries[ITRK_ID] ?? ""));
}

/// Construct and write a WAV header into a [ByteData] buffer.
///
/// Under the hood, this sets up the RIFF/RIFX header container structure, the
/// `fmt` subchunk, the `fact` subchunk, and prepends the `data` subchunk header.
ByteData writeWavHeader(
    WavFormat format, StorageType storageType, int numSamples,
    {ListInfo? info, bool extensible = true, bool bigEndian = false}) {
  int dataCkSize = format.blockAlign * numSamples;
  int listCkSize = info?.sizeOnDisk ?? 0;

  const fmtExCkSize = 40;
  const fmtSimpleCkSize = 16;
  int fmtSize = extensible ? fmtExCkSize : fmtSimpleCkSize;
  const factCkSize = 4;
  int ckSize = 4 + (fmtSize + 8) + (factCkSize + 8) + (dataCkSize + 8);
  if (listCkSize > 0) {
    ckSize = roundUp2(ckSize) + listCkSize + 8;
  }
  int headerSize = 20 + fmtSize + 12 + 8;

  var data = ByteData(headerSize);

  Endian numEndianess = bigEndian ? Endian.big : Endian.little;
  data.setUint32(0, bigEndian ? RIFX_ID : RIFF_ID, Endian.big);
  data.setUint32(4, ckSize, numEndianess);
  data.setUint32(8, WAVE_ID, Endian.big);
  data.setUint32(12, fmt_ID, Endian.big);

  data.setUint32(16, fmtSize, numEndianess);
  writeFmt(data.buffer.asByteData(20, fmtSize), extensible, format, storageType,
      numEndianess);
  int position = 20 + fmtSize;
  //write Fact
  {
    data.setUint32(position, fact_ID, Endian.big);
    data.setUint32(position + 4, factCkSize, numEndianess);
    data.setUint32(position + 8, numSamples, numEndianess);
    position += 12;
  }

  {
    // write data chunk header
    data.setUint32(position, data_ID, Endian.big);
    data.setUint32(position + 4, dataCkSize, numEndianess);
    position += 8;
  }

  return data;
}

/// Encodes [wavContent] into WAV format bytes stored in [ByteData].
///
/// [extensible] determines whether the extended `fmt` format should be used.
/// [bigEndian] determines if it should be encoded in big-endian (RIFX) format.
ByteData saveWav(IWavContent wavContent,
    [bool extensible = true, bool bigEndian = false]) {
  int dataCkSize = wavContent.format.blockAlign * wavContent.numSamples;
  int listCkSize = wavContent.info?.sizeOnDisk ?? 0;

  const fmtExCkSize = 40;
  const fmtSimpleCkSize = 16;
  int fmtSize = extensible ? fmtExCkSize : fmtSimpleCkSize;
  const factCkSize = 4;
  int ckSize = 4 + (fmtSize + 8) + (factCkSize + 8) + (dataCkSize + 8);
  if (listCkSize > 0) {
    ckSize = roundUp2(ckSize) + listCkSize + 8;
  }
  int totalFileSize = roundUp2(ckSize) + 8;

  var data = ByteData(totalFileSize);

  // Write header using our new writeWavHeader
  var header = writeWavHeader(
      wavContent.format, wavContent.storageType, wavContent.numSamples,
      info: wavContent.info, extensible: extensible, bigEndian: bigEndian);

  data.buffer
      .asUint8List()
      .setRange(0, header.lengthInBytes, header.buffer.asUint8List());

  Endian numEndianess = bigEndian ? Endian.big : Endian.little;
  int position = header.lengthInBytes;

  // write data content
  wavContent.exportStorageAsBytes(
      data.buffer.asByteData(data.offsetInBytes + position, dataCkSize),
      numEndianess);
  position += roundUp2(dataCkSize);

  // write list info
  if (listCkSize > 0) {
    data.setUint32(position, LIST_ID, Endian.big);
    data.setUint32(position + 4, listCkSize, numEndianess);
    data.setUint32(position + 8, INFO_ID, Endian.big);
    position += 12;
    if (wavContent.info!.writeToChunk(
            data.buffer.asByteData(data.offsetInBytes + position),
            numEndianess) !=
        listCkSize - 4 /*for INFO tag*/) {
      throw UnimplementedError("software bug");
    }
  }

  return data;
}

/// Helper that serializes format metadata parameters into the `fmt` chunk byte data block.
void writeFmt(ByteData data, bool extensible, WavFormat format,
    StorageType storageType, Endian numEndianess) {
  int wFormatTag;
  if (extensible) {
    wFormatTag = WAVE_FORMAT_EXTENSIBLE;
  } else {
    wFormatTag = (storageType == StorageType.float32 ||
            storageType == StorageType.float64)
        ? WAVE_FORMAT_IEEE_FLOAT
        : WAVE_FORMAT_PCM;
  }

  data.setUint16(0, wFormatTag, numEndianess);
  data.setUint16(2, format.numChannels, numEndianess);
  data.setUint32(4, format.sampleRate, numEndianess);
  data.setUint32(8, format.blockAlign * format.sampleRate, numEndianess);
  data.setUint16(12, format.blockAlign, numEndianess);
  data.setUint16(14, format.containerBitsPerSample, numEndianess);
  if (extensible) {
    data.setUint16(16, 22, numEndianess);
    data.setUint16(18, format.validBitsPerSample, numEndianess);
    data.setUint32(20, format.channelMask, numEndianess);
    data.buffer.asUint8List(data.offsetInBytes + 24, 16).setRange(
        0,
        16,
        (storageType == StorageType.float32 ||
                storageType == StorageType.float64)
            ? KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
            : KSDATAFORMAT_SUBTYPE_PCM);
  }
}
