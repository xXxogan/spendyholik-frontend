import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spendyholik/features/user/presentation/cubit/login_cubit.dart';
import 'package:spendyholik/features/user/presentation/pages/login_page.dart';

import '../../../../helpers/pump_app.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

void main() {
  testWidgets('на экране входа есть ссылка «Забыли пароль?»', (tester) async {
    final cubit = MockLoginCubit();
    when(() => cubit.state).thenReturn(const LoginState());
    await pumpPage(
      tester,
      BlocProvider<LoginCubit>.value(value: cubit, child: const LoginView()),
    );
    await tester.pump();

    expect(find.text('Забыли пароль?'), findsOneWidget);
  });
}
