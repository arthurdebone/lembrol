import 'package:clock/clock.dart' as pkg_clock;

/// Abstração de relógio para permitir testes unitários determinísticos
/// sem dependência do relógio físico do sistema operacional.
abstract class AppClock {
  DateTime now();
}

/// Implementação padrão que utiliza o relógio do sistema (ou pkg_clock.clock)
class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => pkg_clock.clock.now();
}

/// Relógio virtual controlável para simulações e testes automatizados
class SettableClock implements AppClock {
  DateTime _currentTime;

  SettableClock(this._currentTime);

  @override
  DateTime now() => _currentTime;

  void setTime(DateTime newTime) {
    _currentTime = newTime;
  }

  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
}
