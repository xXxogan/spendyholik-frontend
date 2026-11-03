import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:spendyholik/features/debts/presentation/pages/debt_edit_page.dart';

/// Отдельная страница, а не `DebtEditPage` без id: auto_route требует
/// уникальное имя маршрута на каждый путь.
@RoutePage()
class DebtCreatePage extends StatelessWidget {
  const DebtCreatePage({super.key, this.initialDirection = DebtDirection.iOwe});

  /// Полное имя в умолчании: auto_route не разбирает dot shorthand.
  /// Параметр конструктора, не путь: после обновления Web будет iOwe.
  final DebtDirection initialDirection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DebtFormCubit>()..start(initialDirection),
      child: const DebtEditView(),
    );
  }
}
