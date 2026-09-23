import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'main_store_capture.dart' as store;

/// Local recording only: taps the real settings controls and resumes gameplay.
/// Build with STORE_CAPTURE_EXPERT_DEMO=true and STORE_CAPTURE_THEME=deepOcean.
Future<void> main() async {
  await store.main();
  unawaited(_tour());
}

Future<void> _wait(int milliseconds) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

Future<void> _tap(bool Function(Widget) matches) async {
  Element? target;
  void visit(Element element) {
    if (matches(element.widget)) target = element;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  if (target == null) throw StateError('Capture control not found');
  final box = target!.findRenderObject()! as RenderBox;
  final position = box.localToGlobal(box.size.center(Offset.zero));
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(pointer: 1, position: position),
  );
  await _wait(80);
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(pointer: 1, position: position),
  );
  await _wait(650);
}

Future<void> _text(String label) =>
    _tap((widget) => widget is Text && widget.data == label);

Future<void> _tour() async {
  await _wait(6500);
  for (final name in [
    'Arcade Neon',
    'Warm Sunset',
    'Candy Pop',
    'Deep Ocean',
  ]) {
    await _tap(
      (widget) => widget is IconButton && widget.tooltip == 'Settings',
    );
    await _text('GAMEPLAY');
    await _text('APPEARANCE');
    await _wait(1800);
    await _text(name);
    await _wait(1000);
    await _text('Save');
    await _text('Resume');
    await _wait(6500);
  }
  debugPrint('PALETTE_TOUR_COMPLETE');
}
