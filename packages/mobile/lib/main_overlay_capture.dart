import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'main_store_capture.dart' as store;

/// Local media entry point that exposes the current Pause, Settings, and
/// Purchases states at stable times while expert gameplay runs underneath.
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
  await _wait(6000);
  await _tap((widget) => widget is IconButton && widget.tooltip == 'Pause');
  await _wait(3800);
  await _text('Resume');
  await _wait(1400);
  await _tap((widget) => widget is IconButton && widget.tooltip == 'Settings');
  await _wait(3800);
  await _text('PURCHASES');
  debugPrint('PURCHASE_CAPTURE_READY');
}
