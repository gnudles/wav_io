import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:wav_io/wav_io.dart';
import 'package:wav_io/wav_writer.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', mandatory: true)
    ..addOption('samplerate', defaultsTo: '44100')
    ..addOption('duration', defaultsTo: '3')
    ..addOption('freq-start', defaultsTo: '200')
    ..addOption('freq-end', defaultsTo: '800');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException {
    print("Usage: dart example/lib/stream_write.dart -o <output.wav> [--samplerate <sr>] [--duration <sec>] [--freq-start <hz>] [--freq-end <hz>]");
    exit(1);
  }

  final String outputPath = results['output'] as String;
  final int sampleRate = int.tryParse(results['samplerate'] as String) ?? 44100;
  final double duration = double.tryParse(results['duration'] as String) ?? 3.0;
  final double freqStart = double.tryParse(results['freq-start'] as String) ?? 200.0;
  final double freqEnd = double.tryParse(results['freq-end'] as String) ?? 800.0;

  final File testFile = File(outputPath);
  if (testFile.existsSync()) {
    testFile.deleteSync();
  }
  final file = testFile.openSync(mode: FileMode.write);

  // Stream stereo 16-bit PCM (PCM16) audio
  final format = WavFormat(
    2, // numChannels
    sampleRate,
    4, // blockAlign: 2 channels * 2 bytes (16-bit)
    16, // validBitsPerSample
    16, // containerBitsPerSample
    FormatType.pcm16,
    channelMask: SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT,
  );

  final info = ListInfo(
    "Sweep Generator",
    "wav_io Examples",
    "wav_io",
    "2026",
    "Generated via streaming WavWriter",
    "Synth",
    "1",
  );

  final writer = WavWriter(
    file,
    format,
    StorageType.int16,
    info: info,
  );

  final int totalSamples = (sampleRate * duration).round();
  const int chunkSize = 1024;
  int writtenSamples = 0;

  print("Streaming sweep from $freqStart Hz to $freqEnd Hz...");

  while (writtenSamples < totalSamples) {
    final int currentChunkSize = min(chunkSize, totalSamples - writtenSamples);
    final chunk = Int16Storage(currentChunkSize, 2);

    for (int i = 0; i < currentChunkSize; i++) {
      final int sampleIndex = writtenSamples + i;
      final double progress = sampleIndex / totalSamples;
      final double time = sampleIndex / sampleRate;
      final double phase = 2 * pi * time * (freqStart + (freqEnd - freqStart) * progress / 2.0);
      final double sampleVal = sin(phase);

      // Left channel: normal sine sweep
      chunk.samplesData[0][i] = (sampleVal * 16000).round();
      // Right channel: out-of-phase sine sweep
      chunk.samplesData[1][i] = (-sampleVal * 16000).round();
    }

    writer.write(chunk);
    writtenSamples += currentChunkSize;
  }

  writer.close();
  print("Saved sweep to $outputPath");
}
