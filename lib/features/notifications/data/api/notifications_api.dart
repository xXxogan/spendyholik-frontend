import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/notifications/data/models/notification_dtos.dart';

part 'notifications_api.g.dart';

@lazySingleton
@RestApi()
abstract class NotificationsApi {
  @factoryMethod
  factory NotificationsApi(Dio dio) = _NotificationsApi;

  @GET('notifications/')
  Future<List<NotificationOutDto>> list();

  @POST('notifications/{id}/read/')
  Future<void> markRead(@Path() String id);
}
