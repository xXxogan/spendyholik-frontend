import 'package:spendyholik/features/recurring/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class RecurringRepository {
  /// Активные по `nextDate`, затем приостановленные.
  Future<List<RecurringModel>> getAll();

  Future<RecurringModel> create(RecurringDraft draft);

  Future<RecurringModel> update(String id, RecurringDraft draft);

  Future<RecurringModel> setPaused(String id, bool paused);
}
