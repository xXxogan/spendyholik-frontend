import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/features/accounts/accounts.dart';

abstract final class FakeSeed {
  static List<AccountModel> accounts() => const [
    AccountModel(
      id: 'acc-tinkoff',
      name: 'Карта Тинькофф',
      type: AccountType.debit,
      balance: 8425000,
      color: EntityColor.yellow,
      isArchived: false,
      cardLast4: '4831',
    ),
    AccountModel(
      id: 'acc-savings',
      name: 'Накопительный счёт',
      type: AccountType.savings,
      balance: 15640000,
      color: EntityColor.green,
      isArchived: false,
      interestRate: 6.2,
    ),
    AccountModel(
      id: 'acc-cash',
      name: 'Наличные',
      type: AccountType.cash,
      balance: 1280000,
      color: EntityColor.teal,
      isArchived: false,
    ),
    AccountModel(
      id: 'acc-credit',
      name: 'Кредитная карта',
      type: AccountType.credit,
      balance: -2340000,
      color: EntityColor.red,
      isArchived: false,
      creditLimit: 15000000,
    ),
    AccountModel(
      id: 'acc-sber',
      name: 'Зарплатная карта Сбера',
      type: AccountType.debit,
      balance: 0,
      color: EntityColor.gray,
      isArchived: true,
    ),
  ];
}
