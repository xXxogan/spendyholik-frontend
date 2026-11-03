import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/features/goals/data/models/goal_model.dart';

GoalModel goal({required int saved, int target = 20000000}) =>
    GoalModel(id: 'g1', name: 'Подушка', target: target, saved: saved);

void main() {
  test('120 000 из 200 000 — 60%, осталось 80 000, не достигнута', () {
    final model = goal(saved: 12000000);

    expect(model.progress, 0.6);
    expect(model.remaining, 8000000);
    expect(model.isReached, isFalse);
  });

  test('накоплено больше цели — прогресс 1, остаток 0, достигнута', () {
    final model = goal(saved: 25000000);

    expect(model.progress, 1);
    expect(model.remaining, 0);
    expect(model.isReached, isTrue);
  });

  test('ровно цель — достигнута', () {
    expect(goal(saved: 20000000).isReached, isTrue);
  });
}
