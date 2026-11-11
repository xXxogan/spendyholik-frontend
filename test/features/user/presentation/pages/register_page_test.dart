import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/user/presentation/cubit/register_cubit.dart';
import 'package:spendyholik/features/user/presentation/pages/register_page.dart';

import '../../../../helpers/pump_app.dart';

class MockRegisterCubit extends MockCubit<RegisterState>
    implements RegisterCubit {}

void main() {
  late MockRegisterCubit cubit;

  setUp(() => cubit = MockRegisterCubit());

  Future<void> pump(WidgetTester tester, RegisterState state) async {
    when(() => cubit.state).thenReturn(state);
    await pumpPage(
      tester,
      BlocProvider<RegisterCubit>.value(
        value: cubit,
        child: const RegisterView(),
      ),
      width: 600,
    );
    await tester.pump();
  }

  testWidgets('галочка согласия не отмечена; нажатие — consentChanged(true)', (
    tester,
  ) async {
    await pump(tester, const RegisterState());

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
    expect(find.textContaining('персональных данных'), findsWidgets);

    await tester.tap(find.byType(Checkbox));
    verify(() => cubit.consentChanged(true)).called(1);
  });

  testWidgets('без согласия — ошибка у галочки', (tester) async {
    await pump(
      tester,
      const RegisterState(
        fieldErrors: {RegisterField.consent: FieldError.required},
      ),
    );

    expect(find.text('Обязательное поле'), findsOneWidget);
  });
}
