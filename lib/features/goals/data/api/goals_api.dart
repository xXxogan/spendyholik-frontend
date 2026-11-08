import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/goals/data/models/goal_dtos.dart';

part 'goals_api.g.dart';

@lazySingleton
@RestApi()
abstract class GoalsApi {
  @factoryMethod
  factory GoalsApi(Dio dio) = _GoalsApi;

  @GET('goals/')
  Future<List<GoalOutDto>> list();

  @GET('goals/{id}/')
  Future<GoalOutDto> get(@Path() String id);

  @POST('goals/')
  Future<GoalOutDto> create(@Body() GoalCreateBody body);

  @PATCH('goals/{id}/')
  Future<GoalOutDto> update(@Path() String id, @Body() GoalPatchBody body);

  @DELETE('goals/{id}/')
  Future<void> delete(@Path() String id);

  @POST('goals/{id}/contribute/')
  Future<ContributionOutDto> contribute(
    @Path() String id,
    @Body() ContributeBody body,
  );

  @GET('goals/{id}/contributions/')
  Future<List<ContributionOutDto>> contributions(@Path() String id);

  @GET('goals/{id}/forecast/')
  Future<ForecastOutDto> forecast(@Path() String id);
}
