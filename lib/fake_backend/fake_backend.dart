import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/fake_backend/seed.dart';
import 'package:spendyholik/features/accounts/accounts.dart';

/// «Сервер» фазы 1: данные в памяти до перезапуска. В фазе 2 удаляется
/// вместе с фейковыми репозиториями.
@lazySingleton
class FakeBackend {
  final List<AccountModel> accounts = FakeSeed.accounts();

  Future<T> call<T>(T Function() handler) async {
    await Future<void>.delayed(AppConfig.fakeLatency);
    return handler();
  }
}
