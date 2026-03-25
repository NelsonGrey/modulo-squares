import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FallingModuloGameScreen extends StatefulWidget {
  const FallingModuloGameScreen({super.key, this.onOpenModePicker});

  final VoidCallback? onOpenModePicker;

  @override
  State<FallingModuloGameScreen> createState() =>
      _FallingModuloGameScreenState();
}

class _FallingModuloGameScreenState extends State<FallingModuloGameScreen> {
  static const Duration _tick = Duration(milliseconds: 16);
  static const Duration _spawnDelay = Duration(milliseconds: 500);
  static const String _visualCuesPrefKey = 'fallingMode.visualCuesEnabled';
  static const String _highScorePrefKey = 'fallingMode.highScore';

  final FallingModuloGameEngine _engine = FallingModuloGameEngine();
  late FallingModuloGameState _state;
  Timer? _timer;

  DateTime? _lastInputAt;
  Duration _elapsed = Duration.zero;
  Duration _spawnDelayRemaining = _spawnDelay;
  int _highScore = 0;
  String? _resultBurstText;
  bool _resultBurstPositive = true;

  @override
  void initState() {
    super.initState();
    _state = _engine.createInitialState();
    _loadPreferences();
    _startTicker();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final visualCues = prefs.getBool(_visualCuesPrefKey) ?? true;
    final highScore = prefs.getInt(_highScorePrefKey) ?? 0;

    if (!mounted) return;
    setState(() {
      _highScore = highScore;
      _state = _state.copyWith(visualCuesEnabled: visualCues);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;

      setState(() {
        if (_spawnDelayRemaining > Duration.zero) {
          _spawnDelayRemaining -= _tick;
          if (_spawnDelayRemaining < Duration.zero) {
            _spawnDelayRemaining = Duration.zero;
          }
        } else {
          _elapsed += _tick;
        }
      });

      if (_spawnDelayRemaining == Duration.zero &&
          _elapsed >= Duration(milliseconds: _effectiveDropIntervalMs)) {
        _resolveCurrentTile();
      }
    });
  }

  int get _effectiveDropIntervalMs => _state.dropIntervalMs * 2;

  bool get _isSpawnDelayActive => _spawnDelayRemaining > Duration.zero;

  double get _dropProgress {
    if (_isSpawnDelayActive) return 0.0;

    final totalMs = _effectiveDropIntervalMs;
    if (totalMs <= 0) return 1.0;
    final p = _elapsed.inMilliseconds / totalMs;
    return p.clamp(0.0, 1.0);
  }

  void _resetDropClock() {
    _elapsed = Duration.zero;
  }

  void _resolveCurrentTile() {
    final result = _engine.resolveCurrentTile(_state);
    final scoreDelta = result.resolution.scoreDelta;
    final success = result.resolution.success;
    final burstText = success ? '+$scoreDelta' : '$scoreDelta';

    setState(() {
      _state = result.state;
      _highScore = _state.score > _highScore ? _state.score : _highScore;
      _resultBurstText = burstText;
      _resultBurstPositive = success;
      _spawnDelayRemaining = _spawnDelay;
      _resetDropClock();
    });

    _persistHighScore();

    Timer(const Duration(milliseconds: 700), () {
      if (!mounted || _resultBurstText != burstText) return;
      setState(() {
        _resultBurstText = null;
      });
    });
  }

  Duration _moveCooldown() {
    final baseMs = 180;
    final adjusted = (baseMs / _state.horizontalMoveSpeedMultiplier).round();
    return Duration(milliseconds: adjusted.clamp(80, 180));
  }

  bool _canMoveNow() {
    final now = DateTime.now();
    final last = _lastInputAt;
    if (last == null) {
      _lastInputAt = now;
      return true;
    }

    if (now.difference(last) >= _moveCooldown()) {
      _lastInputAt = now;
      return true;
    }
    return false;
  }

  void _moveLeft() {
    if (!_canMoveNow()) return;
    setState(() {
      _state = _engine.moveLeft(_state);
    });
  }

  void _moveRight() {
    if (!_canMoveNow()) return;
    setState(() {
      _state = _engine.moveRight(_state);
    });
  }

  void _toggleVisualCues() {
    final enabled = !_state.visualCuesEnabled;
    setState(() {
      _state = _state.copyWith(visualCuesEnabled: enabled);
    });
    _persistVisualCues(enabled);
  }

