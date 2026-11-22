import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/features/user/data/repositories/privacy_policy_repository.dart';
import 'package:spendyholik/features/user/presentation/pages/privacy_policy_page.dart';

import '../../../../helpers/pump_app.dart';

class MockPrivacyPolicyRepository extends Mock
    implements PrivacyPolicyRepository {}

void main() {
  testWidgets('на экране политики видны разделы документа', (tester) async {
    final repository = MockPrivacyPolicyRepository();
    when(repository.load).thenAnswer(
      (_) => SynchronousFuture('''
# Пример документа

## 1. Первый раздел

Пример текста.

## 2. Второй раздел
'''),
    );
    getIt.registerSingleton<PrivacyPolicyRepository>(repository);
    addTearDown(() => getIt.unregister<PrivacyPolicyRepository>());
    await pumpPage(tester, const PrivacyPolicyPage());
    await settle(tester);

    expect(find.text('1. Первый раздел'), findsOneWidget);
    expect(find.text('2. Второй раздел'), findsOneWidget);
    expect(find.text('Текст готовится.'), findsNothing);
  });
}
