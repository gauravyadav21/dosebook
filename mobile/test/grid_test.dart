import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The 8-point grid guard. Spacing and radii come from `Space`, `Corner` and `Gap` in
/// `lib/app/tokens.dart`; a screen must not write its own number. This counts the raw numbers
/// per file and fails if a file has more than `test/grid_baseline.txt` allows. The baseline
/// only goes down: when a screen is moved onto the tokens, lower its line (or delete it).
/// Rules: docs/03-standards/ui-ux-rules.md.
final _raw = RegExp(
  r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]*\d'
  r'|SizedBox\((?:width|height): \d'
  r'|(?:BorderRadius|Radius)\.circular\(\d',
);

void main() {
  final baseline = <String, int>{};
  final file = File('test/grid_baseline.txt');
  if (file.existsSync()) {
    for (final line in file.readAsLinesSync()) {
      final parts = line.split(' ');
      if (parts.length == 2) baseline[parts[0]] = int.parse(parts[1]);
    }
  }

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('app/tokens.dart') && !f.path.endsWith('app/theme.dart'));

  for (final f in files) {
    test('no new raw spacing in ${f.path}', () {
      final count = _raw.allMatches(f.readAsStringSync()).length;
      final allowed = baseline[f.path] ?? 0;
      expect(count, lessThanOrEqualTo(allowed),
          reason: '${f.path} has $count raw spacing/radius numbers, baseline allows $allowed. Use Space/Corner/Gap.');
    });
  }
}
