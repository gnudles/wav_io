import 'dart:io';
import 'dart:math';

import 'package:wav_io/wav_io.dart';
import 'package:test/test.dart';

WavContent loadFile(String filename) {
  var f = File(filename).openSync();
  var buf = f.readSync(f.lengthSync());
  f.closeSync();
  return WavContent.fromBytes(buf.buffer.asByteData());
}

void main() {
  group('wav_io load mono', () {
    var wav = loadFile("test/16bit_mono.wav");

    setUp(() {});

    test('test variables', () {
      expect(wav.numChannels == 1, isTrue);
      expect(wav.bitsPerSample == 16, isTrue);
      expect(wav.sampleRate == 44100, isTrue);
      expect(wav.numSamples == 515, isTrue);
      expect(wav.samplesForChannel.length == 1, isTrue);
      expect(wav.samplesForChannel[0].length == 515, isTrue);
    });
  });
  group('wav_io load stereo float and 24bit pcm', () {
    var wav_float = loadFile("test/float32_stereo.wav");
    var wav_24bit = loadFile("test/24bit_stereo.wav");

    setUp(() {});

    test('test variables float', () {
      expect(wav_float.numChannels == 2, isTrue);
      expect(wav_float.bitsPerSample == 32, isTrue);
      expect(wav_float.sampleRate == 44100, isTrue);
      expect(wav_float.numSamples == 113, isTrue);
      expect(wav_float.samplesForChannel.length == 2, isTrue);

      expect(wav_float.samplesForChannel[0].length == wav_float.numSamples,
          isTrue);
      expect(wav_float.samplesForChannel[1].length == wav_float.numSamples,
          isTrue);
    });
    test('test variables 24bit', () {
      expect(wav_24bit.numChannels == 2, isTrue);
      expect(wav_24bit.bitsPerSample == 24, isTrue);
      expect(wav_24bit.sampleRate == 44100, isTrue);
      expect(wav_24bit.numSamples == 113, isTrue);
      expect(wav_24bit.samplesForChannel.length == 2, isTrue);
      expect(wav_24bit.samplesForChannel[0].length == wav_float.numSamples,
          isTrue);
      expect(wav_24bit.samplesForChannel[1].length == wav_float.numSamples,
          isTrue);
    });
    test('test comparison', () {
      for (int i = 0;
          i < min(wav_24bit.numSamples, wav_float.numSamples);
          ++i) {
        expect(
            wav_float.samplesForChannel[0][i] ==
                wav_24bit.samplesForChannel[0][i],
            isTrue);

        expect(
            wav_float.samplesForChannel[1][i] ==
                wav_24bit.samplesForChannel[1][i] ,
            isTrue);
      }
    });
  });
}
