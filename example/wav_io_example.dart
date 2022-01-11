import 'dart:io';

import 'package:wav_io/wav_io.dart';

void main() {
  var f = File("example/hello_float.wav").openSync();
  var buf = f.readSync(f.lengthSync());
  f.closeSync();
  var wav = WavContent.fromBytes(buf.buffer.asByteData());

  print(wav.numChannels);
  print(wav.numSamples);
  print(wav.sampleRate);
  print(wav.bitsPerSample);
  f = File("example/hello2.wav").openSync(mode: FileMode.writeOnly);
  f.writeFromSync(wav.toBytes().buffer.asInt8List());
  f.flushSync();
  f.closeSync();
}

