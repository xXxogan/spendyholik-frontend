import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:spendyholik/features/recurring/presentation/pages/recurring_edit_page.dart';

/// Отдельная страница, а не `RecurringEditPage` без id: auto_route требует
/// уникальное имя маршрута на каждый путь.
@RoutePage()
class RecurringCreatePage extends StatelessWidget {
  const RecurringCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecurringFormCubit>()..start(DateTime.now()),
      child: const RecurringEditView(),
    );
  }
}
