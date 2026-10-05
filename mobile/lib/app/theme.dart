import 'package:flutter/material.dart';

/// The one seed every colour in the app is derived from.
const seed = Colors.indigo;

/// Light or dark theme from the same seed. Screens read colours from the theme and never fix their own.
ThemeData appTheme(Brightness brightness) =>
    ThemeData(colorSchemeSeed: seed, brightness: brightness, useMaterial3: true);

/// The brand colours: the light scheme, in both modes. Used by the logo and the splash so that
/// the start of the app matches the Android launch screen whatever the theme (S12).
final brandScheme = ColorScheme.fromSeed(seedColor: seed);
