import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/errors/failure.dart';
import 'package:spendyholik/core/network/api_call.dart';

@lazySingleton
class PrivacyPolicyRepository {
  const PrivacyPolicyRepository(@Named('publicDocumentsDio') this._dio);

  final Dio _dio;

  Future<String> load() async {
    final response = await callApi(
      () => _dio.get<String>(
        AppConfig.privacyPolicyUrl,
        options: Options(responseType: .plain),
      ),
    );
    final document = response.data;
    if (document == null || document.trim().isEmpty) {
      throw const UnknownFailure();
    }
    return document;
  }
}