  Future<void> _persistVisualCues(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visualCuesPrefKey, enabled);
  }

  Future<void> _persistHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScorePrefKey, _highScore);
  }

  void _startNewRun() {
    setState(() {
      _state = _engine.createInitialState(
        visualCuesEnabled: _state.visualCuesEnabled,
      );
      _elapsed = Duration.zero;
      _spawnDelayRemaining = _spawnDelay;
      _lastInputAt = null;
      _resultBurstText = null;
    });
  }

  Future<void> _openSettingsDialog() async {
    var localVisualCues = _state.visualCuesEnabled;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Falling Mode Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: localVisualCues,
                    onChanged: (value) {
                      setLocalState(() {
                        localVisualCues = value;
                      });
                    },
                    title: const Text('Visual Cues'),
                    subtitle: const Text('Highlight divisible buckets'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('High Score'),
                    trailing: Text('$_highScore'),
                  ),
                ],
              ),
              actions: [
                if (widget.onOpenModePicker != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      widget.onOpenModePicker?.call();
                    },
                    child: const Text('Switch Mode'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _startNewRun();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('New Run'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _state = _state.copyWith(
                        visualCuesEnabled: localVisualCues,
                      );
                    });
                    _persistVisualCues(localVisualCues);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final divisibleIndexes = _engine.divisibleBucketIndexes(_state).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modulo Squares: Falling Mode'),
        actions: [
          if (widget.onOpenModePicker != null)
            IconButton(
              tooltip: 'Switch game mode',
              onPressed: widget.onOpenModePicker,
              icon: const Icon(Icons.swap_horiz),
            ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip:
                _state.visualCuesEnabled
                    ? 'Disable visual cues'
                    : 'Enable visual cues',
            onPressed: _toggleVisualCues,
            icon: Icon(
              _state.visualCuesEnabled
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildModeBadge(),
              const SizedBox(height: 10),
              _buildHud(),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final laneWidth =
                        constraints.maxWidth /
                        FallingModuloGameEngine.laneCount;
                    final tileSize = laneWidth.clamp(24.0, 40.0);
                    final bucketTop = constraints.maxHeight - 92;
                    final fallTop = _dropProgress * (bucketTop - tileSize);

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blueGrey.shade50,
                                  Colors.blueGrey.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Positioned(
                          left:
                              (_state.currentLane * laneWidth) +
                              ((laneWidth - tileSize) / 2),
                          top: fallTop,
                          child: _buildFallingTile(tileSize),
                        ),
                        if (_resultBurstText != null)
                          Positioned(
                            top: 18,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _buildAnimatedScoreBurst(
                                _resultBurstText!,
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Row(
                            children: List<Widget>.generate(
                              _state.bucketValues.length,
                              (index) => SizedBox(
                                width: laneWidth,
                                child: _buildBucket(
                                  index: index,
                                  value: _state.bucketValues[index],
                                  selected: index == _state.currentLane,
                                  divisibleHint: divisibleIndexes.contains(
                                    index,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _dropProgress),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _moveLeft,
                    icon: const Icon(Icons.arrow_left),
                    label: const Text('Left'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSpawnDelayActive ? null : _resolveCurrentTile,
                    icon: const Icon(Icons.vertical_align_bottom),
                    label: const Text('Drop'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _moveRight,
                    icon: const Icon(Icons.arrow_right),
                    label: const Text('Right'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _pill('Level', '${_state.level}'),
        _pill('Score', '${_state.score}'),
        _pill('Best', '$_highScore'),
        _pill('Combo', '${_state.combo}'),
        _pill(
          'Move Speed',
          '${_state.horizontalMoveSpeedMultiplier.toStringAsFixed(2)}x',
        ),
        _pill(
          'Fall',
          _isSpawnDelayActive
              ? 'Ready...'
              : '${(_effectiveDropIntervalMs / 1000).toStringAsFixed(2)}s',
        ),
        _pill('Range', '${_state.numberRangeMin}-${_state.numberRangeMax}'),
      ],
    );
  }

  Widget _buildScoreBurst(String text) {
    final positive = _resultBurstPositive;
    final bg = positive ? const Color(0xFFFFD66B) : const Color(0xFFFF8A80);
    final fg = positive ? const Color(0xFF7A4A00) : const Color(0xFF7A0019);
    final border = positive ? const Color(0xFFFFA000) : const Color(0xFFD32F2F);
    final label = text;

    final burst = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(positive ? 999 : 16),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.22),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );

    if (positive) {
      return burst;
    }

    return Transform.rotate(
      angle: 0.78539816339,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: border.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -10,
              right: -8,
              child: Transform.rotate(
                angle: -0.78539816339,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: border,
                  size: 16,
                ),
              ),
            ),
            Transform.rotate(angle: -0.78539816339, child: burst),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedScoreBurst(String text) {
    final positive = _resultBurstPositive;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final opacity = (1 - (value * 0.15)).clamp(0.0, 1.0);

        if (positive) {
          final translateY = 18 - (26 * value);
          final scale = 0.78 + (0.34 * value);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        }

        final shakeX = math.sin(value * math.pi * 5) * (1 - value) * 14;
        final scale = 0.96 + ((1 - value) * 0.12);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(shakeX, value * 6),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: _buildScoreBurst(text),
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.lightBlue.shade300),
      ),
      child: Text(
        'Falling Modulo Mode',
        style: TextStyle(
          color: Colors.blueGrey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text('$label: $value'),
    );
  }

  Widget _buildFallingTile(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.indigo.shade400,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${_state.currentFallingValue}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBucket({
    required int index,
    required int value,
    required bool selected,
    required bool divisibleHint,
  }) {
    final base = selected ? Colors.orange.shade200 : Colors.white;
    final hintColor = divisibleHint ? Colors.green.shade100 : base;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hintColor,
        border: Border.all(
          color: selected ? Colors.deepOrange : Colors.black26,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '$index',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
