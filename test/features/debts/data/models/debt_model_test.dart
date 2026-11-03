import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/features/debts/data/models/debt_model.dart';

DebtModel debt({int remaining = 100, DateTime? dueDate}) => DebtModel(
  id: 'd',
  counterparty: 'Дмитрий',
  direction: DebtDirection.iOwe,
  total: 100,
  remaining: remaining,
  dueDate: dueDate,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  final today = DateTime(2026, 6, 10, 0, 1);

  test('isClosed: остаток 0', () {
    expect(debt(remaining: 0).isClosed, isTrue);
    expect(debt().isClosed, isFalse);
  });

  group('isOverdue', () {
    test('срок вчера — просрочен', () {
      expect(
        debt(dueDate: DateTime(2026, 6, 9, 23, 59)).isOverdue(today),
        isTrue,
      );
    });

    test('срок сегодня, даже 23:59, — не просрочен', () {
      expect(
        debt(dueDate: DateTime(2026, 6, 10, 23, 59)).isOverdue(today),
        isFalse,
      );
    });

    test('без срока — не просрочен', () {
      expect(debt().isOverdue(today), isFalse);
    });

    test('закрытый с прошедшим сроком — не просрочен', () {
      expect(
        debt(remaining: 0, dueDate: DateTime(2026, 1, 1)).isOverdue(today),
        isFalse,
      );
    });
  });
}
