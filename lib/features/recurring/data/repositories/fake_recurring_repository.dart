import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/events/data_change_bus.dart';
import 'package:spendyholik/fake_backend/fake_backend.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/repositories/recurring_repository.dart';

@LazySingleton(as: RecurringRepository)
class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository(this._backend, this._bus);

  final FakeBackend _backend;
  final DataChangeBus _bus;

  @override
  Future<List<RecurringModel>> getAll() => _backend(() {
    final all = _backend.recurring;
    return [
      ...all.where((r) => !r.isPaused).toList()
        ..sort((a, b) => a.nextDate.compareTo(b.nextDate)),
      ...all.where((r) => r.isPaused),
    ];
  });

  @override
  Future<RecurringModel> create(RecurringDraft draft) async {
    final created = await _backend(() {
      final id = _backend.addRecurring(draft);
      return _backend.recurring.firstWhere((r) => r.id == id);
    });
    _bus.emit({DataTopic.recurring});
    return created;
  }

  @override
  Future<RecurringModel> update(String id, RecurringDraft draft) async {
    final updated = await _backend(() {
      _backend.updateRecurring(id, draft);
      return _backend.recurring.firstWhere((r) => r.id == id);
    });
    _bus.emit({DataTopic.recurring});
    return updated;
  }

  @override
  Future<RecurringModel> setPaused(String id, bool paused) async {
    final updated = await _backend(() {
      _backend.setRecurringPaused(id, paused: paused);
      return _backend.recurring.firstWhere(
        (r) => r.id == id,
        orElse: () => throw const NotFoundFailure(),
      );
    });
    _bus.emit({DataTopic.recurring});
    return updated;
  }
}
