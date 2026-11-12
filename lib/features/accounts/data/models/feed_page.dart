import 'package:spendyholik/features/accounts/data/models/feed_entry.dart';

class FeedPage {
  const FeedPage({required this.items, this.nextCursor});

  /// Порядок сервера: день, затем время записи в базу — новые первыми.
  final List<FeedEntry> items;

  /// null — страница последняя.
  final String? nextCursor;
}
