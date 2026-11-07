import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';

enum BudgetsTab { budgets, goals }

/// Выбранный сегмент вкладки: его видят и вкладка, и общая шапка `TabsPage`,
/// у которой «+» ведёт на новый бюджет или новую цель.
@lazySingleton
class BudgetsTabCubit extends Cubit<BudgetsTab> with CubitLogging<BudgetsTab> {
  BudgetsTabCubit() : super(BudgetsTab.budgets);

  void select(BudgetsTab tab) => emit(tab);
}
