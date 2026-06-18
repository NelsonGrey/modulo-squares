import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:modulo_squares/core/di/service_locator.dart';
import 'package:modulo_squares/core/services/ad_service.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/models/falling_modulo_game_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FallingModuloGameScreen extends StatefulWidget {
  const FallingModuloGameScreen({super.key});

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
  bool _isRunning = false;
  bool _hasStarted = false;

  AdService? get _adServiceOrNull =>
      getIt.isRegistered<AdService>() ? getIt<AdService>() : null;

  PurchaseService? get _purchaseServiceOrNull =>
      getIt.isRegistered<PurchaseService>() ? getIt<PurchaseService>() : null;

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
      if (!mounted || !_isRunning) return;

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

  int get _effectiveDropIntervalMs => _state.dropIntervalMs;

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
    final previousLevel = _state.level;
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

    if (result.state.level > previousLevel) {
      setState(() {
        _isRunning = false;
      });

      unawaited(
        _showInterstitialTransition(trigger: 'level_complete', onClosed: () {}),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Level $previousLevel complete!')));
    }

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
      _isRunning = false;
      _hasStarted = false;
      _elapsed = Duration.zero;
      _spawnDelayRemaining = _spawnDelay;
      _lastInputAt = null;
      _resultBurstText = null;
    });
  }

  void _toggleRunning() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) _hasStarted = true;
    });
  }

  Future<void> _showInterstitialTransition({
    required String trigger,
    required VoidCallback onClosed,
  }) async {
    final adService = _adServiceOrNull;
    if (adService == null) {
      onClosed();
      return;
    }

    await adService.showInterstitial(
      trigger: trigger,
      levelNum: _state.level,
      onClosed: onClosed,
    );
  }

  Future<void> _openSettingsDialog() async {
    var localVisualCues = _state.visualCuesEnabled;
    final purchaseService = _purchaseServiceOrNull;
    var adsRemoved = purchaseService?.adsRemoved ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Settings'),
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ads'),
                    subtitle: Text(
                      adsRemoved
                          ? 'Removed for this account'
                          : 'Interstitial ads shown between every level',
                    ),
                    trailing: Icon(
                      adsRemoved ? Icons.check_circle : Icons.ads_click,
                      color: adsRemoved ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (purchaseService != null && !adsRemoved)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () async {
                          await purchaseService.purchaseAdRemoval();
                          setLocalState(() {
                            adsRemoved = purchaseService.adsRemoved;
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Purchase completed! Ads removed.'),
                            ),
                          );
                        },
                        child: Text(
                          'Remove Ads (${purchaseService.getProductPrice('remove_ads')})',
                        ),
                      ),
                    ),
                  if (purchaseService != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          await purchaseService.restorePurchases();
                          setLocalState(() {
                            adsRemoved = purchaseService.adsRemoved;
                          });
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Purchase restoration attempted.'),
                            ),
                          );
                        },
                        child: const Text('Restore Purchases'),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _startNewRun();
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
        title: const Text('Modulo Squares'),
        actions: [
          if (_isRunning)
            IconButton(
              tooltip: 'Pause',
              onPressed: _toggleRunning,
              icon: const Icon(Icons.pause),
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
              _buildHud(),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
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
                          left: 0,
                          right: 0,
                          bottom: 96,
                          child: _buildProgressGridOverlay(
                            totalWidth: constraints.maxWidth,
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
                    if (!_isRunning && !_hasStarted) _buildPreGameOverlay(),
                    if (!_isRunning && _hasStarted) _buildPauseOverlay(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _dropProgress),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 72,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? _moveLeft : null,
                        icon: const Icon(Icons.arrow_left, size: 32),
                        label: const Text(
                          'Left',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 72,
                      child: FilledButton.icon(
                        onPressed:
                            (_isRunning && !_isSpawnDelayActive)
                                ? _resolveCurrentTile
                                : null,
                        icon: const Icon(Icons.vertical_align_bottom, size: 28),
                        label: const Text(
                          'Drop',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 72,
                      child: ElevatedButton.icon(
                        onPressed: _isRunning ? _moveRight : null,
                        icon: const Icon(Icons.arrow_right, size: 32),
                        label: const Text(
                          'Right',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
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
          !_isRunning
              ? 'Paused'
              : _isSpawnDelayActive
              ? 'Ready...'
              : '${(_effectiveDropIntervalMs / 1000).toStringAsFixed(2)}s',
        ),
        _pill('Range', '${_state.numberRangeMin}-${_state.numberRangeMax}'),
        _pill(
          'Fill',
          '${_state.filledSquares}/${_state.progressGridCellCount}',
        ),
        if (_state.deficitSquares > 0)
          _pill('Deficit', '-${_state.deficitSquares}'),
      ],
    );
  }

  Widget _buildProgressGridOverlay({required double totalWidth}) {
    const int columns = 10;
    const int rows = 10;
    final filled = _state.filledSquares;
    final deficit = _state.deficitSquares;
    const double spacing = 2;

    final cellSize = ((totalWidth - (spacing * (columns - 1))) / columns).clamp(
      10.0,
      36.0,
    );
    final gridWidth = (cellSize * columns) + (spacing * (columns - 1));

    bool isFilledCell(int row, int col) {
      final orderFromBottomLeft = ((rows - 1 - row) * columns) + col;
      return orderFromBottomLeft < filled;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        key: const Key('progress-grid'),
        width: gridWidth,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows * columns,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ columns;
            final col = index % columns;
            final isDeficitCell = row == rows - 1 && col == 0 && deficit > 0;
            final filledCell = isFilledCell(row, col);

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    filledCell
                        ? Colors.lightGreen.shade300.withValues(alpha: 0.9)
                        : Colors.lightBlue.shade50.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.28),
                ),
              ),
              child:
                  isDeficitCell
                      ? Text(
                        '-$deficit',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: cellSize < 14 ? 7 : 9,
                        ),
                      )
                      : null,
            );
          },
        ),
      ),
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

  Widget _buildPreGameOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text(
                'Modulo Squares',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 24),
              _buildOverlayRule(
                Icons.arrow_downward,
                'A number falls — guide it left or right into a bucket',
              ),
              const SizedBox(height: 8),
              _buildOverlayRule(
                Icons.calculate_outlined,
                'Land it where the number is divisible by the bucket value',
              ),
              const SizedBox(height: 8),
              _buildOverlayRule(
                Icons.grid_on_outlined,
                'Fill 100 squares to level up — wrong buckets cost points',
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _toggleRunning,
                icon: const Icon(Icons.play_arrow, size: 22),
                label: const Text(
                  'Start Game',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 52),
                  backgroundColor: Colors.lightBlue.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showHowToPlaySheet,
                icon: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.lightBlue.shade200,
                ),
                label: Text(
                  'How to Play',
                  style: TextStyle(color: Colors.lightBlue.shade200),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildOverlayRule(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightBlue.shade200, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_filled_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paused',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Level ${_state.level}  ·  Score ${_state.score}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _toggleRunning,
              icon: const Icon(Icons.play_arrow, size: 22),
              label: const Text(
                'Resume',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(180, 52),
                backgroundColor: Colors.lightBlue.shade400,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _startNewRun,
              icon: const Icon(Icons.restart_alt, size: 20),
              label: const Text('New Game'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                minimumSize: const Size(180, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlaySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildHowToSection(
                        icon: Icons.arrow_downward,
                        title: 'The Falling Number',
                        body:
                            'Each round a number falls from the top. '
                            'Move it left or right before the timer drops it — '
                            'or tap Drop to send it down instantly.',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.inbox_outlined,
                        title: 'The Buckets',
                        body:
                            'Nine buckets sit at the bottom, each labelled 1–9. '
                            'Their positions are shuffled each level. '
                            'Land the tile where the number is exactly divisible '
                            'by the bucket value (remainder = 0).',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.calculate_outlined,
                        title: 'Scoring',
                        body:
                            'Success → earn falling number × bucket value points.\n\n'
                            'Miss → lose falling number × bucket value × remainder points.\n\n'
                            'Tip: bucket 1 always divides any number — but scores 0. '
                            'Use it to avoid a big penalty when no other bucket fits.',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.grid_on_outlined,
                        title: 'Level Progress',
                        body:
                            'Each successful match fills squares in the 10×10 grid. '
                            'Fill all 100 to complete the level. '
                            'Missed buckets create a deficit you must clear first.',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.bolt,
                        title: 'Combos & Speed',
                        body:
                            'Chain consecutive successful drops to build a combo. '
                            'At combo 3, 5, and 8 your move speed increases — '
                            'making it easier to line up the tile quickly.',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.visibility,
                        title: 'Visual Cues',
                        body:
                            'Green-highlighted buckets show valid landing spots for '
                            'the current tile. Toggle the hint via the eye icon in '
                            'the top bar.',
                      ),
                      const SizedBox(height: 20),
                      _buildHowToSection(
                        icon: Icons.trending_up,
                        title: 'Later Levels',
                        body:
                            'Each level raises the number range and speeds up the '
                            'fall timer. Higher numbers mean bigger rewards — and '
                            'bigger penalties for a miss.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blueGrey.shade700, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
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
