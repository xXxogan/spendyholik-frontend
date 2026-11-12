import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/features/user/presentation/cubit/profile_edit_cubit.dart';
import 'package:spendyholik/features/user/presentation/widgets/profile_form.dart';

import '../../../../helpers/pump_app.dart';

class MockProfileEditCubit extends MockCubit<ProfileEditState>
    implements ProfileEditCubit {}

void main() {
  Future<void> pump(WidgetTester tester, ProfileEditState state) => pumpPage(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: ProfileForm(state: state, cubit: MockProfileEditCubit()),
      ),
    ),
  );

  testWidgets('email прежний — поля текущего пароля нет', (tester) async {
    await pump(
      tester,
      const ProfileEditState(
        email: 'maria@example.com',
        initialEmail: 'maria@example.com',
      ),
    );

    expect(find.text('Текущий пароль'), findsNothing);
  });

  testWidgets('email изменён — поле текущего пароля и его ошибка', (
    tester,
  ) async {
    await pump(
      tester,
      const ProfileEditState(
        email: 'new@example.com',
        initialEmail: 'maria@example.com',
        fieldErrors: {ProfileField.currentPassword: FieldError.required},
      ),
    );

    expect(find.text('Текущий пароль'), findsOneWidget);
    expect(find.text('Обязательное поле'), findsOneWidget);
  });
}
