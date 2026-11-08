import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/recurring/data/models/recurring_dtos.dart';

part 'recurring_api.g.dart';

@lazySingleton
@RestApi()
abstract class RecurringApi {
  @factoryMethod
  factory RecurringApi(Dio dio) = _RecurringApi;

  @GET('recurring/')
  Future<List<RecurringOutDto>> list();

  @POST('recurring/')
  Future<RecurringOutDto> create(@Body() RecurringCreateBody body);

  @PATCH('recurring/{id}/')
  Future<RecurringOutDto> update(
    @Path() String id,
    @Body() RecurringPatchBody body,
  );

  @POST('recurring/{id}/toggle/')
  Future<RecurringOutDto> toggle(
    @Path() String id,
    @Body() RecurringToggleBody body,
  );
}
