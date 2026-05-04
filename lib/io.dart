import 'dart:io';
import 'dart:typed_data';

import 'package:wav_io/wav_io.dart';

/// A class to stream/write audio samples to a wav file on disk.
class WavWriter {
  final RandomAccessFile file;
  final WavFormat format;
  final StorageType storageType;
  final bool extensible;
  final bool bigEndian;
  final Endian numEndianess;
  final ListInfo? info;

  int _numSamples = 0;
  bool _isClosed = false;

  WavWriter(
    this.file,
    this.format,
    this.storageType, {
    this.extensible = true,
    this.bigEndian = false,
    this.info,
  }) : numEndianess = bigEndian ? Endian.big : Endian.little {
    _writeHeader();
  }

  /// Write the initial header. The total length will be 0 initially.
  void _writeHeader() {
    file.setPositionSync(0);
    var headerData = writeWavHeader(
      format,
      storageType,
      _numSamples,
      info: info,
      extensible: extensible,
      bigEndian: bigEndian,
    );
    file.writeFromSync(headerData.buffer.asUint8List());
  }

  /// Append audio chunks to the end of the data chunk.
  void write(IWavSamplesStorage chunk) {
    if (_isClosed) {
      throw StateError("WavWriter is already closed");
    }
    if (chunk.channels != format.numChannels) {
      throw ArgumentError("Chunks channels must match the format channels");
    }

    int bytesPerSample = format.containerBitsPerSample ~/ 8;
    int dataCkSize = format.blockAlign * chunk.length;
    var data = ByteData(dataCkSize);

    chunk.writeStorage(data, numEndianess, bytesPerSample);

    file.writeFromSync(data.buffer.asUint8List());
    _numSamples += chunk.length;
  }

  /// Finalize the wav file by rewriting the header with the total length.
  void close() {
    if (_isClosed) return;
    _isClosed = true;

    // Write padding byte if the total data length is odd
    int dataCkSize = format.blockAlign * _numSamples;
    int bytesToPad = roundUp2(dataCkSize) - dataCkSize;
    for (int i = 0; i < bytesToPad; i++) {
      file.writeByteSync(0);
    }

    // Write LIST INFO if any
    int listCkSize = info?.sizeOnDisk ?? 0;
    if (listCkSize > 0) {
      var listInfoData = ByteData(8 + listCkSize);
      listInfoData.setUint32(0, LIST_ID, Endian.big);
      listInfoData.setUint32(4, listCkSize, numEndianess);
      listInfoData.setUint32(8, INFO_ID, Endian.big);
      if (info!.writeToChunk(
            listInfoData.buffer.asByteData(12),
            numEndianess,
          ) !=
          listCkSize - 4) {
        throw UnimplementedError("software bug");
      }
      file.writeFromSync(listInfoData.buffer.asUint8List());
    }

    // The total length of the file may be odd now, round up by adding padding
    // Actually `saveWav` ensures the entire file size is rounded up to an even number, adding padding at the end.
    int ckSize = 4 + (extensible ? 40 : 16) + 8 + 4 + 8 + dataCkSize + 8;
    if (listCkSize > 0) {
      ckSize = roundUp2(ckSize) + listCkSize + 8;
    }
    int totalFileSize = roundUp2(ckSize) + 8;
    int bytesWritten = file.lengthSync();
    while (bytesWritten < totalFileSize) {
      file.writeByteSync(0);
      bytesWritten++;
    }

    _writeHeader();
    file.closeSync();
  }
}
