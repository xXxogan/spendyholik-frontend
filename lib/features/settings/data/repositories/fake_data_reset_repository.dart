import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/settings/data/repositories/data_reset_repository.dart';

@LazySingleton(as: DataResetRepository)
class FakeDataResetRepository implements DataResetRepository {
  FakeDataResetRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<void> wipeAll() async {
    await _backend(_backend.wipeAll);
    _bus.emit(DataTopic.values.toSet());
  }
}
