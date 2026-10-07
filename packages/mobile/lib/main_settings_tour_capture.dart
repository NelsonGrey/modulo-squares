import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'main_store_capture.dart' as store;

/// Local recording entry point that demonstrates the production Appearance and
/// Difficulty settings without authentication, analytics, ads, or network IO.
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

/// Scrolls the Settings page until the [label] text is on screen.
Future<void> _reveal(String label) async {
  Element? target;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data == label) target = element;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  if (target == null) throw StateError('Capture control not found');
  await Scrollable.ensureVisible(
    target!,
    duration: const Duration(milliseconds: 400),
  );
  await _wait(650);
}

Future<void> _tour() async {
  await _wait(5500);
  await _tap((widget) => widget is IconButton && widget.tooltip == 'Settings');
  await _wait(2500);
  await _text('Arcade Neon');
  await _wait(2200);
  await _reveal('Hard');
  await _wait(1800);
  await _text('Hard');
  await _wait(2200);
  await _tap((widget) => widget is BackButton);
  await _text('Resume');
  await _wait(9000);
  debugPrint('SETTINGS_TOUR_COMPLETE');
}
