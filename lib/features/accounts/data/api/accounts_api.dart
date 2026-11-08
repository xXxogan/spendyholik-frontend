import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/accounts/data/models/account_dtos.dart';

part 'accounts_api.g.dart';

@lazySingleton
@RestApi()
abstract class AccountsApi {
  @factoryMethod
  factory AccountsApi(Dio dio) = _AccountsApi;

  @GET('accounts/')
  Future<List<AccountOutDto>> list(
    @Query('include_archived') bool includeArchived,
  );

  @GET('accounts/{id}/')
  Future<AccountOutDto> get(@Path() String id);

  @POST('accounts/')
  Future<AccountOutDto> create(@Body() AccountCreateBody body);

  @PATCH('accounts/{id}/')
  Future<AccountOutDto> update(
    @Path() String id,
    @Body() AccountPatchBody body,
  );

  @POST('accounts/{id}/archive/')
  Future<AccountOutDto> archive(@Path() String id);

  @POST('accounts/{id}/unarchive/')
  Future<AccountOutDto> unarchive(@Path() String id);

  @GET('accounts/{id}/balance-history/')
  Future<List<BalancePointOutDto>> history(
    @Path() String id,
    @Query('weeks') int weeks,
  );

  @GET('dashboard/')
  Future<DashboardOutDto> dashboard();
}
