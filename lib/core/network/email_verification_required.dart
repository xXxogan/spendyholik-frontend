import 'dart:async';

import 'package:injectable/injectable.dart';

/// Сигнал «сервер закрыт до подтверждения почты» (403 `email_not_verified`):
/// интерсептор не знает о сессии — профиль перечитывает AuthRepository.
@lazySingleton
class EmailVerificationRequired {
  final _required = StreamController<void>.broadcast();

  Stream<void> get required => _required.stream;

  void notify() => _required.add(null);
}
