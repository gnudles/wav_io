import 'package:test/test.dart';
import 'package:wav_io/wav_io.dart';

void main() {
  group('Uint8Storage Conversions', () {
    test('Identity and conversion to other types', () {
      final u8 = Uint8Storage(3, 1);
      u8.samplesData[0][0] = 0;   // Maximum negative (-1.0)
      u8.samplesData[0][1] = 128; // Midpoint/Silence (0.0)
      u8.samplesData[0][2] = 255; // Maximum positive (~0.992)

      // Test to Uint8
      final toU8 = u8.convertToUint8();
      expect(toU8.samplesData[0][0], equals(0));
      expect(toU8.samplesData[0][1], equals(128));
      expect(toU8.samplesData[0][2], equals(255));

      // Test to Float32
      final f32 = u8.convertToFloat32();
      expect(f32.samplesData[0][0], closeTo(-1.0, 1e-5));
      expect(f32.samplesData[0][1], closeTo(0.0, 1e-5));
      expect(f32.samplesData[0][2], closeTo(127.0 / 128.0, 1e-5));

      // Test to Float64
      final f64 = u8.convertToFloat64();
      expect(f64.samplesData[0][0], closeTo(-1.0, 1e-9));
      expect(f64.samplesData[0][1], closeTo(0.0, 1e-9));
      expect(f64.samplesData[0][2], closeTo(127.0 / 128.0, 1e-9));

      // Test to Int16
      final i16 = u8.convertToInt16();
      expect(i16.samplesData[0][0], equals(-32768));
      expect(i16.samplesData[0][1], equals(0));
      expect(i16.samplesData[0][2], equals(127 << 8)); // 32512

      // Test to Int32
      final i32 = u8.convertToInt32();
      expect(i32.samplesData[0][0], equals(-2147483648));
      expect(i32.samplesData[0][1], equals(0));
      expect(i32.samplesData[0][2], equals(127 << 24)); // 2130706432
    });

    test('PCM8 -> Float32 -> PCM8 round-trip sanity', () {
      final u8 = Uint8Storage(5, 1);
      u8.samplesData[0].setAll(0, [0, 64, 128, 192, 255]);

      final f32 = u8.convertToFloat32();
      expect(f32.samplesData[0][0], closeTo(-1.0, 1e-5));
      expect(f32.samplesData[0][2], closeTo(0.0, 1e-5));

      final backToU8 = f32.convertToUint8(enableDithering: false);
      expect(backToU8.samplesData[0][0], equals(0));
      expect(backToU8.samplesData[0][1], equals(64));
      expect(backToU8.samplesData[0][2], equals(128));
      expect(backToU8.samplesData[0][3], equals(192));
      expect(backToU8.samplesData[0][4], equals(255));
    });
  });

  group('Int16Storage Conversions', () {
    test('Sanity, overflow check, and no DC offset', () {
      final i16 = Int16Storage(3, 1);
      i16.samplesData[0][0] = -32768;
      i16.samplesData[0][1] = 0;
      i16.samplesData[0][2] = 32767;

      // Test to Float32
      final f32 = i16.convertToFloat32();
      expect(f32.samplesData[0][0], closeTo(-1.0, 1e-5));
      expect(f32.samplesData[0][1], closeTo(0.0, 1e-5));
      expect(f32.samplesData[0][2], closeTo(32767 / 32768, 1e-5));

      // Test to Uint8 without dithering
      final u8 = i16.convertToUint8(enableDithering: false);
      expect(u8.samplesData[0][0], equals(0));
      expect(u8.samplesData[0][1], equals(128)); // No DC offset
      expect(u8.samplesData[0][2], equals(255));

      // Test to Int32
      final i32 = i16.convertToInt32();
      expect(i32.samplesData[0][0], equals(-2147483648));
      expect(i32.samplesData[0][1], equals(0));
      expect(i32.samplesData[0][2], equals(32767 << 16));
    });

    test('Uint8 Conversion with dithering', () {
      final i16 = Int16Storage(100, 1);
      for (int i = 0; i < 100; i++) {
        i16.samplesData[0][i] = 0; // silence
      }
      final u8 = i16.convertToUint8(enableDithering: true);
      // Dithering adds small random noise, so values should be close to 128 (e.g. 127, 128, 129)
      for (int i = 0; i < 100; i++) {
        expect(u8.samplesData[0][i], allOf(greaterThanOrEqualTo(126), lessThanOrEqualTo(130)));
      }
    });
  });

  group('Int32Storage Conversions', () {
    test('Sanity, range limits, clamping and no DC offset', () {
      final i32 = Int32Storage(3, 1);
      i32.samplesData[0][0] = -2147483648;
      i32.samplesData[0][1] = 0;
      i32.samplesData[0][2] = 2147483647;

      // Test to Float32
      final f32 = i32.convertToFloat32();
      expect(f32.samplesData[0][0], closeTo(-1.0, 1e-5));
      expect(f32.samplesData[0][1], closeTo(0.0, 1e-5));
      expect(f32.samplesData[0][2], closeTo(2147483647 / 2147483648, 1e-5));

      // Test to Int16 without dithering
      final i16 = i32.convertToInt16(enableDithering: false);
      expect(i16.samplesData[0][0], equals(-32768));
      expect(i16.samplesData[0][1], equals(0));
      expect(i16.samplesData[0][2], equals(32767));

      // Test to Uint8 without dithering
      final u8 = i32.convertToUint8(enableDithering: false);
      expect(u8.samplesData[0][0], equals(0));
      expect(u8.samplesData[0][1], equals(128));
      expect(u8.samplesData[0][2], equals(255));
    });
  });

  group('Float32Storage Conversions', () {
    test('Clamping, overflow prevention, and no DC offset', () {
      final f32 = Float32Storage(5, 1);
      f32.samplesData[0][0] = 0.0;
      f32.samplesData[0][1] = -1.0;
      f32.samplesData[0][2] = 1.0;
      f32.samplesData[0][3] = -2.5; // Out of bounds negative
      f32.samplesData[0][4] = 3.0;  // Out of bounds positive

      // Test to Int16 without dithering
      final i16 = f32.convertToInt16(enableDithering: false);
      expect(i16.samplesData[0][0], equals(0));          // Zero maps to zero
      expect(i16.samplesData[0][1], equals(-32768));      // -1.0 maps to min
      expect(i16.samplesData[0][2], equals(32767));       // 1.0 maps to max
      expect(i16.samplesData[0][3], equals(-32768));      // Clamped, no wrap-around
      expect(i16.samplesData[0][4], equals(32767));       // Clamped, no wrap-around

      // Test to Uint8 without dithering
      final u8 = f32.convertToUint8(enableDithering: false);
      expect(u8.samplesData[0][0], equals(128));        // Zero maps to midpoint
      expect(u8.samplesData[0][1], equals(0));          // -1.0 maps to 0
      expect(u8.samplesData[0][2], equals(256.round().clamp(0, 255))); // 255
      expect(u8.samplesData[0][3], equals(0));          // Clamped
      expect(u8.samplesData[0][4], equals(255));        // Clamped

      // Test to Int32
      final i32 = f32.convertToInt32();
      expect(i32.samplesData[0][0], equals(0));
      expect(i32.samplesData[0][1], equals(-2147483648));
      expect(i32.samplesData[0][2], equals(2147483647));
      expect(i32.samplesData[0][3], equals(-2147483648));
      expect(i32.samplesData[0][4], equals(2147483647));
    });

    test('Dithering correctness', () {
      final f32 = Float32Storage(100, 1);
      for (int i = 0; i < 100; i++) {
        f32.samplesData[0][i] = 0.5;
      }

      // Convert with dithering
      final i16Dithered = f32.convertToInt16(enableDithering: true);
      // 0.5 * 32768 = 16384. With dithering it should be close to 16384 but vary.
      bool hasVariation = false;
      for (int i = 0; i < 100; i++) {
        expect(i16Dithered.samplesData[0][i], allOf(greaterThan(16384 - 5), lessThan(16384 + 5)));
        if (i16Dithered.samplesData[0][i] != 16384) {
          hasVariation = true;
        }
      }
      expect(hasVariation, isTrue, reason: 'Dithering should introduce random variations');
    });
  });

  group('Float64Storage Conversions', () {
    test('Clamping, overflow prevention, and no DC offset', () {
      final f64 = Float64Storage(5, 1);
      f64.samplesData[0][0] = 0.0;
      f64.samplesData[0][1] = -1.0;
      f64.samplesData[0][2] = 1.0;
      f64.samplesData[0][3] = -5.0; // Out of bounds negative
      f64.samplesData[0][4] = 5.0;  // Out of bounds positive

      // Test to Int16 without dithering
      final i16 = f64.convertToInt16(enableDithering: false);
      expect(i16.samplesData[0][0], equals(0));
      expect(i16.samplesData[0][1], equals(-32768));
      expect(i16.samplesData[0][2], equals(32767));
      expect(i16.samplesData[0][3], equals(-32768));
      expect(i16.samplesData[0][4], equals(32767));

      // Test to Uint8 without dithering
      final u8 = f64.convertToUint8(enableDithering: false);
      expect(u8.samplesData[0][0], equals(128));
      expect(u8.samplesData[0][1], equals(0));
      expect(u8.samplesData[0][2], equals(255));
      expect(u8.samplesData[0][3], equals(0));
      expect(u8.samplesData[0][4], equals(255));

      // Test to Int32
      final i32 = f64.convertToInt32();
      expect(i32.samplesData[0][0], equals(0));
      expect(i32.samplesData[0][1], equals(-2147483648));
      expect(i32.samplesData[0][2], equals(2147483647));
      expect(i32.samplesData[0][3], equals(-2147483648));
      expect(i32.samplesData[0][4], equals(2147483647));
    });
  });

  group('Storage Mixing Tests', () {
    test('Float32 mixTogether with different scales', () {
      final f32_1 = Float32Storage(2, 1);
      f32_1.samplesData[0][0] = 0.2;
      f32_1.samplesData[0][1] = -0.4;

      final f32_2 = Float32Storage(2, 1);
      f32_2.samplesData[0][0] = 0.5;
      f32_2.samplesData[0][1] = 0.8;

      // Mix f32_1 (scale 0.5) and f32_2 (scale 1.0)
      // Result should be:
      // Index 0: 0.2 * 0.5 + 0.5 * 1.0 = 0.1 + 0.5 = 0.6
      // Index 1: -0.4 * 0.5 + 0.8 * 1.0 = -0.2 + 0.8 = 0.6
      final mixingInfo1 = MixingInfo(f32_1, [ChannelMapping(0, 0, 0, 2, 0, 0.5)]);
      final mixingInfo2 = MixingInfo(f32_2, [ChannelMapping(0, 0, 0, 2, 0, 1.0)]);

      final mixed = Float32Storage(2, 1).mixTogether(2, 1, [mixingInfo1, mixingInfo2]) as Float32Storage;
      expect(mixed.samplesData[0][0], closeTo(0.6, 1e-5));
      expect(mixed.samplesData[0][1], closeTo(0.6, 1e-5));
    });

    test('Int16 mixTogether with clamping', () {
      final i16_1 = Int16Storage(2, 1);
      i16_1.samplesData[0][0] = 20000;
      i16_1.samplesData[0][1] = -25000;

      final i16_2 = Int16Storage(2, 1);
      i16_2.samplesData[0][0] = 20000;  // Will sum to 40000 -> clamps to 32767
      i16_2.samplesData[0][1] = -15000; // Will sum to -40000 -> clamps to -32768

      final mixingInfo1 = MixingInfo(i16_1, [ChannelMapping(0, 0, 0, 2, 0, 1.0)]);
      final mixingInfo2 = MixingInfo(i16_2, [ChannelMapping(0, 0, 0, 2, 0, 1.0)]);

      final mixed = Int16Storage(2, 1).mixTogether(2, 1, [mixingInfo1, mixingInfo2]) as Int16Storage;
      expect(mixed.samplesData[0][0], equals(32767));
      expect(mixed.samplesData[0][1], equals(-32768));
    });

    test('Uint8 mixTogether silence and scale', () {
      final u8_1 = Uint8Storage(2, 1);
      u8_1.samplesData[0][0] = 138; // +10 relative to 128
      u8_1.samplesData[0][1] = 118; // -10 relative to 128

      // Mix with scale 0.5
      // Result relative to 128 should be:
      // Index 0: 128 + (+10 * 0.5) = 133
      // Index 1: 128 + (-10 * 0.5) = 123
      final mixingInfo = MixingInfo(u8_1, [ChannelMapping(0, 0, 0, 2, 0, 0.5)]);
      final mixed = Uint8Storage(2, 1).mixTogether(2, 1, [mixingInfo]) as Uint8Storage;

      expect(mixed.samplesData[0][0], equals(133));
      expect(mixed.samplesData[0][1], equals(123));
    });
  });

  group('WavFormat Validation Tests', () {
    test('sampleRate setter behavior and validation', () {
      final format = WavFormat(2, 44100, 4, 16, 16, FormatType.pcm16);
      expect(format.sampleRate, equals(44100));

      // Should allow valid rate update
      format.sampleRate = 48000;
      expect(format.sampleRate, equals(48000));

      // Should throw on invalid rates
      expect(() => format.sampleRate = 0, throwsArgumentError);
      expect(() => format.sampleRate = -1, throwsArgumentError);
    });

    test('channelMask setter validation', () {
      final format = WavFormat(2, 44100, 4, 16, 16, FormatType.pcm16);

      // Stereo format should accept a stereo mask (count = 2)
      format.channelMask = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
      expect(format.channelMask, equals(SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT));

      // Should throw if channel count in mask (1) doesn't match format channel count (2)
      expect(() => format.channelMask = SPEAKER_FRONT_CENTER, throwsArgumentError);
    });

    test('7.1 channel layouts validation', () {
      final format71 = WavFormat(8, 44100, 16, 16, 16, FormatType.pcm16);
      
      // Should accept standard 7.1 channel mask
      format71.channelMask = KSAUDIO_SPEAKER_7POINT1;
      expect(format71.channelMask, equals(KSAUDIO_SPEAKER_7POINT1));

      // Should accept 7.1 surround channel mask
      format71.channelMask = KSAUDIO_SPEAKER_7POINT1_SURROUND;
      expect(format71.channelMask, equals(KSAUDIO_SPEAKER_7POINT1_SURROUND));

      // Should throw if channel count in mask (8) doesn't match format channels (2)
      final formatStereo = WavFormat(2, 44100, 4, 16, 16, FormatType.pcm16);
      expect(() => formatStereo.channelMask = KSAUDIO_SPEAKER_7POINT1, throwsArgumentError);
    });
  });
}
