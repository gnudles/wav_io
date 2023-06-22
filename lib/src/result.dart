enum ResultKind { ok, error }

class Result<V, E> {
  final ResultKind _kind;
  final V? _value;
  final E? _error;
  const Result.ok(this._value) : _kind = ResultKind.ok, _error = null;
  const Result.error(this._error) : _kind = ResultKind.error, _value = null;
  bool get isOk => _kind == ResultKind.ok;
  bool get isError => _kind == ResultKind.error;
  void match(
      {required Function(V value) onOk, required Function(E error) onError}) {
    if (_kind == ResultKind.ok) {
      onOk(_value as V);
    } else {
      onError(_error as E);
    }
  }

  V unwrap() {
    if (_kind != ResultKind.ok) throw UnsupportedError;
    return _value!;
  }
  E? get error
  {
    if (_kind != ResultKind.error) throw UnsupportedError;
    return _error;
  }

}

class ResultVE<V> {
  //result with void error
  final ResultKind _kind;
  final V? _value;
  const ResultVE.ok(this._value) : _kind = ResultKind.ok;
  const ResultVE.error() : _kind = ResultKind.error, _value = null;
  bool get isOk => _kind == ResultKind.ok;
  bool get isError => _kind == ResultKind.error;
  void match({required Function(V value) onOk, required Function() onError}) {
    if (_kind == ResultKind.ok) {
      onOk(_value as V);
    } else {
      onError();
    }
  }

  V unwrap() {
    if (_kind == ResultKind.error) throw UnsupportedError;
    return _value!;
  }
}
