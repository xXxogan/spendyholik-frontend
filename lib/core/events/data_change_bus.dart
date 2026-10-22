import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/events/data_topic.dart';

export 'data_topic.dart';

@lazySingleton
class DataChangeBus {
  final _controller = StreamController<Set<DataTopic>>.broadcast();

  Stream<Set<DataTopic>> get changes => _controller.stream;

  void emit(Set<DataTopic> topics) => _controller.add(topics);

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
