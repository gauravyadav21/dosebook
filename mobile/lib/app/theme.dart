import 'package:flutter/material.dart';

import 'contrast.dart';
import 'tokens.dart';

/// The one seed every colour in the app is derived from. A calm teal: clinical enough to trust,
/// warm enough not to feel like a hospital form.
const seed = Color(0xFF0F766E);

/// Colours for the state of a dose. Taken, due, skipped and missed need to be told apart at a glance,
/// so they are not left to primary and grey. Derived from the scheme so dark mode follows.
@immutable
class DoseColors extends ThemeExtension<DoseColors> {
  const DoseColors({
    required this.taken,
    required this.takenContainer,
    required this.due,
    required this.dueContainer,
    required this.skipped,
    required this.skippedContainer,
  });

  final Color taken;
  final Color takenContainer;
  final Color due;
  final Color dueContainer;
  final Color skipped;
  final Color skippedContainer;

  factory DoseColors.of(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    final takenBg = dark ? const Color(0xFF123B28) : const Color(0xFFD4F0E0);
    final dueBg = dark ? const Color(0xFF3F2E0A) : const Color(0xFFFFEBC8);
    return DoseColors(
      taken: ensureContrast(dark ? const Color(0xFF7DD3A8) : const Color(0xFF1B6B45), takenBg),
      takenContainer: takenBg,
      due: ensureContrast(dark ? const Color(0xFFF5C26B) : const Color(0xFF8A5A00), dueBg),
      dueContainer: dueBg,
      skipped: s.onSurfaceVariant,
      skippedContainer: s.surfaceContainerHighest,
    );
  }

  @override
  DoseColors copyWith({
    Color? taken,
    Color? takenContainer,
    Color? due,
    Color? dueContainer,
    Color? skipped,
    Color? skippedContainer,
  }) => DoseColors(
    taken: taken ?? this.taken,
    takenContainer: takenContainer ?? this.takenContainer,
    due: due ?? this.due,
    dueContainer: dueContainer ?? this.dueContainer,
    skipped: skipped ?? this.skipped,
    skippedContainer: skippedContainer ?? this.skippedContainer,
  );

  @override
  DoseColors lerp(DoseColors? other, double t) {
    if (other == null) return this;
    return DoseColors(
      taken: Color.lerp(taken, other.taken, t)!,
      takenContainer: Color.lerp(takenContainer, other.takenContainer, t)!,
      due: Color.lerp(due, other.due, t)!,
      dueContainer: Color.lerp(dueContainer, other.dueContainer, t)!,
      skipped: Color.lerp(skipped, other.skipped, t)!,
      skippedContainer: Color.lerp(skippedContainer, other.skippedContainer, t)!,
    );
  }
}

extension DoseColorsOnTheme on ThemeData {
  DoseColors get dose => extension<DoseColors>() ?? DoseColors.of(colorScheme);
}

/// Light or dark theme from the same seed. Screens read colours, type and shapes from the theme and never fix their own.
ThemeData appTheme(Brightness brightness) {
  final generated = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  // The generated primary and error reach AA but not AAA against their label colour. Button
  // labels and error text are important text (7:1), so lift those two roles; the hue stays.
  final scheme = generated.copyWith(
    primary: ensureContrast(generated.primary, generated.onPrimary),
    error: ensureContrast(generated.error, generated.onError),
  );
  final base = ThemeData(colorScheme: scheme, brightness: brightness, useMaterial3: true);

  // A real hierarchy: the default scale has everything at one weight, so screens read flat.
  final text = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
  );

  const buttonShape = StadiumBorder();
  const buttonPadding = EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm);

  return base.copyWith(
    textTheme: text,
    extensions: [DoseColors.of(scheme)],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: Corner.card,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: buttonShape, padding: buttonPadding, minimumSize: const Size(0, Space.tapTarget)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: buttonShape, padding: buttonPadding, minimumSize: const Size(0, Space.tapTarget)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: buttonShape, minimumSize: const Size(0, Space.tapTarget)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: Corner.card),
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
      border: OutlineInputBorder(borderRadius: Corner.card, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: Corner.card, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: Corner.card,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: Corner.card,
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: Corner.card,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelLarge,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: Corner.sheet),
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: Corner.card),
    ),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: Space.md)),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: Space.lg),
    tabBarTheme: TabBarThemeData(
      dividerColor: scheme.outlineVariant,
      labelStyle: text.titleSmall,
      unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}

/// The brand colours: the light scheme, in both modes. Used by the logo and the splash so that
/// the start of the app matches the Android launch screen whatever the theme (S12).
final brandScheme = ColorScheme.fromSeed(seedColor: seed);
