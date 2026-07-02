/// Represents the outcome of an operation: either a success ([ok]) or a failure ([error]).
enum ResultKind {
  /// The operation succeeded.
  ok,

  /// The operation failed.
  error
}

/// A container that holds either a success value [V] or a failure error [E].
///
/// Used to represent the result of operations that can fail, promoting explicit
/// handling of success and error cases without throwing exceptions.
class Result<V, E> {
  final ResultKind _kind;
  final V? _value;
  final E? _error;

  /// Creates a successful [Result] containing [value].
  const Result.ok(V value)
      : _kind = ResultKind.ok,
        _value = value,
        _error = null;

  /// Creates a failed [Result] containing [error].
  const Result.error(E error)
      : _kind = ResultKind.error,
        _error = error,
        _value = null;

  /// Returns `true` if the result is a success.
  bool get isOk => _kind == ResultKind.ok;

  /// Returns `true` if the result is a failure.
  bool get isError => _kind == ResultKind.error;

  /// Invokes [onOk] with the value if the result is a success, or [onError]
  /// with the error if the result is a failure.
  void match(
      {required Function(V value) onOk, required Function(E error) onError}) {
    if (_kind == ResultKind.ok) {
      onOk(_value as V);
    } else {
      onError(_error as E);
    }
  }

  /// Extracts the success value. Throws an [UnsupportedError] if the result
  /// is actually an error.
  V unwrap() {
    if (_kind != ResultKind.ok) throw UnsupportedError("Result is not Ok");
    return _value!;
  }

  /// Extracts the failure error. Throws an [UnsupportedError] if the result
  /// is actually a success.
  E get error {
    if (_kind != ResultKind.error) {
      throw UnsupportedError("Result is not Error");
    }
    return _error!;
  }
}

/// A simplified version of [Result] where the error type is void.
///
/// Contains either a success value of type [V] or represents a generic failure
/// without any additional error payload.
class ResultVE<V> {
  final ResultKind _kind;
  final V? _value;

  /// Creates a successful [ResultVE] containing [value].
  const ResultVE.ok(V value)
      : _kind = ResultKind.ok,
        _value = value;

  /// Creates a failed [ResultVE].
  const ResultVE.error()
      : _kind = ResultKind.error,
        _value = null;

  /// Returns `true` if the result is a success.
  bool get isOk => _kind == ResultKind.ok;

  /// Returns `true` if the result is a failure.
  bool get isError => _kind == ResultKind.error;

  /// Invokes [onOk] with the value if the result is a success, or [onError]
  /// if the result is a failure.
  void match({required Function(V value) onOk, required Function() onError}) {
    if (_kind == ResultKind.ok) {
      onOk(_value as V);
    } else {
      onError();
    }
  }

  /// Extracts the success value. Throws an [UnsupportedError] if the result
  /// is a failure.
  V unwrap() {
    if (_kind == ResultKind.error) throw UnsupportedError("ResultVE is Error");
    return _value!;
  }
}
