import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:wav_io/wav_io.dart';
import 'package:wav_io/wav_reader.dart';
import 'package:wav_io/wav_writer.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', mandatory: true)
    ..addOption('output', abbr: 'o', mandatory: true);

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException {
    print("Usage: dart example/lib/merge_mono.dart -i <input.wav> -o <output.wav>");
    exit(1);
  }

  final String inputPath = results['input'] as String;
  final String outputPath = results['output'] as String;

  final File inFile = File(inputPath);
  if (!inFile.existsSync()) {
    print("Error: Input file $inputPath does not exist.");
    exit(1);
  }

  final File outFile = File(outputPath);
  if (outFile.existsSync()) {
    outFile.deleteSync();
  }

  final inRaf = inFile.openSync(mode: FileMode.read);
  final outRaf = outFile.openSync(mode: FileMode.write);

  final reader = WavReader(inRaf);

  final int inputChannels = reader.format.numChannels;
  if (inputChannels == 1) {
    print("Warning: Input file is already mono (1 channel).");
  }

  // Create mono output format with 1 channel and KSAUDIO_SPEAKER_MONO mask (SPEAKER_FRONT_CENTER)
  final outputFormat = WavFormat(
    1, // numChannels
    reader.format.sampleRate,
    reader.format.containerBitsPerSample ~/ 8, // blockAlign: 1 channel * bytes per sample container
    reader.format.validBitsPerSample,
    reader.format.containerBitsPerSample,
    reader.format.formatType,
    channelMask: SPEAKER_FRONT_CENTER,
  );

  final writer = WavWriter(
    outRaf,
    outputFormat,
    reader.storageType,
    info: reader.info,
  );

  final int totalSamples = reader.totalSamples;
  const int chunkSize = 1024;
  int processedSamples = 0;

  // Pre-allocate the channel mappings since they remain the same across chunks.
  final mappings = List.generate(
    inputChannels,
    (c) => ChannelMapping(
      c, // fromChannel: source channel
      0, // toChannel: target mono channel
      0, // offsetSource: start of block
      chunkSize, // length: will be adjusted per chunk
      0, // offsetOutput: start of block
      1.0, // scale: add the channels up without division/average
    ),
  );

  print("Merging $totalSamples samples from $inputPath ($inputChannels channels) to $outputPath (mono)...");

  while (processedSamples < totalSamples) {
    final int samplesToRead = min(chunkSize, totalSamples - processedSamples);
    final chunk = reader.read(samplesToRead);
    if (chunk == null) break;

    final int currentChunkSize = chunk.length;
    final bool isF64 = reader.storageType == StorageType.float64;

    // Update the length for this block mapping
    for (final mapping in mappings) {
      mapping.length = currentChunkSize;
    }

    late final IWavSamplesStorage mixedMonoChunk;

    if (isF64) {
      // For Float64 format, perform mixing in Float64Storage
      final inputF64 = chunk.convertToFloat64();
      final mixResult = inputF64.mixTogether(
        currentChunkSize,
        1,
        [MixingInfo(inputF64, mappings)],
      );
      mixedMonoChunk = mixResult;
    } else {
      // For all other formats, perform mixing in Float32Storage
      final inputF32 = chunk.convertToFloat32();
      final mixResult = inputF32.mixTogether(
        currentChunkSize,
        1,
        [MixingInfo(inputF32, mappings)],
      );

      // Convert the mixed Float32 result back to the original reader storage type for writing
      switch (reader.storageType) {
        case StorageType.uint8:
          mixedMonoChunk = mixResult.convertToUint8();
          break;
        case StorageType.int16:
          mixedMonoChunk = mixResult.convertToInt16();
          break;
        case StorageType.int32:
          mixedMonoChunk = mixResult.convertToInt32();
          break;
        case StorageType.float32:
          mixedMonoChunk = mixResult.convertToFloat32();
          break;
        default:
          throw StateError("Unsupported storage type: ${reader.storageType}");
      }
    }

    writer.write(mixedMonoChunk);
    processedSamples += currentChunkSize;
  }

  reader.close();
  writer.close();

  print("Successfully merged and saved mono audio file.");
}
