import 'package:spendyholik/core/models/currency.dart';
import 'package:spendyholik/core/models/date_period.dart';
import 'package:spendyholik/core/models/entity_color.dart';
import 'package:spendyholik/core/models/entity_icon.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/budgets/data/models/models.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/debts/data/models/models.dart';
import 'package:spendyholik/features/goals/data/models/models.dart';
import 'package:spendyholik/features/notifications/data/models/models.dart';
import 'package:spendyholik/features/recurring/data/models/models.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:spendyholik/features/user/data/models/models.dart';

abstract final class FakeSeed {
  /// Тестовый вход фазы 1 — не настоящие учётные данные.
  static const email = 'maria@example.com';
  static const password = 'spendy-test-2026';

  static const user = UserModel(
    id: 'user-maria',
    name: 'Мария Соколова',
    email: email,
    baseCurrency: Currency.rub,
  );

  /// Балансы здесь начальные: итоговые считает FakeBackend из операций.
  static List<AccountModel> initialAccounts() => const [
    AccountModel(
      id: 'acc-tinkoff',
      name: 'Карта Тинькофф',
      type: AccountType.debit,
      balance: 7622100,
      color: EntityColor.yellow,
      isArchived: false,
      cardLast4: '4831',
    ),
    AccountModel(
      id: 'acc-savings',
      name: 'Накопительный счёт',
      type: AccountType.savings,
      balance: 856000,
      color: EntityColor.green,
      isArchived: false,
      interestRate: 6.2,
    ),
    AccountModel(
      id: 'acc-cash',
      name: 'Наличные',
      type: AccountType.cash,
      balance: 895000,
      color: EntityColor.teal,
      isArchived: false,
    ),
    AccountModel(
      id: 'acc-credit',
      name: 'Кредитная карта',
      type: AccountType.credit,
      balance: -1376000,
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

  static List<CategoryModel> categories() => const [
    CategoryModel(
      id: 'cat-groceries',
      name: 'Продукты',
      kind: CategoryKind.expense,
      icon: EntityIcon.cart,
      color: EntityColor.green,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-groceries-delivery',
      name: 'Доставка продуктов',
      kind: CategoryKind.expense,
      icon: EntityIcon.cart,
      color: EntityColor.teal,
      parentId: 'cat-groceries',
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-cafe',
      name: 'Кафе и рестораны',
      kind: CategoryKind.expense,
      icon: EntityIcon.cafe,
      color: EntityColor.orange,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-transport',
      name: 'Транспорт',
      kind: CategoryKind.expense,
      icon: EntityIcon.bus,
      color: EntityColor.blue,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-housing',
      name: 'Жильё',
      kind: CategoryKind.expense,
      icon: EntityIcon.home,
      color: EntityColor.purple,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-fun',
      name: 'Развлечения',
      kind: CategoryKind.expense,
      icon: EntityIcon.film,
      color: EntityColor.pink,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-health',
      name: 'Здоровье',
      kind: CategoryKind.expense,
      icon: EntityIcon.health,
      color: EntityColor.red,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-shopping',
      name: 'Покупки',
      kind: CategoryKind.expense,
      icon: EntityIcon.bag,
      color: EntityColor.yellow,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-subscriptions',
      name: 'Подписки',
      kind: CategoryKind.expense,
      icon: EntityIcon.subscription,
      color: EntityColor.gray,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-salary',
      name: 'Зарплата',
      kind: CategoryKind.income,
      icon: EntityIcon.salary,
      color: EntityColor.green,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-freelance',
      name: 'Фриланс',
      kind: CategoryKind.income,
      icon: EntityIcon.freelance,
      color: EntityColor.blue,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-interest',
      name: 'Проценты по вкладу',
      kind: CategoryKind.income,
      icon: EntityIcon.percent,
      color: EntityColor.teal,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-debt-return',
      name: 'Возврат долга',
      kind: CategoryKind.income,
      icon: EntityIcon.gift,
      color: EntityColor.purple,
      transactionCount: 0,
    ),
    CategoryModel(
      id: 'cat-between',
      name: 'Между счетами',
      kind: CategoryKind.transfer,
      icon: EntityIcon.transfer,
      color: EntityColor.gray,
      transactionCount: 0,
    ),
  ];

  /// Два непрочитанных и два прочитанных — как в AC-25.
  static List<NotificationModel> notifications(DateTime now) => [
    NotificationModel(
      id: 'ntf-budget',
      kind: NotificationKind.budgetAlmostSpent,
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      subject: 'Развлечения',
      percent: 86,
    ),
    NotificationModel(
      id: 'ntf-salary',
      kind: NotificationKind.incomeReceived,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      isRead: false,
      subject: 'Яндекс',
      amount: 11850000,
    ),
    NotificationModel(
      id: 'ntf-plus',
      kind: NotificationKind.recurringTomorrow,
      createdAt: now.subtract(const Duration(days: 3)),
      isRead: true,
      subject: 'Яндекс Плюс',
      amount: 29900,
    ),
    NotificationModel(
      id: 'ntf-goal',
      kind: NotificationKind.goalProgress,
      createdAt: now.subtract(const Duration(days: 6)),
      isRead: true,
      subject: 'Подушка безопасности',
      percent: 60,
    ),
  ];

  /// Шаблоны регулярных операций: id, черновик, на паузе ли.
  static List<(String, RecurringDraft, bool)> recurring(DateTime now) {
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return [
      (
        'rec-rent',
        RecurringDraft(
          title: 'Аренда квартиры',
          type: TransactionType.expense,
          amount: 4500000,
          categoryId: 'cat-housing',
          accountId: 'acc-savings',
          frequency: RecurrenceFrequency.monthly,
          anchor: DateTime(now.year - 1, 1, 1, 12),
        ),
        false,
      ),
      (
        'rec-salary',
        RecurringDraft(
          title: 'Зарплата · Яндекс',
          type: TransactionType.income,
          amount: 11850000,
          categoryId: 'cat-salary',
          accountId: 'acc-savings',
          frequency: RecurrenceFrequency.monthly,
          anchor: DateTime(now.year - 1, 1, 5, 10),
        ),
        false,
      ),
      (
        'rec-plus',
        RecurringDraft(
          title: 'Яндекс Плюс',
          type: TransactionType.expense,
          amount: 29900,
          categoryId: 'cat-subscriptions',
          accountId: 'acc-tinkoff',
          frequency: RecurrenceFrequency.monthly,
          anchor: DateTime(now.year - 1, 1, 31, 9, 30),
        ),
        false,
      ),
      (
        'rec-cleaning',
        RecurringDraft(
          title: 'Уборка',
          type: TransactionType.expense,
          amount: 250000,
          categoryId: 'cat-housing',
          accountId: 'acc-tinkoff',
          frequency: RecurrenceFrequency.weekly,
          anchor: DateTime(monday.year, monday.month, monday.day - 21 + 4, 11),
        ),
        false,
      ),
      (
        'rec-insurance',
        RecurringDraft(
          title: 'Страховка ОСАГО',
          type: TransactionType.expense,
          amount: 1450000,
          categoryId: 'cat-transport',
          accountId: 'acc-tinkoff',
          frequency: RecurrenceFrequency.yearly,
          anchor: DateTime(now.year - 2, 3, 15, 12),
        ),
        false,
      ),
      (
        'rec-gym',
        RecurringDraft(
          title: 'Спортзал',
          type: TransactionType.expense,
          amount: 249000,
          categoryId: 'cat-health',
          accountId: 'acc-tinkoff',
          frequency: RecurrenceFrequency.monthly,
          anchor: DateTime(now.year - 1, 1, 10, 12),
        ),
        true,
      ),
    ];
  }

  /// `saved` здесь не важен: FakeBackend считает его из пополнений.
  static List<GoalModel> goals(DateTime now) => [
    const GoalModel(
      id: 'goal-buffer',
      name: 'Подушка безопасности',
      target: 20000000,
      saved: 0,
    ),
    GoalModel(
      id: 'goal-trip',
      name: 'Отпуск в Грузии',
      target: 9000000,
      saved: 0,
      deadline: DateTime(now.year, now.month + 8),
    ),
    const GoalModel(
      id: 'goal-laptop',
      name: 'MacBook Air',
      target: 18000000,
      saved: 0,
    ),
    GoalModel(
      id: 'goal-phone',
      name: 'Новый телефон',
      target: 6000000,
      saved: 0,
      deadline: DateTime(now.year, now.month - 1),
    ),
  ];

  /// Долги без остатка: `remaining` backend пересчитывает из событий.
  static List<DebtModel> debts(DateTime now) {
    DateTime ago(int days) => now.subtract(Duration(days: days));
    DateTime ahead(int days) => now.add(Duration(days: days));

    DebtModel debt(
      String id,
      String counterparty,
      DebtDirection direction,
      int total,
      int createdDaysAgo, {
      DateTime? dueDate,
      String? note,
    }) => DebtModel(
      id: id,
      counterparty: counterparty,
      direction: direction,
      total: total,
      remaining: total,
      dueDate: dueDate,
      note: note,
      createdAt: ago(createdDaysAgo),
    );

    return [
      debt(
        'debt-dmitry',
        'Дмитрий',
        .iOwe,
        1200000,
        10,
        dueDate: ahead(17),
        note: 'Заём до зарплаты',
      ),
      debt(
        'debt-sister',
        'Сестра',
        .iOwe,
        3000000,
        60,
        dueDate: ago(5),
        note: 'На ремонт',
      ),
      debt('debt-colleague', 'Коллега', .iOwe, 500000, 25),
      debt(
        'debt-kirill',
        'Кирилл',
        .owedToMe,
        850000,
        6,
        note: 'Возврат за концерт',
      ),
      debt('debt-oleg', 'Олег', .owedToMe, 1500000, 30, dueDate: ago(3)),
      debt('debt-masha', 'Маша', .owedToMe, 200000, 18),
    ];
  }

  /// События долгов: открытие на дату создания плюс погашения.
  static List<(String, DebtEvent)> debtEvents(
    DateTime now,
    List<DebtModel> debts,
    List<AccountModel> accounts,
  ) {
    AccountRef acc(String id) {
      final a = accounts.firstWhere((a) => a.id == id);
      return AccountRef(id: a.id, name: a.name, color: a.color);
    }

    var n = 0;
    (String, DebtEvent) repayment(
      String debtId,
      int amount,
      String account,
      int daysAgo,
    ) {
      n++;
      return (
        debtId,
        DebtEvent(
          id: 'de-r${n.toString().padLeft(3, '0')}',
          kind: .repayment,
          amount: amount,
          date: now.subtract(Duration(days: daysAgo)),
          account: acc(account),
        ),
      );
    }

    return [
      for (final d in debts)
        (
          d.id,
          DebtEvent(
            id: 'de-open-${d.id}',
            kind: .opened,
            amount: d.total,
            date: d.createdAt,
          ),
        ),
      repayment('debt-sister', 1000000, 'acc-tinkoff', 40),
      repayment('debt-sister', 1000000, 'acc-tinkoff', 12),
      repayment('debt-colleague', 500000, 'acc-cash', 20),
      repayment('debt-oleg', 500000, 'acc-tinkoff', 8),
      repayment('debt-masha', 200000, 'acc-cash', 15),
    ];
  }

  /// Помесячные пополнения: по ним в деталях цели считается прогноз.
  static List<(String, GoalContribution)> contributions(
    DateTime now,
    List<AccountModel> accounts,
  ) {
    AccountRef acc(String id) {
      final a = accounts.firstWhere((a) => a.id == id);
      return AccountRef(id: a.id, name: a.name, color: a.color);
    }

    var n = 0;
    (String, GoalContribution) contribution(
      String goalId,
      int amount,
      String account,
      int monthsAgo,
    ) {
      n++;
      return (
        goalId,
        GoalContribution(
          id: 'gc-${n.toString().padLeft(3, '0')}',
          amount: amount,
          from: acc(account),
          date: DateTime(now.year, now.month - monthsAgo, 5, 12),
        ),
      );
    }

    return [
      for (var m = 1; m <= 6; m++)
        contribution('goal-buffer', 2000000, 'acc-savings', m),
      for (var m = 1; m <= 3; m++)
        contribution('goal-trip', 1500000, 'acc-tinkoff', m),
      contribution('goal-laptop', 2000000, 'acc-tinkoff', 2),
      contribution('goal-laptop', 1000000, 'acc-tinkoff', 5),
      for (var m = 2; m <= 5; m++)
        contribution('goal-phone', 1500000, 'acc-tinkoff', m),
    ];
  }

  /// Траты сида зависят от дня месяца, поэтому лимит подбирается под долю
  /// от уже потраченного — так на любой день видны ok, warning и exceeded.
  /// Ничего не потрачено — лимит [fallback].
  static List<(String, BudgetDraft)> budgets(
    DateTime now,
    int Function(String categoryId, DatePeriod period) spentOf,
  ) {
    final day = DateTime(now.year, now.month, now.day);
    final onceStart = DateTime(day.year, day.month, day.day - 10);
    final onceEnd = DateTime(day.year, day.month, day.day + 20);

    (String, BudgetDraft) budget(
      String id,
      String categoryId,
      BudgetPeriod period,
      double share,
      int fallback,
    ) {
      final spent = spentOf(categoryId, switch (period) {
        BudgetPeriod.monthly => DatePeriod.current(PeriodPreset.month, now),
        BudgetPeriod.weekly => DatePeriod.current(PeriodPreset.week, now),
        BudgetPeriod.once => DatePeriod(start: onceStart, end: onceEnd),
      });
      const step = 10000;
      final limit = spent == 0
          ? fallback
          : ((spent / share) / step).ceil() * step;
      return (
        id,
        BudgetDraft(
          categoryId: categoryId,
          limit: limit,
          period: period,
          onceStart: period == BudgetPeriod.once ? onceStart : null,
          onceEnd: period == BudgetPeriod.once ? onceEnd : null,
        ),
      );
    }

    return [
      budget('bud-groceries', 'cat-groceries', .monthly, 0.71, 2000000),
      budget('bud-fun', 'cat-fun', .monthly, 0.86, 800000),
      budget('bud-transport', 'cat-transport', .weekly, 0.48, 500000),
      budget('bud-cafe', 'cat-cafe', .monthly, 1.12, 600000),
      budget('bud-shopping', 'cat-shopping', .once, 0.6, 1500000),
    ];
  }

  /// Даты строятся от [now] смещением в днях, чтобы «Сегодня/Вчера» были правдой.
  static List<TransactionModel> transactions(
    DateTime now,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
  ) {
    AccountRef acc(String id) {
      final a = accounts.firstWhere((a) => a.id == id);
      return AccountRef(id: a.id, name: a.name, color: a.color);
    }

    CategoryRef cat(String id) =>
        categories.firstWhere((c) => c.id == id).toRef();

    var n = 0;
    TransactionModel tx(
      TransactionType type,
      int amount,
      String title,
      int daysAgo,
      int hour,
      int minute,
      String account, {
      String? category,
      String? toAccount,
    }) {
      n++;
      return TransactionModel(
        id: 'tx-${n.toString().padLeft(3, '0')}',
        type: type,
        amount: amount,
        title: title,
        category: category == null ? null : cat(category),
        account: acc(account),
        toAccount: toAccount == null ? null : acc(toAccount),
        occurredAt: DateTime(
          now.year,
          now.month,
          now.day - daysAgo,
          hour,
          minute,
        ),
      );
    }

    const e = TransactionType.expense;
    const i = TransactionType.income;
    const t = TransactionType.transfer;
    // Помесячная история до свежих 36 дней: для сравнения периодов и
    // графиков по месяцам. Суммы меняются от месяца к месяцу детерминированно.
    List<TransactionModel> history() => [
      for (var m = 1; m <= 6; m++)
        ...() {
          final base = 30 * m + 6;
          int vary(int amount, int seed) =>
              amount + (m * 7919 + seed * 104729) % (amount ~/ 3);
          return [
            tx(
              i,
              11850000,
              'Зарплата \u00b7 Яндекс',
              base + 1,
              10,
              0,
              'acc-savings',
              category: 'cat-salary',
            ),
            tx(
              t,
              6000000,
              'На карту',
              base + 2,
              12,
              0,
              'acc-savings',
              toAccount: 'acc-tinkoff',
            ),
            tx(
              e,
              4500000,
              'Аренда квартиры',
              base + 3,
              12,
              0,
              'acc-savings',
              category: 'cat-housing',
            ),
            for (var w = 0; w < 4; w++)
              tx(
                e,
                vary(180000, w),
                'Пятёрочка',
                base + 4 + w * 7,
                18,
                30,
                'acc-tinkoff',
                category: 'cat-groceries',
              ),
            tx(
              e,
              vary(95000, 11),
              'Даблби',
              base + 6,
              13,
              10,
              'acc-tinkoff',
              category: 'cat-cafe',
            ),
            tx(
              e,
              vary(210000, 12),
              'Upside',
              base + 19,
              20,
              0,
              'acc-tinkoff',
              category: 'cat-cafe',
            ),
            for (var w = 0; w < 3; w++)
              tx(
                e,
                vary(60000, 20 + w),
                'Метро',
                base + 5 + w * 9,
                8,
                45,
                'acc-tinkoff',
                category: 'cat-transport',
              ),
            tx(
              e,
              29900,
              'Яндекс Плюс',
              base + 2,
              9,
              30,
              'acc-tinkoff',
              category: 'cat-subscriptions',
            ),
            tx(
              e,
              vary(150000, 30),
              'Кино \u00b7 Афиша',
              base + 13,
              19,
              0,
              'acc-tinkoff',
              category: 'cat-fun',
            ),
            if (m.isEven)
              tx(
                e,
                vary(120000, 40),
                'Аптека',
                base + 9,
                14,
                20,
                'acc-cash',
                category: 'cat-health',
              ),
            if (m % 3 == 0)
              tx(
                e,
                vary(900000, 50),
                'Озон',
                base + 16,
                21,
                15,
                'acc-tinkoff',
                category: 'cat-shopping',
              ),
            if (m % 3 == 1)
              tx(
                i,
                vary(2500000, 60),
                'Фриланс',
                base + 15,
                17,
                0,
                'acc-tinkoff',
                category: 'cat-freelance',
              ),
          ];
        }(),
    ];

    return [
      tx(
        e,
        124000,
        'Пятёрочка',
        0,
        18,
        42,
        'acc-tinkoff',
        category: 'cat-groceries',
      ),
      tx(e, 42000, 'Даблби', 0, 13, 15, 'acc-tinkoff', category: 'cat-cafe'),
      tx(
        i,
        11850000,
        'Зарплата \u00b7 Яндекс',
        1,
        10,
        0,
        'acc-savings',
        category: 'cat-salary',
      ),
      tx(
        e,
        29900,
        'Яндекс Плюс',
        1,
        9,
        30,
        'acc-tinkoff',
        category: 'cat-subscriptions',
      ),
      tx(e, 6200, 'Метро', 1, 8, 50, 'acc-tinkoff', category: 'cat-transport'),
      tx(
        e,
        4500000,
        'Аренда квартиры',
        3,
        12,
        0,
        'acc-savings',
        category: 'cat-housing',
      ),
      tx(e, 238000, 'Upside', 4, 20, 10, 'acc-tinkoff', category: 'cat-cafe'),
      tx(
        e,
        70000,
        'Кино \u00b7 Афиша',
        4,
        19,
        5,
        'acc-tinkoff',
        category: 'cat-fun',
      ),
      tx(
        i,
        850000,
        'Возврат долга \u00b7 Анна',
        5,
        16,
        20,
        'acc-tinkoff',
        category: 'cat-debt-return',
      ),
      tx(e, 115000, 'Аптека', 5, 14, 35, 'acc-cash', category: 'cat-health'),
      tx(
        t,
        500000,
        'Снятие наличных',
        6,
        11,
        0,
        'acc-tinkoff',
        toAccount: 'acc-cash',
      ),
      tx(
        e,
        348000,
        'ВкусВилл',
        7,
        19,
        12,
        'acc-tinkoff',
        category: 'cat-groceries-delivery',
      ),
      tx(e, 560000, 'Ozon', 8, 21, 3, 'acc-credit', category: 'cat-shopping'),
      tx(
        e,
        215000,
        'Магнит',
        11,
        18,
        20,
        'acc-tinkoff',
        category: 'cat-groceries',
      ),
      tx(
        e,
        736000,
        'Лента',
        15,
        17,
        45,
        'acc-tinkoff',
        category: 'cat-groceries',
      ),
      tx(
        e,
        189000,
        'Ресторан Терраса',
        16,
        20,
        30,
        'acc-credit',
        category: 'cat-cafe',
      ),
      tx(
        i,
        11850000,
        'Зарплата \u00b7 Яндекс',
        31,
        10,
        0,
        'acc-savings',
        category: 'cat-salary',
      ),
      tx(
        e,
        4500000,
        'Аренда квартиры',
        33,
        12,
        0,
        'acc-savings',
        category: 'cat-housing',
      ),
      tx(
        e,
        592000,
        'Лента',
        34,
        18,
        10,
        'acc-tinkoff',
        category: 'cat-groceries',
      ),
      tx(
        e,
        310000,
        'Азбука Вкуса',
        38,
        19,
        40,
        'acc-tinkoff',
        category: 'cat-groceries',
      ),
      tx(e, 125000, 'Кофейня', 36, 9, 15, 'acc-tinkoff', category: 'cat-cafe'),
      tx(
        e,
        215000,
        'Бургер Кинг',
        41,
        14,
        0,
        'acc-credit',
        category: 'cat-cafe',
      ),
      tx(
        e,
        180000,
        'Такси',
        37,
        23,
        10,
        'acc-tinkoff',
        category: 'cat-transport',
      ),
      tx(
        e,
        31000,
        'Метро',
        40,
        8,
        45,
        'acc-tinkoff',
        category: 'cat-transport',
      ),
      tx(
        i,
        3500000,
        'Фриланс \u00b7 Логотип',
        43,
        15,
        0,
        'acc-tinkoff',
        category: 'cat-freelance',
      ),
      tx(
        i,
        84000,
        'Проценты по вкладу',
        45,
        0,
        5,
        'acc-savings',
        category: 'cat-interest',
      ),
      ...history(),
    ];
  }
}
