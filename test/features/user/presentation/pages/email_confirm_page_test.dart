import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/user/presentation/cubit/email_confirm_cubit.dart';
import 'package:spendyholik/features/user/presentation/pages/email_confirm_page.dart';

import '../../../../helpers/pump_app.dart';

class MockEmailConfirmCubit extends MockCubit<EmailConfirmState>
    implements EmailConfirmCubit {}

void main() {
  late MockEmailConfirmCubit cubit;

  setUp(() {
    cubit = MockEmailConfirmCubit();
    when(() => cubit.resend()).thenAnswer((_) async {});
    when(() => cubit.signOut()).thenAnswer((_) async {});
    when(() => cubit.submit(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, EmailConfirmState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<EmailConfirmCubit>.value(
        value: cubit,
        child: const EmailConfirmView(),
      ),
      width: 600,
    );
    await tester.pump();
  }

  testWidgets('адрес виден; полный код — submit', (tester) async {
    await pump(tester, const EmailConfirmState(email: 'ivan@example.com'));

    expect(find.textContaining('ivan@example.com'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '482913');
    await tester.pump();

    verify(() => cubit.submit('482913')).called(1);
  });

  testWidgets('ошибка кода — текст под полем', (tester) async {
    await pump(
      tester,
      const EmailConfirmState(codeError: FieldError.codeExpired),
    );

    expect(find.text('Код устарел, запросите новый'), findsOneWidget);
  });

  testWidgets('дневной лимит — сообщение', (tester) async {
    await pump(
      tester,
      const EmailConfirmState(failure: RateLimitedFailure(daily: true)),
    );

    expect(find.text('Слишком много кодов, попробуйте завтра'), findsOneWidget);
  });

  testWidgets('«Отправить снова» и «Выйти»', (tester) async {
    await pump(tester, const EmailConfirmState());

    await tester.tap(find.text('Отправить снова'));
    verify(() => cubit.resend()).called(1);
    await tester.tap(find.text('Выйти'));
    verify(() => cubit.signOut()).called(1);
  });
}
