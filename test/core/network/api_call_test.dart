import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/api_call.dart';

import '../../helpers/dio_errors.dart';

void main() {
  test('успех — значение как есть', () async {
    expect(await callApi(() async => 42), 42);
  });

  test('DioException — Failure по маппингу, с картой полей', () async {
    await expectLater(
      callApi(
        () async => throw apiError(422, 'validation_error', {'x': 'required'}),
        fields: {'x': 'name'},
      ),
      throwsA(isA<ValidationFailure>().having((f) => f.field, 'field', 'name')),
    );
  });

  test(
    'ответ не того формата (TypeError) — UnknownFailure, а не Error мимо Cubit',
    () async {
      await expectLater(
        callApi<String>(() async => (null as dynamic) as String),
        throwsA(isA<UnknownFailure>()),
      );
    },
  );

  test('FormatException — UnknownFailure', () async {
    await expectLater(
      callApi(() async => throw const FormatException('bad')),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test('Failure изнутри — без обёртки', () async {
    await expectLater(
      callApi(() async => throw const NotFoundFailure()),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
