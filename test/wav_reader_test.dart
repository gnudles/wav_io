import 'dart:io';

import 'package:test/test.dart';
import 'package:wav_io/wav_reader.dart';
import 'package:wav_io/wav_io.dart';

void main() {
  group('WavReader', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('wav_reader_test');
      testFile = File('${tempDir.path}/test_input.wav');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('reads mono 16-bit PCM file chunk-by-chunk and seeks', () {
      // 1. Generate a WAV file with known samples
      final int sampleRate = 44100;
      final int numSamples = 10;
      final storage = Int16Storage(numSamples, 1);
      for (int i = 0; i < numSamples; i++) {
        storage.samplesData[0][i] = i * 1000;
      }

      final format = WavFormat(
        1, sampleRate, 2, 16, 16, FormatType.pcm16,
        channelMask: SPEAKER_FRONT_CENTER,
      );
      final info = ListInfo("Reader Test", "Product", "Artist", "2026", "Comment", "Genre", "1");
      final content = WavContent<Int16Storage>(format, StorageType.int16, storage, info: info);
      testFile.writeAsBytesSync(saveWav(content).buffer.asUint8List());

      // 2. Open WavReader
      final file = testFile.openSync(mode: FileMode.read);
      final reader = WavReader(file);

      expect(reader.format.numChannels, equals(1));
      expect(reader.format.sampleRate, equals(44100));
      expect(reader.storageType, equals(StorageType.int16));
      expect(reader.totalSamples, equals(numSamples));
      expect(reader.info?.name, equals("Reader Test"));

      // 3. Read first chunk (size 4)
      final chunk1 = reader.read(4) as Int16Storage?;
      expect(chunk1, isNotNull);
      expect(chunk1!.length, equals(4));
      expect(chunk1.samplesData[0], equals([0, 1000, 2000, 3000]));
      expect(reader.currentSample, equals(4));

      // 4. Read second chunk (size 4)
      final chunk2 = reader.read(4) as Int16Storage?;
      expect(chunk2, isNotNull);
      expect(chunk2!.length, equals(4));
      expect(chunk2.samplesData[0], equals([4000, 5000, 6000, 7000]));
      expect(reader.currentSample, equals(8));

      // 5. Read remaining (request 4, only 2 left)
      final chunk3 = reader.read(4) as Int16Storage?;
      expect(chunk3, isNotNull);
      expect(chunk3!.length, equals(2));
      expect(chunk3.samplesData[0], equals([8000, 9000]));
      expect(reader.currentSample, equals(10));

      // 6. Read at EOF
      final chunkEOF = reader.read(4);
      expect(chunkEOF, isNull);

      // 7. Seek back and read again
      reader.seek(2);
      expect(reader.currentSample, equals(2));
      final chunkSeek = reader.read(3) as Int16Storage?;
      expect(chunkSeek, isNotNull);
      expect(chunkSeek!.length, equals(3));
      expect(chunkSeek.samplesData[0], equals([2000, 3000, 4000]));

      reader.close();
      expect(reader.isClosed, isTrue);
    });

    test('reads float32 stereo WAV file', () {
      final int sampleRate = 48000;
      final int numSamples = 4;
      final storage = Float32Storage(numSamples, 2);
      storage.samplesData[0].setAll(0, [0.0, 0.5, -0.5, 1.0]);
      storage.samplesData[1].setAll(0, [0.0, -0.2, 0.2, -1.0]);

      final format = WavFormat(
        2, sampleRate, 8, 32, 32, FormatType.float32,
        channelMask: SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT,
      );
      final content = WavContent<Float32Storage>(format, StorageType.float32, storage);
      testFile.writeAsBytesSync(saveWav(content).buffer.asUint8List());

      final file = testFile.openSync(mode: FileMode.read);
      final reader = WavReader(file);

      expect(reader.format.numChannels, equals(2));
      expect(reader.storageType, equals(StorageType.float32));
      expect(reader.totalSamples, equals(numSamples));

      final chunk = reader.read(4) as Float32Storage?;
      expect(chunk, isNotNull);
      expect(chunk!.length, equals(4));
      expect(chunk.samplesData[0][1], closeTo(0.5, 1e-5));
      expect(chunk.samplesData[1][3], closeTo(-1.0, 1e-5));

      reader.close();
    });

    test('throws StateError when reading/seeking after close', () {
      final int sampleRate = 44100;
      final storage = Int16Storage(5, 1);
      final format = WavFormat(1, sampleRate, 2, 16, 16, FormatType.pcm16);
      final content = WavContent<Int16Storage>(format, StorageType.int16, storage);
      testFile.writeAsBytesSync(saveWav(content).buffer.asUint8List());

      final file = testFile.openSync(mode: FileMode.read);
      final reader = WavReader(file);
      reader.close();

      expect(() => reader.read(2), throwsStateError);
      expect(() => reader.seek(0), throwsStateError);
    });
  });
}
