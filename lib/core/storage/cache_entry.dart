import 'package:hive_ce/hive_ce.dart';

class CacheEntry {
  const CacheEntry(this.json, this.savedAt);

  final String json;
  final DateTime savedAt;
}

/// Рукописный: hive_ce_generator требует другой analyzer и откатывает freezed.
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final typeId = 0;

  @override
  CacheEntry read(BinaryReader reader) => CacheEntry(
    reader.readString(),
    DateTime.fromMillisecondsSinceEpoch(reader.readInt(), isUtc: true),
  );

  @override
  void write(BinaryWriter writer, CacheEntry obj) => writer
    ..writeString(obj.json)
    ..writeInt(obj.savedAt.millisecondsSinceEpoch);
}
