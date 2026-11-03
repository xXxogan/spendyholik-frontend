import 'package:spendyholik/core/models/currency.dart';

enum AuthProvider { apple, google }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.baseCurrency,
  });

  final String id;
  final String name;
  final String email;

  /// null — валюта ещё не выбрана, после входа ведём на выбор валюты.
  final Currency? baseCurrency;
}
