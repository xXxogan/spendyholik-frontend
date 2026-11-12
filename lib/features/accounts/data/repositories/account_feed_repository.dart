import 'package:spendyholik/features/accounts/data/models/models.dart';

/// Бросает только [Failure] из `core/errors`. Первая страница — с подстраховкой кэшем.
abstract interface class AccountFeedRepository {
  Future<FeedPage> getPage(String accountId, {String? cursor});
}
