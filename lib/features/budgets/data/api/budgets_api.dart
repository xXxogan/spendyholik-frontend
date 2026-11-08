import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/budgets/data/models/budget_dtos.dart';

part 'budgets_api.g.dart';

@lazySingleton
@RestApi()
abstract class BudgetsApi {
  @factoryMethod
  factory BudgetsApi(Dio dio) = _BudgetsApi;

  @GET('budgets/')
  Future<List<BudgetOutDto>> list();

  @GET('budgets/{id}/')
  Future<BudgetOutDto> get(@Path() String id);

  @POST('budgets/')
  Future<BudgetOutDto> create(@Body() BudgetCreateBody body);

  @PATCH('budgets/{id}/')
  Future<BudgetOutDto> update(@Path() String id, @Body() BudgetPatchBody body);

  @DELETE('budgets/{id}/')
  Future<void> delete(@Path() String id);
}
