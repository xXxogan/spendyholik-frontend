import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/widgets/glass/app_back_button.dart';

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  late MockStackRouter router;
  const parent = PageRouteInfo<void>('ParentRoute');

  setUpAll(() => registerFallbackValue(<PageRouteInfo>[]));

  setUp(() {
    router = MockStackRouter();
    when(() => router.maybePop<Object?>()).thenAnswer((_) async => true);
    when(() => router.replaceAll(any())).thenAnswer((_) async {});
  });

  test('есть куда вернуться — обычный pop', () async {
    when(() => router.canPop()).thenReturn(true);

    await navigateBack(router, parent);

    verify(() => router.maybePop<Object?>()).called(1);
    verifyNever(() => router.replaceAll(any()));
  });

  test('стек пуст (страница открыта по URL или после обновления) — на логического родителя', () async {
    when(() => router.canPop()).thenReturn(false);

    await navigateBack(router, parent);

    verify(() => router.replaceAll([parent])).called(1);
    verifyNever(() => router.maybePop<Object?>());
  });
}
