import 'dart:io';
import 'package:args/args.dart';
import 'package:wav_io/wav_io.dart';

void main(List<String> arguments) {
  final parser = ArgParser();
  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException {
    print("Usage: dart example/lib/info.dart <input.wav>");
    exit(1);
  }

  if (results.rest.isEmpty) {
    print("Usage: dart example/lib/info.dart <input.wav>");
    exit(1);
  }

  final String inputPath = results.rest.first;
  final File file = File(inputPath);
  if (!file.existsSync()) {
    print("Error: File $inputPath does not exist.");
    exit(1);
  }

  final bytes = file.readAsBytesSync();
  final result = loadWav(bytes.buffer.asByteData());

  result.match(
    onOk: (wav) {
      print("=== WAV File Information ===");
      print("File path:       $inputPath");
      print("Channels:        ${wav.numChannels} (${wav.isMono ? 'Mono' : wav.isStereo ? 'Stereo' : 'Multichannel'})");
      print("Sample Rate:     ${wav.sampleRate} Hz");
      print("Bits per Sample: ${wav.bitsPerSample} bit");
      print("Duration:        ${wav.duration.toStringAsFixed(3)} seconds");
      print("Total Samples:   ${wav.numSamples}");
      print("Storage Type:    ${wav.storageType}");
      print("Format Type:     ${wav.format.formatType}");

      final info = wav.info;
      if (info != null) {
        print("\n=== Metadata (LIST INFO) ===");
        if (info.name.isNotEmpty) print("Title:        ${info.name}");
        if (info.artist.isNotEmpty) print("Artist:       ${info.artist}");
        if (info.product.isNotEmpty) print("Album:        ${info.product}");
        if (info.date.isNotEmpty) print("Year/Date:    ${info.date}");
        if (info.genre.isNotEmpty) print("Genre:        ${info.genre}");
        if (info.trackNumber.isNotEmpty) print("Track #:      ${info.trackNumber}");
        if (info.comment.isNotEmpty) print("Comment:      ${info.comment}");
      } else {
        print("\nNo LIST INFO metadata chunk present.");
      }
    },
    onError: (error) {
      print("Error parsing WAV file: $error");
      exit(1);
    },
  );
}
