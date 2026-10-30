
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);

  final AppThemeMode mode;
  final String fontFamily;

  static const Color gold = Color(0xFFFFC857);
  static const Color lightGold = Color(0xFFFFDFA0);
  static const Color black = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = (lightColorScheme ??
            ColorScheme.fromSeed(seedColor: gold))
        .copyWith(
      primary: gold,
      secondary: lightGold,
      onPrimary: black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light
      },
    );
  }

  ThemeData darkTheme(ColorScheme? darkColorScheme) {
    final ColorScheme scheme = (darkColorScheme ??
            ColorScheme.fromSeed(
              seedColor: gold,
              brightness: Brightness.dark,
            ))
        .copyWith(
      primary: gold,
      secondary: lightGold,
      surface: darkSurface,
      onPrimary: black,
      onSurface: Colors.white,
      outline: const Color(0xFF66512C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: black,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{
        ConnectionButtonTheme.light
      },
    );
  }

  CupertinoThemeData cupertinoThemeData(
    bool sysDark,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
  ) {
    final bool isDark = switch (mode) {
      AppThemeMode.system => sysDark,
      AppThemeMode.light => false,
      AppThemeMode.dark => true,
      AppThemeMode.black => true,
    };

    final def = CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: gold,
    );

    final defaultMaterialTheme =
        isDark ? darkTheme(darkColorScheme) : lightTheme(lightColorScheme);

    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(
              fontFamily: fontFamily,
            ),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            navLargeTitleTextStyle:
                def.textTheme.navLargeTitleTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            dateTimePickerTextStyle:
                def.textTheme.dateTimePickerTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(
              fontFamily: fontFamily,
            ),
          ),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
