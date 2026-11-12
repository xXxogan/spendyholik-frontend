import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/settings/data/models/notification_preferences_dtos.dart';

part 'notification_preferences_api.g.dart';

@lazySingleton
@RestApi()
abstract class NotificationPreferencesApi {
  @factoryMethod
  factory NotificationPreferencesApi(Dio dio) = _NotificationPreferencesApi;

  @GET('profile/')
  Future<NotificationPreferencesDto> get();

  @PATCH('profile/')
  Future<NotificationPreferencesDto> update(
    @Body() NotificationPreferencesDto body,
  );
}
