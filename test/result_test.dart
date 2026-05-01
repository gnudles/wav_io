import 'package:test/test.dart';
import 'package:wav_io/src/result.dart';

void main() {
  group('Result', () {
    test('Result.ok', () {
      final result = Result<int, String>.ok(42);
      expect(result.isOk, isTrue);
      expect(result.isError, isFalse);
      expect(result.unwrap(), 42);
      expect(() => result.error, throwsA(isA<UnsupportedError>()));

      int? matchedValue;
      result.match(
        onOk: (v) => matchedValue = v,
        onError: (e) => matchedValue = -1,
      );
      expect(matchedValue, 42);
    });

    test('Result.error', () {
      final result = Result<int, String>.error('error');
      expect(result.isOk, isFalse);
      expect(result.isError, isTrue);
      expect(result.error, 'error');
      expect(() => result.unwrap(), throwsA(isA<UnsupportedError>()));

      String? matchedError;
      result.match(
        onOk: (v) => matchedError = 'ok',
        onError: (e) => matchedError = e,
      );
      expect(matchedError, 'error');
    });
  });

  group('ResultVE', () {
    test('ResultVE.ok', () {
      final result = ResultVE<int>.ok(42);
      expect(result.isOk, isTrue);
      expect(result.isError, isFalse);
      expect(result.unwrap(), 42);

      int? matchedValue;
      result.match(
        onOk: (v) => matchedValue = v,
        onError: () => matchedValue = -1,
      );
      expect(matchedValue, 42);
    });

    test('ResultVE.error', () {
      final result = ResultVE<int>.error();
      expect(result.isOk, isFalse);
      expect(result.isError, isTrue);
      expect(() => result.unwrap(), throwsA(isA<UnsupportedError>()));

      bool errorMatched = false;
      result.match(
        onOk: (v) => errorMatched = false,
        onError: () => errorMatched = true,
      );
      expect(errorMatched, isTrue);
    });
  });
}
