import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/config/app_config.dart';
import 'package:spendyholik/core/network/api_call.dart';
import 'package:spendyholik/core/network/cached_read.dart';
import 'package:spendyholik/features/accounts/data/api/accounts_api.dart';
import 'package:spendyholik/features/accounts/data/models/feed_dtos.dart';
import 'package:spendyholik/features/accounts/data/models/models.dart';
import 'package:spendyholik/features/accounts/data/repositories/account_feed_repository.dart';
import 'package:spendyholik/features/debts/debts.dart';
import 'package:spendyholik/features/transactions/transactions.dart';
import 'package:talker/talker.dart';

@LazySingleton(as: AccountFeedRepository)
class RemoteAccountFeedRepository implements AccountFeedRepository {
  RemoteAccountFeedRepository(
    this._api,
    this._reader,
    this._mapper,
    this._talker,
  );

  final AccountsApi _api;
  final CachedReader _reader;
  final TransactionMapper _mapper;
  final Talker _talker;

  @override
  Future<FeedPage> getPage(String accountId, {String? cursor}) async {
    const limit = AppConfig.transactionsPageSize;
    Future<FeedPageDto> fetch() => callApi(
      () => _api.feed(accountId: accountId, cursor: cursor, limit: limit),
    );

    // Как у операций: в кэше только первая страница, продолжение из старого
    // кэша дало бы дыры в ленте.
    final dto = cursor == null
        ? await _reader.read(
            key: cacheKey('feed', {'account_id': accountId, 'limit': limit}),
            fetch: fetch,
            toJson: (dto) => dto.toJson(),
            fromJson: (json) =>
                FeedPageDto.fromJson(json! as Map<String, dynamic>),
          )
        : await fetch();
    return FeedPage(
      items: dto.items.map(_entry).nonNulls.toList(),
      nextCursor: dto.nextCursor,
    );
  }

  /// null — запись, которую клиент не умеет показать: новый `kind` сервера
  /// или `transfer`, который бывает только без фильтра счёта.
  FeedEntry? _entry(FeedItemOutDto dto) {
    final effect = switch (dto.effect) {
      'in' => FeedEffect.incoming,
      'out' => FeedEffect.outgoing,
      _ => null,
    };
    if (effect == null) return _skip(dto);
    final date = DateTime.parse(dto.date);
    final currency = _mapper.currency(dto.amount.currency);
    final amount = dto.amount.minor;
    final transaction = dto.transaction;
    final debt = dto.debt;
    final goal = dto.goal;
    return switch (dto.kind) {
      'transaction' when transaction != null => FeedTransaction(
        id: dto.id,
        date: date,
        amount: amount,
        currency: currency,
        effect: effect,
        transaction: _mapper.transaction(transaction),
      ),
      'debt_opening' || 'debt_payment' when debt != null => FeedDebtEvent(
        id: dto.id,
        date: date,
        amount: amount,
        currency: currency,
        effect: effect,
        debtId: debt.id,
        personName: debt.personName,
        direction: debt.direction == 'owed_to_me'
            ? DebtDirection.owedToMe
            : DebtDirection.iOwe,
        opening: dto.kind == 'debt_opening',
      ),
      'goal_contribution' when goal != null => FeedGoalContribution(
        id: dto.id,
        date: date,
        amount: amount,
        currency: currency,
        effect: effect,
        goalId: goal.id,
        goalName: goal.name,
      ),
      _ => _skip(dto),
    };
  }

  FeedEntry? _skip(FeedItemOutDto dto) {
    _talker.warning('Feed item ${dto.kind}/${dto.effect} ${dto.id} skipped');
    return null;
  }
}
