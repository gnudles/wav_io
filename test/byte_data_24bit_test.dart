import 'dart:typed_data';
import 'package:test/test.dart';

// Since ByteData24Bit is an extension on ByteData, we need to import it.
// We'll import wav_io/src/byte_data_24bit.dart to access it.
import 'package:wav_io/src/byte_data_24bit.dart';

void main() {
  group('ByteData24Bit Extension Tests', () {
    test('getInt24 Big Endian', () {
      final buffer = ByteData(12);

      // Test 0
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getInt24(0, Endian.big), 0);

      // Test 1
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x01);
      expect(buffer.getInt24(0, Endian.big), 1);

      // Test -1
      buffer.setUint8(0, 0xFF);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0xFF);
      expect(buffer.getInt24(0, Endian.big), -1);

      // Test Max Positive: 8388607 (0x7FFFFF)
      buffer.setUint8(0, 0x7F);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0xFF);
      expect(buffer.getInt24(0, Endian.big), 8388607);

      // Test Min Negative: -8388608 (0x800000)
      buffer.setUint8(0, 0x80);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getInt24(0, Endian.big), -8388608);

      // Offset test
      buffer.setUint8(3, 0x7F);
      buffer.setUint8(4, 0xFF);
      buffer.setUint8(5, 0xFF);
      expect(buffer.getInt24(3, Endian.big), 8388607);
    });

    test('getInt24 Little Endian', () {
      final buffer = ByteData(12);

      // Test 0
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getInt24(0, Endian.little), 0);

      // Test 1
      buffer.setUint8(0, 0x01);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getInt24(0, Endian.little), 1);

      // Test -1
      buffer.setUint8(0, 0xFF);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0xFF);
      expect(buffer.getInt24(0, Endian.little), -1);

      // Test Max Positive: 8388607 (0x7FFFFF)
      buffer.setUint8(0, 0xFF);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0x7F);
      expect(buffer.getInt24(0, Endian.little), 8388607);

      // Test Min Negative: -8388608 (0x800000)
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x80);
      expect(buffer.getInt24(0, Endian.little), -8388608);

      // Offset test
      buffer.setUint8(3, 0xFF);
      buffer.setUint8(4, 0xFF);
      buffer.setUint8(5, 0x7F);
      expect(buffer.getInt24(3, Endian.little), 8388607);
    });

    test('getUint24 Big Endian', () {
      final buffer = ByteData(12);

      // Test 0
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getUint24(0, Endian.big), 0);

      // Test Max Unsigned: 16777215 (0xFFFFFF)
      buffer.setUint8(0, 0xFF);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0xFF);
      expect(buffer.getUint24(0, Endian.big), 16777215);

      // Mid range
      buffer.setUint8(0, 0x12);
      buffer.setUint8(1, 0x34);
      buffer.setUint8(2, 0x56);
      expect(buffer.getUint24(0, Endian.big), 0x123456);

      // Offset test
      buffer.setUint8(3, 0xFF);
      buffer.setUint8(4, 0xFF);
      buffer.setUint8(5, 0xFF);
      expect(buffer.getUint24(3, Endian.big), 16777215);
    });

    test('getUint24 Little Endian', () {
      final buffer = ByteData(12);

      // Test 0
      buffer.setUint8(0, 0x00);
      buffer.setUint8(1, 0x00);
      buffer.setUint8(2, 0x00);
      expect(buffer.getUint24(0, Endian.little), 0);

      // Test Max Unsigned: 16777215 (0xFFFFFF)
      buffer.setUint8(0, 0xFF);
      buffer.setUint8(1, 0xFF);
      buffer.setUint8(2, 0xFF);
      expect(buffer.getUint24(0, Endian.little), 16777215);

      // Mid range
      buffer.setUint8(0, 0x56);
      buffer.setUint8(1, 0x34);
      buffer.setUint8(2, 0x12);
      expect(buffer.getUint24(0, Endian.little), 0x123456);

      // Offset test
      buffer.setUint8(3, 0xFF);
      buffer.setUint8(4, 0xFF);
      buffer.setUint8(5, 0xFF);
      expect(buffer.getUint24(3, Endian.little), 16777215);
    });

    test('setInt24 Big Endian', () {
      final buffer = ByteData(12);

      buffer.setInt24(0, 0, Endian.big);
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      buffer.setInt24(0, 1, Endian.big);
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x01);

      buffer.setInt24(0, -1, Endian.big);
      expect(buffer.getUint8(0), 0xFF);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0xFF);

      buffer.setInt24(0, 8388607, Endian.big); // Max positive
      expect(buffer.getUint8(0), 0x7F);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0xFF);

      buffer.setInt24(0, -8388608, Endian.big); // Min negative
      expect(buffer.getUint8(0), 0x80);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      // Offset test
      buffer.setInt24(3, 8388607, Endian.big);
      expect(buffer.getUint8(3), 0x7F);
      expect(buffer.getUint8(4), 0xFF);
      expect(buffer.getUint8(5), 0xFF);
    });

    test('setInt24 Little Endian', () {
      final buffer = ByteData(12);

      buffer.setInt24(0, 0, Endian.little);
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      buffer.setInt24(0, 1, Endian.little);
      expect(buffer.getUint8(0), 0x01);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      buffer.setInt24(0, -1, Endian.little);
      expect(buffer.getUint8(0), 0xFF);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0xFF);

      buffer.setInt24(0, 8388607, Endian.little); // Max positive
      expect(buffer.getUint8(0), 0xFF);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0x7F);

      buffer.setInt24(0, -8388608, Endian.little); // Min negative
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x80);

      // Offset test
      buffer.setInt24(3, 8388607, Endian.little);
      expect(buffer.getUint8(3), 0xFF);
      expect(buffer.getUint8(4), 0xFF);
      expect(buffer.getUint8(5), 0x7F);
    });

    test('setUint24 Big Endian', () {
      final buffer = ByteData(12);

      buffer.setUint24(0, 0, Endian.big);
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      buffer.setUint24(0, 16777215, Endian.big); // Max unsigned
      expect(buffer.getUint8(0), 0xFF);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0xFF);

      buffer.setUint24(0, 0x123456, Endian.big); // Mid range
      expect(buffer.getUint8(0), 0x12);
      expect(buffer.getUint8(1), 0x34);
      expect(buffer.getUint8(2), 0x56);

      // Offset test
      buffer.setUint24(3, 16777215, Endian.big);
      expect(buffer.getUint8(3), 0xFF);
      expect(buffer.getUint8(4), 0xFF);
      expect(buffer.getUint8(5), 0xFF);
    });

    test('setUint24 Little Endian', () {
      final buffer = ByteData(12);

      buffer.setUint24(0, 0, Endian.little);
      expect(buffer.getUint8(0), 0x00);
      expect(buffer.getUint8(1), 0x00);
      expect(buffer.getUint8(2), 0x00);

      buffer.setUint24(0, 16777215, Endian.little); // Max unsigned
      expect(buffer.getUint8(0), 0xFF);
      expect(buffer.getUint8(1), 0xFF);
      expect(buffer.getUint8(2), 0xFF);

      buffer.setUint24(0, 0x123456, Endian.little); // Mid range
      expect(buffer.getUint8(0), 0x56);
      expect(buffer.getUint8(1), 0x34);
      expect(buffer.getUint8(2), 0x12);

      // Offset test
      buffer.setUint24(3, 16777215, Endian.little);
      expect(buffer.getUint8(3), 0xFF);
      expect(buffer.getUint8(4), 0xFF);
      expect(buffer.getUint8(5), 0xFF);
    });

    test('Out of bounds and RangeError handling', () {
      final buffer = ByteData(4); // Only indices 0, 1, 2, 3

      // We need to be able to read 3 bytes.
      // Offset 0 reads 0, 1, 2 (Valid)
      // Offset 1 reads 1, 2, 3 (Valid)
      // Offset 2 reads 2, 3, 4 (Invalid, 4 is out of bounds)
      // Offset -1 is invalid

      expect(() => buffer.getInt24(-1), throwsRangeError);
      expect(() => buffer.getInt24(2), throwsRangeError);
      expect(() => buffer.getInt24(3), throwsRangeError);

      expect(() => buffer.getUint24(-1), throwsRangeError);
      expect(() => buffer.getUint24(2), throwsRangeError);
      expect(() => buffer.getUint24(3), throwsRangeError);

      expect(() => buffer.setInt24(-1, 0), throwsRangeError);
      expect(() => buffer.setInt24(2, 0), throwsRangeError);
      expect(() => buffer.setInt24(3, 0), throwsRangeError);

      expect(() => buffer.setUint24(-1, 0), throwsRangeError);
      expect(() => buffer.setUint24(2, 0), throwsRangeError);
      expect(() => buffer.setUint24(3, 0), throwsRangeError);
    });
  });
}
