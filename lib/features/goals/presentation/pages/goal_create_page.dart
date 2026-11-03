import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/goals/presentation/cubit/goal_form_cubit.dart';
import 'package:spendyholik/features/goals/presentation/pages/goal_edit_page.dart';

/// Отдельная страница, а не `GoalEditPage` без id: auto_route требует
/// уникальное имя маршрута на каждый путь.
@RoutePage()
class GoalCreatePage extends StatelessWidget {
  const GoalCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GoalFormCubit>(),
      child: const GoalEditView(),
    );
  }
}
