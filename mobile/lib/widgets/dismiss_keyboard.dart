import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A touch anywhere that is not on a text field closes the keyboard and drops the focus. Wrapped once
/// around the whole app (`MaterialApp.builder`), so no screen has to do it and a field added later
/// behaves the same way.
///
/// It reacts to the touch going down rather than to a finished tap. A chip, a button or a list row
/// claims the tap for itself, so a tap-based wrapper never saw those and the field kept its focus.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      child: child,
    );
  }

  static void _onPointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    final onText = result.path.any((entry) => entry.target is RenderEditable);
    if (!onText) focus.unfocus();
  }
}

/// `MaterialApp.builder` for the whole app, so the real app and the widget tests wrap every route the same way.
Widget dismissKeyboardBuilder(BuildContext context, Widget? child) => DismissKeyboard(child: child ?? const SizedBox.shrink());
