import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
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
    print("Usage: dart example/lib/reverse.dart -i <input.wav> -o <output.wav>");
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
  final writer = WavWriter(outRaf, reader.format, reader.storageType, info: reader.info);

  final int totalSamples = reader.totalSamples;
  const int chunkSize = 1024;
  int currentPosition = totalSamples;

  print("Reversing $totalSamples samples from $inputPath to $outputPath...");

  while (currentPosition > 0) {
    final int chunkStart = max(0, currentPosition - chunkSize);
    final int samplesToRead = currentPosition - chunkStart;

    // Seek to the start of this block
    reader.seek(chunkStart);

    // Read the chunk
    final chunk = reader.read(samplesToRead);
    if (chunk != null) {
      // Reverse each channel's samples in-place using the native API
      chunk.reverse();
      // Write the reversed chunk
      writer.write(chunk);
    }

    currentPosition = chunkStart;
  }

  reader.close();
  writer.close();

  print("Successfully saved reversed audio file.");
}
