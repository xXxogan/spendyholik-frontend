import 'package:spendyholik/core/models/currency.dart';

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

  UserModel copyWith({Currency? baseCurrency}) => UserModel(
    id: id,
    name: name,
    email: email,
    baseCurrency: baseCurrency ?? this.baseCurrency,
  );
}
