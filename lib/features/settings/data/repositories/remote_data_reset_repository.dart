import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/storage/api_cache.dart';
import 'package:spendyholik/features/settings/data/api/data_reset_api.dart';
import 'package:spendyholik/features/settings/data/repositories/data_reset_repository.dart';

@LazySingleton(as: DataResetRepository)
class RemoteDataResetRepository implements DataResetRepository {
  RemoteDataResetRepository(this._api, this._cache, this._bus);

  final DataResetApi _api;
  final ApiCache _cache;
  final DataChangeBus _bus;

  @override
  Future<void> wipeAll() async {
    await callApi(_api.wipeData);
    // Кэш чистим только после успеха: при ошибке данные на сервере целы.
    await _cache.clear();
    _bus.emit(DataTopic.values.toSet());
  }
}
