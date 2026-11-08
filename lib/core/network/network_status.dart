import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// true — последний запрос дошёл до сервера; false — экран показан из кэша.
@lazySingleton
class NetworkStatus extends Cubit<bool> {
  NetworkStatus() : super(true);

  void reportOffline() => emit(false);

  void reportOnline() => emit(true);
}
