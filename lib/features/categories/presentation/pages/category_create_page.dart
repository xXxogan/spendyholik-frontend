import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:spendyholik/features/categories/presentation/pages/category_edit_page.dart';

/// Отдельная страница, а не `CategoryEditPage` без id: auto_route не пускает
/// одну страницу на два пути — имя маршрута должно быть уникальным.
@RoutePage()
class CategoryCreatePage extends StatelessWidget {
  const CategoryCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Создание тоже грузит список: из него берутся варианты родителя.
      create: (_) => getIt<CategoryFormCubit>()..init(null),
      child: const CategoryEditView(),
    );
  }
}
