// lib/core/utils/color_extensions.dart
import 'package:flutter/material.dart';

extension ColorToCss on Color {
  /// Converts a Flutter Color to a CSS rgba(r,g,b,a) string.
  String toCssRgbaString() {
    return 'rgba($red, $green, $blue, $opacity)';
  }

  /// Converts a Flutter Color to a CSS hex #RRGGBB string.
  /// Alpha is ignored in this hex representation.
  String toCssHexString() {
    // Get the hex string, AARRGGBB format
    String hex = value.toRadixString(16).padLeft(8, '0');
    // Return the RRGGBB part
    return '#${hex.substring(2)}';
  }

  /// Converts a Flutter Color to a CSS hex #RRGGBBAA string if alpha is not 255,
  /// otherwise returns #RRGGBB.
  String toCssHexWithAlphaString() {
    if (alpha == 255) {
      return toCssHexString(); // No alpha needed if fully opaque
    }
    // Get the hex string, AARRGGBB format, and rearrange to RRGGBBAA for CSS
    String alphaHex = alpha.toRadixString(16).padLeft(2, '0');
    String colorHex =
        value.toRadixString(16).padLeft(8, '0').substring(2); // RRGGBB
    return '#$colorHex$alphaHex';
  }
}
