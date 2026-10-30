import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/widgets/dismiss_keyboard.dart';

/// A touch anywhere that is not a text field closes the keyboard, including on chips and buttons,
/// which claim the tap for themselves (the app wraps every route in DismissKeyboard).
void main() {
  var pressed = 0;
  var chipOn = false;

  Future<void> pump(WidgetTester tester) async {
    pressed = 0;
    chipOn = false;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => DismissKeyboard(child: child!),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Column(children: [
            const TextField(key: Key('field')),
            const TextField(key: Key('other')),
            FilterChip(
              key: const Key('chip'),
              label: const Text('Before food'),
              selected: chipOn,
              onSelected: (on) => setState(() => chipOn = on),
            ),
            FilledButton(key: const Key('button'), onPressed: () => pressed++, child: const Text('Go')),
            const Expanded(child: SizedBox.expand()),
          ]),
        ),
      ),
    ));
  }

  bool fieldFocused() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>() != null;

  Future<void> focusField(WidgetTester tester, [String key = 'field']) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    expect(fieldFocused(), isTrue);
  }

  testWidgets('tapping empty space drops the focus from a field', (tester) async {
    await pump(tester);
    await focusField(tester);
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(fieldFocused(), isFalse);
  });

  testWidgets('tapping a chip drops the focus and the chip still selects', (tester) async {
    await pump(tester);
    await focusField(tester);
    await tester.tap(find.byKey(const Key('chip')));
    await tester.pump();
    expect(fieldFocused(), isFalse);
    expect(chipOn, isTrue);
  });

  testWidgets('tapping a button drops the focus and the button still works', (tester) async {
    await pump(tester);
    await focusField(tester);
    await tester.tap(find.byKey(const Key('button')));
    await tester.pump();
    expect(fieldFocused(), isFalse);
    expect(pressed, 1);
  });

  testWidgets('tapping inside the field keeps the focus, and another field takes it over', (tester) async {
    await pump(tester);
    await focusField(tester);
    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(fieldFocused(), isTrue);

    await focusField(tester, 'other');
    final focused = FocusManager.instance.primaryFocus!.context!.findAncestorWidgetOfExactType<TextField>()!;
    expect(focused.key, const Key('other'));
  });
}
