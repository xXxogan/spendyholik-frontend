import 'package:injectable/injectable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/features/budgets/presentation/widgets/budgets_segment.dart';

/// Выбранный сегмент вкладки: его видят и вкладка, и общая шапка `TabsPage`,
/// у которой «+» ведёт на новый бюджет или новую цель.
@lazySingleton
class BudgetsTabNotifier extends ValueNotifier<BudgetsTab> {
  BudgetsTabNotifier() : super(BudgetsTab.budgets);
}
