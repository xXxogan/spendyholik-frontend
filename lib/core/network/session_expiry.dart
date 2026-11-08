import 'dart:async';

import 'package:injectable/injectable.dart';

/// Сигнал «refresh отклонён»: интерсептор не знает о сессии приложения,
/// гасит её репозиторий, который слушает этот поток.
@lazySingleton
class SessionExpiry {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notify() => _expired.add(null);
}
