import 'dart:io';
import 'package:args/args.dart';

import 'package:wav_io/wav_io.dart';

int main(List<String> arguments) {
  final parser = ArgParser()..addOption('output', abbr: 'o', mandatory: true);
  ArgResults parsingResults;
  try {
    parsingResults = parser.parse(arguments);
  } on FormatException {
    print(
        "no output supplied. usage: concat [in1.wav] [in2.wav] .. -o output.wav");
    return -1;
  }
  Iterable<Result<IWavContent, WavParsingError>> waves = parsingResults.rest
      .map((e) => loadWav(File(e).readAsBytesSync().buffer.asByteData()));
  if (!waves.every((e) => e.isOk)) {
    print("error reading one of the input files");
    print(waves.map((e) => e.error));
    return -1;
  }
  var combined = waves.map((e) {
    var wav = e.unwrap();
    wav = (wav.isMono ? wav.monoToStereo() : wav);
    return (wav is WavContent<Float32Storage>) ? wav : wav.toFloat32();
  }).reduce(
      (value, element) => value.append(element) as WavContent<Float32Storage>);

  File(parsingResults['output'])
      .writeAsBytesSync(saveWav(combined).buffer.asUint8List());
  return 0;
}
