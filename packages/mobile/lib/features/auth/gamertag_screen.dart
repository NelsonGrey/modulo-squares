import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modulo_squares/core/services/gamertag_service.dart';

const _kBg = Color(0xFF1A1A2E);
const _kSurface = Color(0xFF16213E);
const _kAccent = Color(0xFF4CAF50);

class GamertagScreen extends StatefulWidget {
  const GamertagScreen({super.key, required this.onGamertagSet});

  final VoidCallback onGamertagSet;

  @override
  State<GamertagScreen> createState() => _GamertagScreenState();
}

class _GamertagScreenState extends State<GamertagScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  String? _validationError;
  bool? _isAvailable;
  bool _checkingAvailability = false;
  bool _saving = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final error = GamertagService.validate(value);
    setState(() {
      _validationError = error;
      _isAvailable = null;
    });
    if (error != null || value.isEmpty) return;

    setState(() => _checkingAvailability = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final available = await GamertagService.isAvailable(value);
      if (mounted) {
        setState(() {
          _isAvailable = available;
          _checkingAvailability = false;
        });
      }
    });
  }

  Future<void> _save() async {
    final tag = _controller.text.trim();
    final error = GamertagService.validate(tag);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    if (_isAvailable == false) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await GamertagService.setGamertag(uid, tag);
      widget.onGamertagSet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save gamertag. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvailabilityIndicator() {
    if (_controller.text.isEmpty || _validationError != null) {
      return const SizedBox.shrink();
    }
    if (_checkingAvailability) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
      );
    }
    if (_isAvailable == true) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: _kAccent, size: 16),
          SizedBox(width: 4),
          Text('Available', style: TextStyle(color: _kAccent, fontSize: 12)),
        ],
      );
    }
    if (_isAvailable == false) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, color: Colors.redAccent, size: 16),
          SizedBox(width: 4),
          Text('Already taken', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  bool get _canSave {
    return _validationError == null &&
        _isAvailable == true &&
        !_checkingAvailability &&
        !_saving &&
        _controller.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Image.asset('assets/icons/icon.png', width: 72, height: 72),
              const SizedBox(height: 12),
              const Text(
                'Modulo Squares',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Choose Your Gamertag',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is the name displayed on the leaderboard — not your email address.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 24),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: _kAccent,
                    onSurface: Colors.white,
                    surface: _kSurface,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  maxLength: 20,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  onChanged: _onChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Gamertag',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: 'e.g. MathWizard42',
                    hintStyle: const TextStyle(color: Colors.white30),
                    errorText: _validationError,
                    counterStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: _kSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kAccent, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildAvailabilityIndicator(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '3–20 characters · letters, numbers, and underscores only',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withValues(alpha: 0.35),
                  border: Border.all(color: Colors.orange.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offensive, hateful, or inappropriate gamertags are '
                        'immediately removed. Accounts with repeated violations '
                        'are permanently banned.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 16),
                const Text(
                  'You are playing as a guest. Your progress will not be saved if you uninstall the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
