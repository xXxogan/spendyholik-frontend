import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/features/analytics/data/models/models.dart';

/// Все методы бросают только [Failure] из `core/errors`.
abstract interface class AnalyticsRepository {
  /// [preset] — week, month или year; период — текущий на [anchor] (по умолчанию сейчас).
  Future<AnalyticsReport> getReport(PeriodPreset preset, {DateTime? anchor});
}
