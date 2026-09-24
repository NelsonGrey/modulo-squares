import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'main_store_capture.dart' as store;

/// Local media entry point that holds the pre-game screen, then opens the
/// production How to Play sheet for deterministic native screenshots.
Future<void> main() async {
  await store.main();
  unawaited(_openHowToPlay());
}

Future<void> _wait(int milliseconds) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

Future<void> _tapText(String label) async {
  Element? target;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data == label) target = element;
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
  if (target == null) throw StateError('Capture control not found: $label');
  final box = target!.findRenderObject()! as RenderBox;
  final position = box.localToGlobal(box.size.center(Offset.zero));
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(pointer: 1, position: position),
  );
  await _wait(80);
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(pointer: 1, position: position),
  );
}

Future<void> _openHowToPlay() async {
  await _wait(3000);
  await _tapText('How to Play');
  debugPrint('HOW_TO_PLAY_CAPTURE_READY');
}
