import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:spendyholik/features/transactions/presentation/pages/transaction_edit_page.dart';

/// Отдельная страница, а не `TransactionEditPage` без id: auto_route не пускает
/// одну страницу на два пути — имя маршрута должно быть уникальным.
@RoutePage()
class TransactionCreatePage extends StatelessWidget {
  const TransactionCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionFormCubit>()..init(null),
      child: const TransactionEditView(),
    );
  }
}
