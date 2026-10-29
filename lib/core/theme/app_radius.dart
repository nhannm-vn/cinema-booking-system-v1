import 'package:flutter/material.dart';

/// Design tokens for Border Radius.
/// References: DESIGN_TOKENS.md Section 5
abstract final class AppRadius {
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double xl = 12.0;
  static const double full = 9999.0;

  // BorderRadius constants
  static const BorderRadius zeroRadius = BorderRadius.zero;
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(full));

  // BottomSheet and Dialog top rounded
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
