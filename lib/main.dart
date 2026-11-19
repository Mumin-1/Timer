import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TimerApp());
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Таймер',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ReactionScreen(),
    );
  }
}

enum Phase { start, waiting, go, tooEarly, result }

class ReactionScreen extends StatefulWidget {
  const ReactionScreen({super.key});

  @override
  State<ReactionScreen> createState() => _ReactionScreenState();
}

class _ReactionScreenState extends State<ReactionScreen> {
  final Random _rnd = Random();
  final Stopwatch _sw = Stopwatch();
  Timer? _timer;

  Phase _phase = Phase.start;
  int? _last;
  int? _best;
  final List<int> _history = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() => _phase = Phase.waiting);
    // Случайная задержка от 2 до 6 секунд
    final delay = Duration(milliseconds: 2000 + _rnd.nextInt(4000));
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _phase = Phase.go;
        _sw
          ..reset()
          ..start();
      });
    });
  }

  void _onTap() {
    switch (_phase) {
      case Phase.start:
      case Phase.tooEarly:
      case Phase.result:
        _startRound();
        break;
      case Phase.waiting:
        _timer?.cancel();
        setState(() => _phase = Phase.tooEarly);
        break;
      case Phase.go:
        _sw.stop();
        final ms = _sw.elapsedMilliseconds;
        setState(() {
          _last = ms;
          _history.add(ms);
          if (_best == null || ms < _best!) _best = ms;
          _phase = Phase.result;
        });
        break;
    }
  }

  int? get _average {
    if (_history.isEmpty) return null;
    return (_history.reduce((a, b) => a + b) / _history.length).round();
  }

  String _rating(int ms) {
    if (ms < 200) return 'Молниеносно! ⚡';
    if (ms < 250) return 'Отличная реакция!';
    if (ms < 300) return 'Хорошая реакция';
    if (ms < 400) return 'Нормально';
    return 'Можно быстрее 🙂';
  }

  Color get _bg {
    switch (_phase) {
      case Phase.start:
        return const Color(0xFF1E2A44);
      case Phase.waiting:
        return const Color(0xFFD32F2F); // красный
      case Phase.go:
        return const Color(0xFF2E7D32); // зелёный
      case Phase.tooEarly:
        return const Color(0xFFF57C00);
      case Phase.result:
        return const Color(0xFF1E2A44);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTap(), // реагирует сразу при касании
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: _bg,
        child: SafeArea(child: Center(child: _content())),
      ),
    );
  }

  TextStyle _big() => const TextStyle(
      color: Colors.white,
      fontSize: 34,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none);

  TextStyle _small() => const TextStyle(
      color: Colors.white70,
      fontSize: 18,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none);

  Widget _content() {
    switch (_phase) {
      case Phase.start:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏱', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 12),
              Text('Таймер', style: _big()),
              const SizedBox(height: 16),
              Text(
                'Проверь свою реакцию.\nЖди, пока экран станет зелёным, и сразу нажми!',
                textAlign: TextAlign.center,
                style: _small(),
              ),
              const SizedBox(height: 32),
              Text('Нажми, чтобы начать', style: _big().copyWith(fontSize: 22)),
            ],
          ),
        );
      case Phase.waiting:
        return Text('Жди зелёный...', style: _big());
      case Phase.go:
        return Text('ЖМИ!', style: _big().copyWith(fontSize: 64));
      case Phase.tooEarly:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Слишком рано!', style: _big()),
              const SizedBox(height: 12),
              Text('Дождись зелёного экрана.\nНажми, чтобы повторить.',
                  textAlign: TextAlign.center, style: _small()),
            ],
          ),
        );
      case Phase.result:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_last мс', style: _big().copyWith(fontSize: 64)),
              const SizedBox(height: 8),
              Text(_rating(_last!), style: _big().copyWith(fontSize: 24)),
              const SizedBox(height: 24),
              Text('Лучший: $_best мс', style: _small()),
              const SizedBox(height: 4),
              Text('Среднее: ${_average} мс  (попыток: ${_history.length})',
                  style: _small()),
              const SizedBox(height: 32),
              Text('Нажми, чтобы повторить',
                  style: _big().copyWith(fontSize: 22)),
            ],
          ),
        );
    }
  }
}
