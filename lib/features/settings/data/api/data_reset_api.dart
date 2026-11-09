import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'data_reset_api.g.dart';

@lazySingleton
@RestApi()
abstract class DataResetApi {
  @factoryMethod
  factory DataResetApi(Dio dio) = _DataResetApi;

  @DELETE('profile/data/')
  Future<void> wipeData();
}
