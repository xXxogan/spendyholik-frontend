import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:spendyholik/features/budgets/presentation/pages/budget_edit_page.dart';

/// Отдельная страница, а не `BudgetEditPage` без id: auto_route требует
/// уникальное имя маршрута на каждый путь.
@RoutePage()
class BudgetCreatePage extends StatelessWidget {
  const BudgetCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetFormCubit>(),
      child: const BudgetEditView(),
    );
  }
}
