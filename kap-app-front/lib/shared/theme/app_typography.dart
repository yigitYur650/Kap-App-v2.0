import 'package:flutter/material.dart';

/// Design system typography tokens mapping standard typographic scales.
class AppTypography {
  static const display = TextStyle(
    fontSize: 48.0,
    fontWeight: FontWeight.w700, // bold
    height: 1.15,
  );

  static const headline = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700, // bold
    height: 1.25,
  );

  static const title = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600, // semibold
    height: 1.4,
  );

  static const body = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
  );

  static const label = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500, // medium
    height: 1.38,
  );
}
