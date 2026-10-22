import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:spendyholik/features/accounts/presentation/pages/account_edit_page.dart';

/// Отдельная страница, а не `AccountEditPage` без id: auto_route не пускает
/// одну страницу на два пути — имя маршрута должно быть уникальным.
@RoutePage()
class AccountCreatePage extends StatelessWidget {
  const AccountCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountFormCubit>(),
      child: const AccountEditView(),
    );
  }
}
