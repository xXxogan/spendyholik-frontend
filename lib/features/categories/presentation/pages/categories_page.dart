import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/app/router/app_router.gr.dart';
import 'package:spendyholik/core/widgets/widgets.dart';
import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:spendyholik/features/categories/presentation/widgets/widgets.dart';
import 'package:spendyholik/l10n/l10n.dart';

@RoutePage()
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoriesCubit>()..load(),
      child: const CategoriesView(),
    );
  }
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoriesCubit>();
    final state = context.watch<CategoriesCubit>().state;
    final title = context.l10n.categoriesTitle;

    return AppGlassScaffold(
      leading: const AppBackButton(
        fallback: TabsRoute(children: [ProfileRoute()]),
      ),
      title: title,
      largeTitle: true,
      actions: [
        AppGlassIconButton(
          icon: Icons.add,
          tooltip: context.l10n.categoriesAdd,
          onPressed: () => context.router.push(const CategoryCreateRoute()),
        ),
      ],
      body: BaseLayout.slivers(
        largeTitle: title,
        slivers: [
          switch (state) {
            CategoriesLoading() => const SliverToBoxAdapter(
              child: SkeletonList(itemCount: 3, itemHeight: 64),
            ),
            CategoriesLoaded(:final groups) => ContentSliverPadding(
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      children: [
                        for (final MapEntry(key: kind, value: nodes)
                            in groups.entries)
                          Padding(
                            padding: const .only(top: 12),
                            child: CategoryGroup(
                              key: ValueKey(kind),
                              kind: kind,
                              nodes: nodes,
                              initiallyExpanded: kind == CategoryKind.expense,
                              onCategoryTap: (category) => context.router.push(
                                CategoryEditRoute(categoryId: category.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CategoriesError(:final failure) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: FailureView(failure: failure, onRetry: cubit.load),
              ),
            ),
          },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
