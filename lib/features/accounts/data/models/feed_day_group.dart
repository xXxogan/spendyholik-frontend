import 'package:spendyholik/features/accounts/data/models/feed_entry.dart';

class FeedDayGroup {
  const FeedDayGroup({required this.day, required this.items});

  /// Начало дня.
  final DateTime day;
  final List<FeedEntry> items;
}
