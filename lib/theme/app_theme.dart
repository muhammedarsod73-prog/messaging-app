import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ChatWallpaperStyle {
  whatsappDark,
  whatsappEmerald,
  solidMidnight,
  deepCharcoal,
  lightDoodle,
}

class AppTheme {
  // WhatsApp Signature Colors
  static const Color tealHeader = Color(0xFF075E54);
  static const Color tealPrimary = Color(0xFF128C7E);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappAccent = Color(0xFF00A884);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111B21);
  static const Color darkCardColor = Color(0xFF202C33);
  static const Color darkAppBar = Color(0xFF202C33);
  static const Color darkSentBubble = Color(0xFF005C4B);
  static const Color darkReceivedBubble = Color(0xFF202C33);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFE5DDD5);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightAppBar = Color(0xFF075E54);
  static const Color lightSentBubble = Color(0xFFE7FFDB);
  static const Color lightReceivedBubble = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111B21);
  static const Color lightTextSecondary = Color(0xFF667781);

  // Read Ticks
  static const Color tickBlue = Color(0xFF53BDEB);
  static const Color tickGrey = Color(0xFF8696A0);

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: whatsappAccent,
        secondary: tealPrimary,
        surface: darkCardColor,
        background: darkBackground,
        onSurface: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBar,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        actionsIconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardColor: darkCardColor,
      dividerColor: Color(0xFF222D34),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: const TextStyle(color: darkTextPrimary),
        bodySmall: const TextStyle(color: darkTextSecondary),
      ),
    );
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: tealHeader,
        secondary: whatsappGreen,
        surface: lightCardColor,
        background: lightBackground,
        onSurface: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightAppBar,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardColor: lightCardColor,
      dividerColor: Color(0xFFE9EDEF),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        bodyMedium: const TextStyle(color: lightTextPrimary),
        bodySmall: const TextStyle(color: lightTextSecondary),
      ),
    );
  }

  // Helper for wallpaper colors
  static Color getWallpaperBackgroundColor(ChatWallpaperStyle style, bool isDark) {
    switch (style) {
      case ChatWallpaperStyle.whatsappDark:
        return const Color(0xFF0B141A);
      case ChatWallpaperStyle.whatsappEmerald:
        return const Color(0xFF062326);
      case ChatWallpaperStyle.solidMidnight:
        return const Color(0xFF101921);
      case ChatWallpaperStyle.deepCharcoal:
        return const Color(0xFF181818);
      case ChatWallpaperStyle.lightDoodle:
        return const Color(0xFFE5DDD5);
    }
  }
}
