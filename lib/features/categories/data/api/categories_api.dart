import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/categories/data/models/category_dtos.dart';

part 'categories_api.g.dart';

@lazySingleton
@RestApi()
abstract class CategoriesApi {
  @factoryMethod
  factory CategoriesApi(Dio dio) = _CategoriesApi;

  @GET('categories/')
  Future<List<CategoryOutDto>> list();

  @POST('categories/')
  Future<CategoryOutDto> create(@Body() CategoryCreateBody body);

  @PATCH('categories/{id}/')
  Future<CategoryOutDto> update(
    @Path() String id,
    @Body() CategoryPatchBody body,
  );
}
