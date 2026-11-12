import 'package:injectable/injectable.dart';
import 'package:spendyholik/core/models/models.dart';
import 'package:spendyholik/core/session/session_currency.dart';
import 'package:spendyholik/features/accounts/accounts.dart';
import 'package:spendyholik/features/categories/categories.dart';
import 'package:spendyholik/features/transactions/data/models/models.dart';
import 'package:spendyholik/features/transactions/data/models/transaction_dtos.dart';
import 'package:talker/talker.dart';

/// Общий с лентой счёта: операция в ленте приходит той же формой `TransactionOut`.
@lazySingleton
class TransactionMapper {
  TransactionMapper(this._session, this._talker);

  final SessionCurrency _session;
  final Talker _talker;

  TransactionModel transaction(TransactionOutDto dto) {
    final type =
        TransactionType.values.asNameMap()[dto.type] ?? TransactionType.expense;
    final day = DateTime.parse(dto.date);
    // Без времени — полдень, чтобы операция не уезжала на соседний день.
    final parts = (dto.time ?? '12:00:00').split(':');
    final note = dto.note;
    return TransactionModel(
      id: dto.id,
      currency: currency(dto.amount.currency),
      type: type,
      amount: dto.amount.minor,
      title: _ownTitle(dto, type),
      category: switch (dto.category) {
        final ref? => CategoryRef(
          id: ref.id,
          name: ref.name ?? '',
          icon: EntityIcon.values.asNameMap()[ref.icon] ?? EntityIcon.other,
          color: EntityColor.values.asNameMap()[ref.color] ?? EntityColor.gray,
        ),
        null => null,
      },
      account: _accountRef(dto.account),
      toAccount: switch (dto.transferToAccount) {
        final ref? => _accountRef(ref),
        null => null,
      },
      occurredAt: DateTime(
        day.year,
        day.month,
        day.day,
        int.tryParse(parts[0]) ?? 12,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0,
      ),
      note: note == null || note.isEmpty ? null : note,
    );
  }

  /// Неизвестный код — базовая валюта сессии с warning.
  Currency currency(String code) {
    final currency = Currency.fromCode(code);
    if (currency != null) return currency;
    _talker.warning('Unknown transaction currency $code, using base');
    return _session.value;
  }

  /// Без своего названия сервер отдаёт имя категории (у перевода — счёта или
  /// «Перевод», renderers.py). Это не название пользователя: иначе форма правки
  /// вернула бы его на сервер навсегда, и переименование категории до операции
  /// уже не дошло бы (аудит 2026-11-09). Пустое название плитка показывает
  /// именем категории или «откуда → куда» сама.
  static String _ownTitle(TransactionOutDto dto, TransactionType type) {
    final fallbacks = type == TransactionType.transfer
        ? {dto.account.name, 'Перевод'}
        : {dto.category?.name ?? ''};
    return fallbacks.contains(dto.title) ? '' : dto.title;
  }

  AccountRef _accountRef(AccountRefDto dto) => AccountRef(
    id: dto.id,
    name: dto.name,
    color: EntityColor.values.asNameMap()[dto.color] ?? EntityColor.gray,
  );
}
