import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendyholik/app/di/injection.dart';
import 'package:spendyholik/core/bloc/cubit_logging.dart';
import 'package:talker_flutter/talker_flutter.dart';

class _Counter extends Cubit<int> with CubitLogging<int> {
  _Counter() : super(0);

  void set(int value) => emit(value);

  void fail(Object error, StackTrace stackTrace) => addError(error, stackTrace);
}

void main() {
  test('emit после close — молча пропускается, состояние прежнее', () async {
    final cubit = _Counter()..set(1);
    await cubit.close();

    expect(() => cubit.set(2), returnsNormally);
    expect(cubit.state, 1);
  });

  test('onError — ошибка со стектрейсом в Talker', () {
    final talker = getIt<Talker>();
    final stackTrace = StackTrace.current;

    _Counter().fail(StateError('boom'), stackTrace);

    final log = talker.history.last;
    expect(log.exception ?? log.error, isA<StateError>());
    expect(log.stackTrace, stackTrace);
  });
}
