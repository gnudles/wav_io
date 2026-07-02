import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:wav_io/wav_io.dart';

/// A [WavHeaderInput] implementation wrapping a [RandomAccessFile].
class RandomAccessFileHeaderInput implements WavHeaderInput {
  final RandomAccessFile file;
  RandomAccessFileHeaderInput(this.file);

  @override
  int getUint32(int offset, Endian endian) {
    file.setPositionSync(offset);
    final bytes = file.readSync(4);
    if (bytes.length < 4) {
      throw const FormatException("Header ended prematurely");
    }
    return ByteData.sublistView(bytes).getUint32(0, endian);
  }

  @override
  ByteData getByteData(int offset, int length) {
    file.setPositionSync(offset);
    final bytes = file.readSync(length);
    if (bytes.length < length) {
      throw const FormatException("Header ended prematurely");
    }
    return ByteData.sublistView(bytes);
  }

  @override
  int get length => file.lengthSync();
}

/// A class to stream/read audio samples from a WAV file on disk.
///
/// Permits seeking and reading audio blocks on-the-fly to keep memory usage low.
class WavReader {
  /// The underlying binary file.
  final RandomAccessFile file;

  /// The WAV format details parsed from the file header.
  late final WavFormat format;

  /// The memory storage container type suitable for these samples.
  late final StorageType storageType;

  /// Endianness format of numeric values in the file.
  late final Endian numEndianness;

  /// Metadata information retrieved from the LIST INFO chunk, if present.
  late final ListInfo? info;

  /// Total number of audio sample frames per channel.
  late final int totalSamples;

  // Starting byte offset of the audio sample data in the file
  late final int _dataStartOffset;

  // Current sample index position in the file
  int _currentSample = 0;
  bool _isClosed = false;

  /// Gets the current sample frame index location of the reader.
  int get currentSample => _currentSample;

  /// Returns `true` if the reader is closed.
  bool get isClosed => _isClosed;

  /// Creates a new [WavReader] instance from [file], automatically parsing the header.
  WavReader(this.file) {
    _readHeader();
  }

  /// Parses the WAV header structure from the beginning of the file.
  void _readHeader() {
    final input = RandomAccessFileHeaderInput(file);
    final result = parseWavHeader(input);
    if (result.isError) {
      throw FormatException("Invalid WAV file: ${result.error}");
    }
    final header = result.unwrap();

    format = header.format;
    info = header.info;
    numEndianness = header.numEndianness;
    _dataStartOffset = header.dataOffset;
    totalSamples = header.dataSize ~/ format.blockAlign;

    const formatToStorageConversion = [
      StorageType.uint8,
      StorageType.int16,
      StorageType.int32,
      StorageType.int32,
      StorageType.float32,
      StorageType.float64
    ];
    storageType = formatToStorageConversion[format.formatType.index];

    file.setPositionSync(_dataStartOffset);
  }

  /// Seeks to the specified [sampleIndex] position frame in the file.
  void seek(int sampleIndex) {
    if (_isClosed) throw StateError("WavReader is closed");
    if (sampleIndex < 0 || sampleIndex > totalSamples) {
      throw RangeError.range(sampleIndex, 0, totalSamples, "sampleIndex");
    }
    _currentSample = sampleIndex;
    file.setPositionSync(_dataStartOffset + sampleIndex * format.blockAlign);
  }

  /// Reads up to [numSamples] next audio sample frames from the WAV file.
  ///
  /// Returns an [IWavSamplesStorage] containing the read samples, or `null` if EOF is reached.
  IWavSamplesStorage? read(int numSamples) {
    if (_isClosed) throw StateError("WavReader is closed");
    if (_currentSample >= totalSamples) return null;

    final int samplesToRead = min(numSamples, totalSamples - _currentSample);
    if (samplesToRead <= 0) return null;

    final int bytesToRead = samplesToRead * format.blockAlign;
    final bytes = file.readSync(bytesToRead);
    if (bytes.isEmpty) return null;

    final int actualSamplesRead = bytes.length ~/ format.blockAlign;
    if (actualSamplesRead == 0) return null;

    final ByteData chunkData = ByteData.sublistView(bytes);
    late final IWavSamplesStorage storage;

    switch (storageType) {
      case StorageType.uint8:
        storage = Uint8Storage.fromBytes(format.numChannels, chunkData, numEndianness);
        break;
      case StorageType.int16:
        storage = Int16Storage.fromBytes(format.numChannels, chunkData, numEndianness);
        break;
      case StorageType.int32:
        if (format.containerBitsPerSample == 24) {
          storage = Int32Storage.fromBytes24(format.numChannels, chunkData, numEndianness);
        } else {
          storage = Int32Storage.fromBytes32(format.numChannels, chunkData, numEndianness);
        }
        break;
      case StorageType.float32:
        storage = Float32Storage.fromBytes(format.numChannels, chunkData, numEndianness);
        break;
      case StorageType.float64:
        storage = Float64Storage.fromBytes(format.numChannels, chunkData, numEndianness);
        break;
    }

    _currentSample += actualSamplesRead;
    return storage;
  }

  /// Closes the reader and the underlying file resources.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    file.closeSync();
  }
}
