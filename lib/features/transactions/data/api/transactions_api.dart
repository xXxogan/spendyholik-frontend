import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_dtos.dart';

part 'transactions_api.g.dart';

@lazySingleton
@RestApi()
abstract class TransactionsApi {
  @factoryMethod
  factory TransactionsApi(Dio dio) = _TransactionsApi;

  /// `date_to` включительно.
  @GET('transactions/')
  Future<TransactionPageDto> list({
    @Query('type') String? type,
    @Query('account_id') String? accountId,
    @Query('category_id') String? categoryId,
    @Query('date_from') String? dateFrom,
    @Query('date_to') String? dateTo,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  @GET('transactions/{id}/')
  Future<TransactionOutDto> get(@Path() String id);

  @POST('transactions/')
  Future<TransactionOutDto> create(@Body() TransactionCreateBody body);

  @PATCH('transactions/{id}/')
  Future<TransactionOutDto> update(
    @Path() String id,
    @Body() TransactionPatchBody body,
  );

  @DELETE('transactions/{id}/')
  Future<void> delete(@Path() String id);
}
