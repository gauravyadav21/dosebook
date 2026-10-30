import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dosebook/app/contrast.dart';
import 'package:dosebook/app/theme.dart';

/// WCAG 2.x contrast. Every text-on-background pair the theme produces must reach AA (4.5:1);
/// text that matters (doses, warnings, errors, button labels) must reach AAA (7:1). Icons,
/// borders and focus rings need 3:1. Rules: docs/03-standards/ui-ux-rules.md.
double contrast(Color a, Color b) => contrastRatio(a, b);

typedef _Pair = (String, Color, Color);

void main() {
  for (final brightness in Brightness.values) {
    final theme = appTheme(brightness);
    final s = theme.colorScheme;
    final dose = theme.dose;
    final mode = brightness.name;

    // Text that matters: 7:1.
    final important = <_Pair>[
      ('onSurface on surface', s.onSurface, s.surface),
      ('onSurface on surfaceContainerLow (cards)', s.onSurface, s.surfaceContainerLow),
      ('onPrimary on primary (button labels)', s.onPrimary, s.primary),
      ('onPrimaryContainer on primaryContainer', s.onPrimaryContainer, s.primaryContainer),
      ('onError on error', s.onError, s.error),
      ('onErrorContainer on errorContainer (escalation, errors)', s.onErrorContainer, s.errorContainer),
      ('taken on takenContainer', dose.taken, dose.takenContainer),
      ('due on dueContainer', dose.due, dose.dueContainer),
    ];
    // Other text: 4.5:1.
    final normal = <_Pair>[
      ('onSurfaceVariant on surface', s.onSurfaceVariant, s.surface),
      ('onSurfaceVariant on surfaceContainerLow', s.onSurfaceVariant, s.surfaceContainerLow),
      ('onSurfaceVariant on surfaceContainer (nav bar)', s.onSurfaceVariant, s.surfaceContainer),
      ('onSurfaceVariant on surfaceContainerHighest (fields)', s.onSurfaceVariant, s.surfaceContainerHighest),
      ('onSecondaryContainer on secondaryContainer', s.onSecondaryContainer, s.secondaryContainer),
      ('onTertiaryContainer on tertiaryContainer', s.onTertiaryContainer, s.tertiaryContainer),
      ('onSecondary on secondary', s.onSecondary, s.secondary),
      ('onTertiary on tertiary', s.onTertiary, s.tertiary),
      ('primary on surface (text buttons, links)', s.primary, s.surface),
      ('secondary on surface', s.secondary, s.surface),
      ('tertiary on surface', s.tertiary, s.surface),
      ('error on surface', s.error, s.surface),
      ('skipped on skippedContainer', dose.skipped, dose.skippedContainer),
    ];
    // Icons, borders, focus rings: 3:1.
    final ui = <_Pair>[
      ('primary (focus ring, selected) on surface', s.primary, s.surface),
      ('outline (field border, divider icon) on surface', s.outline, s.surface),
    ];

    group('contrast ($mode)', () {
      for (final (name, fg, bg) in important) {
        test('AAA 7:1 $name', () => expect(contrast(fg, bg), greaterThanOrEqualTo(7.0), reason: name));
      }
      for (final (name, fg, bg) in normal) {
        test('AA 4.5:1 $name', () => expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name));
      }
      for (final (name, fg, bg) in ui) {
        test('3:1 $name', () => expect(contrast(fg, bg), greaterThanOrEqualTo(3.0), reason: name));
      }
    });
  }
}
