import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/debts/data/models/debt_dtos.dart';

part 'debts_api.g.dart';

@lazySingleton
@RestApi()
abstract class DebtsApi {
  @factoryMethod
  factory DebtsApi(Dio dio) = _DebtsApi;

  @GET('debts/')
  Future<List<DebtOutDto>> list();

  @GET('debts/{id}/')
  Future<DebtOutDto> get(@Path() String id);

  @POST('debts/')
  Future<DebtOutDto> create(@Body() DebtCreateBody body);

  @PATCH('debts/{id}/')
  Future<DebtOutDto> update(@Path() String id, @Body() DebtPatchBody body);

  @GET('debts/{id}/history/')
  Future<List<DebtEventOutDto>> history(@Path() String id);

  @POST('debts/{id}/repay/')
  Future<DebtPaymentOutDto> repay(@Path() String id, @Body() RepayBody body);
}
