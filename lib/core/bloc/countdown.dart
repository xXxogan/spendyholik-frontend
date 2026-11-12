import 'dart:async';

/// Обратный отсчёт по секундам — до повторной отправки кода из письма.
class Countdown {
  Timer? _timer;

  /// Сразу сообщает [seconds], затем каждую секунду — сколько осталось, до 0.
  void start(int seconds, void Function(int left) onTick) {
    _timer?.cancel();
    var left = seconds;
    onTick(left);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      left--;
      onTick(left);
      if (left <= 0) timer.cancel();
    });
  }

  void cancel() => _timer?.cancel();
}
