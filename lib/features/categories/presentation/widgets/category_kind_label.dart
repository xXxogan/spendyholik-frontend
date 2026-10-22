import 'package:spendyholik/features/categories/data/models/models.dart';
import 'package:spendyholik/l10n/l10n.dart';

String categoryKindLabel(AppLocalizations l10n, CategoryKind kind) =>
    switch (kind) {
      CategoryKind.expense => l10n.categoryKindExpense,
      CategoryKind.income => l10n.categoryKindIncome,
      CategoryKind.transfer => l10n.categoryKindTransfer,
    };
