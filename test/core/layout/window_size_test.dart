import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/layout/window_size.dart';

void main() {
  test('ширина ниже 720 — compact', () {
    expect(WindowSize.fromWidth(0), WindowSize.compact);
    expect(WindowSize.fromWidth(719.9), WindowSize.compact);
  });

  test('от 720 до 1080 — medium', () {
    expect(WindowSize.fromWidth(720), WindowSize.medium);
    expect(WindowSize.fromWidth(1079.9), WindowSize.medium);
  });

  test('от 1080 — expanded', () {
    expect(WindowSize.fromWidth(1080), WindowSize.expanded);
    expect(WindowSize.fromWidth(2560), WindowSize.expanded);
  });
}
