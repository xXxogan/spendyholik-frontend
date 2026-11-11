import 'package:spendyholik/core/models/currency.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.baseCurrency,
    this.emailVerified = true,
  });

  final String id;
  final String name;
  final String email;

  /// null — валюта ещё не выбрана, после входа ведём на выбор валюты.
  final Currency? baseCurrency;

  /// false — почта не подтверждена: до ввода кода из письма сервер закрыт.
  final bool emailVerified;

  UserModel copyWith({
    String? name,
    String? email,
    Currency? baseCurrency,
    bool? emailVerified,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}
