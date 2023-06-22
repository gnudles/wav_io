enum ResultKind { OK, ERROR }

class Result<V, E> {
  final ResultKind _kind;
  final V? _value;
  final E? _error;
  const Result.ok(this._value) : _kind = ResultKind.OK, _error = null;
  const Result.error(this._error) : _kind = ResultKind.ERROR, _value = null;
  bool get isOk => _kind == ResultKind.OK;
  bool get isError => _kind == ResultKind.ERROR;
  void match(
      {required Function(V value) onOk, required Function(E error) onError}) {
    if (_kind == ResultKind.OK) {
      onOk(_value!);
    } else {
      onError(_error!);
    }
  }

  V unwrap() {
    if (_kind != ResultKind.OK) throw UnsupportedError;
    return _value!;
  }
  E? get error
  {
    if (_kind != ResultKind.ERROR) throw UnsupportedError;
    return _error;
  }

}

class ResultVE<V> {
  //result with void error
  final ResultKind _kind;
  final V? _value;
  const ResultVE.ok(this._value) : _kind = ResultKind.OK;
  const ResultVE.error() : _kind = ResultKind.ERROR, _value = null;
  bool get isOk => _kind == ResultKind.OK;
  bool get isError => _kind == ResultKind.ERROR;
  void match({required Function(V value) onOk, required Function() onError}) {
    if (_kind == ResultKind.OK) {
      onOk(_value!);
    } else {
      onError();
    }
  }

  V unwrap() {
    if (_kind == ResultKind.ERROR) throw UnsupportedError;
    return _value!;
  }
}
