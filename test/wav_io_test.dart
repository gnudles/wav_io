import 'dart:io';

import 'package:wav_io/wav_io.dart';
import 'package:test/test.dart';

IWavContent loadFile(String filename) {
  var buf = File(filename).readAsBytesSync();
  return loadWav(buf.buffer.asByteData()).unwrap();
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
    });
  });
  group('wav_io load stereo float and 24bit pcm', () {
    var wavFloat = loadFile("test/float32_stereo.wav") as WavContent<Float32Storage>;
    var wav24bit = loadFile("test/24bit_stereo.wav") as WavContent<Int32Storage>;

    setUp(() {});

    test('test variables float', () {
      expect(wavFloat.numChannels == 2, isTrue);
      expect(wavFloat.bitsPerSample == 32, isTrue);
      expect(wavFloat.sampleRate == 44100, isTrue);
      expect(wavFloat.numSamples == 113, isTrue);
    });
    test('test variables 24bit', () {
      expect(wav24bit.numChannels == 2, isTrue);
      expect(wav24bit.bitsPerSample == 24, isTrue);
      expect(wav24bit.sampleRate == 44100, isTrue);
      expect(wav24bit.numSamples == 113, isTrue);
    });
    
  });
}
