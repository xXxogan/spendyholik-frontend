import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:spendyholik/core/layout/window_size.dart';

const _panelSize = Size(460, 640);

/// На телефоне — календарь Material на весь экран, шире — панель по центру.
/// Отдельной настройки нет: размер календарного режима Material берёт из
/// MediaQuery, поэтому подменяем его размером панели.
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
}) => showDateRangePicker(
  context: context,
  firstDate: firstDate,
  lastDate: lastDate,
  initialDateRange: initialDateRange,
  builder: context.windowSize == WindowSize.compact ? null : _panel,
);

Widget _panel(BuildContext context, Widget? child) {
  final screen = MediaQuery.sizeOf(context);
  final size = Size(
    min(_panelSize.width, screen.width - 48),
    min(_panelSize.height, screen.height - 48),
  );
  final theme = Theme.of(context);

  return Center(
    child: SizedBox.fromSize(
      size: size,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(size: size, padding: .zero, viewPadding: .zero),
        child: Theme(
          data: theme.copyWith(
            datePickerTheme: theme.datePickerTheme.copyWith(
              rangePickerShape: RoundedRectangleBorder(
                borderRadius: .circular(28),
              ),
            ),
          ),
          child: child!,
        ),
      ),
    ),
  );
}
