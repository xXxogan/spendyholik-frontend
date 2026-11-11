import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:spendyholik/features/user/data/models/auth_dtos.dart';

part 'auth_api.g.dart';

@lazySingleton
@RestApi()
abstract class AuthApi {
  @factoryMethod
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('auth/login/')
  Future<AuthOutDto> login(@Body() LoginBody body);

  @POST('auth/register/')
  Future<AuthOutDto> register(@Body() RegisterBody body);

  @POST('auth/logout/')
  Future<void> logout(@Body() RefreshBody body);

  @GET('profile/')
  Future<ProfileOutDto> profile();

  @PATCH('profile/')
  Future<ProfileOutDto> updateProfile(@Body() ProfilePatchBody body);

  @PATCH('profile/password/')
  Future<void> changePassword(@Body() PasswordBody body);

  /// Ответ — UserOut; профиль после подтверждения перечитывается целиком.
  @POST('auth/email/confirm/')
  Future<void> confirmEmail(@Body() ConfirmEmailBody body);

  @POST('auth/email/resend/')
  Future<void> resendEmailCode();
}
