import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kCrimson = Color(0xFF290806);
const Color kCrimsonDark = Color(0xFF230403);
const Color kCrimsonMid = Color(0xFF391411);
const Color kCrimsonLight = Color(0xFF532824);
const Color kGold = Color(0xFFE9C349);
const Color kCream = Color(0xFFD4C6A0);
const Color kOnSurface = Color(0xFFFFDAD6);

const artDecoColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB4AA),
  onPrimary: Color(0xFF5F1410),
  primaryContainer: Color(0xFF4A0404),
  onPrimaryContainer: Color(0xFFD26A5F),
  secondary: kGold,
  onSecondary: Color(0xFF3C2F00),
  secondaryContainer: Color(0xFFAF8D11),
  onSecondaryContainer: Color(0xFF342800),
  tertiary: kCream,
  onTertiary: Color(0xFF383015),
  tertiaryContainer: Color(0xFFB8AB86),
  onTertiaryContainer: Color(0xFF483F22),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: kCrimson,
  onSurface: kOnSurface,
  onSurfaceVariant: Color(0xFFDCC0BD),
  outline: Color(0xFFA38B88),
  outlineVariant: Color(0xFF554240),
  inverseSurface: kOnSurface,
  onInverseSurface: Color(0xFF4E2420),
  inversePrimary: Color(0xFF9D4139),
  surfaceTint: Color(0xFFFFB4AA),
);

ThemeData artDecoTheme() {
  return ThemeData(
    colorScheme: artDecoColorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: kCrimson,
    appBarTheme: AppBarTheme(
      backgroundColor: kCrimsonDark,
      foregroundColor: kGold,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poiretOne(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 20 * 0.05,
        color: kGold,
      ),
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: kGold,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kCrimsonMid,
      contentTextStyle: GoogleFonts.libreFranklin(
        color: kOnSurface,
        fontSize: 14,
      ),
    ),
  );
}
