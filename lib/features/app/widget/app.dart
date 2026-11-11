import 'dart:async';

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/app_based_routing/overview/app_based_routing_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/connection/widget/connection_wrapper.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/shortcut/shortcut_wrapper.dart';
import 'package:hiddify/features/system_tray/notifier/system_tray_notifier.dart';
import 'package:hiddify/features/window/widget/window_wrapper.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upgrader/upgrader.dart';

bool _debugAccessibility = false;
bool isOnPauseCalled = false;

class App extends HookConsumerWidget with WidgetsBindingObserver, PresLogger {
  const App({super.key});

  void onPause(WidgetRef ref) {
    if (PlatformUtils.isDesktop) return;
    isOnPauseCalled = true;
    ref.read(hiddifyCoreServiceProvider).closeFront();
  }

  void onResume(WidgetRef ref) {
    // if (PlatformUtils.isDesktop) return;
    ref.read(hiddifyCoreServiceProvider).init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isOnPauseCalled && PlatformUtils.isAndroid) ref.invalidate(appBasedRoutingProvider);
      isOnPauseCalled = false;
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    setupStateListener(ref);
    final showLaunchSplash = useState(true);
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 2200), () {
        showLaunchSplash.value = false;
      });
      return timer.cancel;
    }, const []);
    final router = ref.watch(goRouterNotiferProvider);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);
    final theme = AppTheme(themeMode, locale.preferredFontFamily);
    final upgrader = ref.watch(upgraderProvider);
    final activeBreakpoint = Breakpoint(context).activeBreakpoint;

    ref.listen(foregroundProfilesUpdateNotifierProvider, (_, _) {});
    if (PlatformUtils.isAndroid) ref.listen(appBasedRoutingProvider, (_, _) {});
    if (PlatformUtils.isDesktop) ref.listen(systemTrayNotifierProvider, (_, _) {});

    // updating ActiveBreakpointNotifier value
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeBreakpointNotifierProvider.notifier).update(activeBreakpoint);
      });
      return null;
    }, [activeBreakpoint]);
    return WindowWrapper(
      ShortcutWrapper(
        ConnectionWrapper(
          DynamicColorBuilder(
            builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
              return MaterialApp.router(
                routerConfig: router,
                scaffoldMessengerKey: appScaffoldMessengerKey,
                locale: locale.flutterLocale,
                supportedLocales: const [Locale("my"), Locale("en")],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                debugShowCheckedModeBanner: false,
                themeMode: themeMode.flutterThemeMode,
                theme: theme.lightTheme(lightColorScheme),
                darkTheme: theme.darkTheme(darkColorScheme),
                title: Constants.appName,
                builder: (context, child) {
                  final theme = Theme.of(context);
                  child = SnackBarHost(
                    child: UpgradeAlert(
                      upgrader: upgrader,
                      navigatorKey: router.routerDelegate.navigatorKey,
                      child: child ?? const SizedBox(),
                    ),
                  );
                  child = Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      if (showLaunchSplash.value) const _KhantLaunchSplash(),
                    ],
                  );
                  if (kDebugMode && _debugAccessibility) {
                    return AccessibilityTools(checkFontOverflows: true, child: child);
                  }
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: Colors.black,
                      statusBarIconBrightness: Brightness.light,
                      systemNavigationBarIconBrightness: Brightness.light,
                    ),
                    child: child,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // @override
  // Widget build1(BuildContext context, WidgetRef ref) {
  //   setupStateListener(ref);
  //   // setupQuickSettings(ref);
  //   final router = ref.watch(routerProvider);
  //   final locale = ref.watch(localePreferencesProvider);
  //   final themeMode = ref.watch(themePreferencesProvider);
  //   final theme = AppTheme(themeMode, locale.preferredFontFamily);
  //   final upgrader = ref.watch(upgraderProvider);

  //   ref.listen(foregroundProfilesUpdateNotifierProvider, (_, __) {});

  //   return WindowWrapper(
  //     TrayWrapper(
  //       ShortcutWrapper(
  //         ConnectionWrapper(
  //           PlatformProvider(
  //               settings: PlatformSettingsData(
  //                 iosUsesMaterialWidgets: true,
  //               ),
  //               builder: (context) => DynamicColorBuilder(
  //                     builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
  //                       return PlatformApp.router(
  //                         routerConfig: router,
  //                         locale: locale.flutterLocale,
  //                         supportedLocales: AppLocaleUtils.supportedLocales,
  //                         localizationsDelegates: GlobalMaterialLocalizations.delegates,
  //                         debugShowCheckedModeBanner: false,
  //                         material: (context, platform) => MaterialAppRouterData(
  //                           theme: theme.lightTheme(lightColorScheme),
  //                           darkTheme: theme.darkTheme(darkColorScheme),
  //                           themeMode: themeMode.flutterThemeMode,
  //                         ),
  //                         cupertino: (context, platform) {
  //                           final sysDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

  //                           return CupertinoAppRouterData(theme: theme.cupertinoThemeData(sysDark, lightColorScheme, darkColorScheme));
  //                         },
  //                         title: Constants.appName,
  //                         builder: (context, child) {
  //                           child = UpgradeAlert(
  //                             upgrader: upgrader,
  //                             navigatorKey: router.routerDelegate.navigatorKey,
  //                             child: child ?? const SizedBox(),
  //                           );
  //                           if (kDebugMode && _debugAccessibility) {
  //                             return AccessibilityTools(
  //                               checkFontOverflows: true,
  //                               child: child,
  //                             );
  //                           }
  //                           return child;
  //                         },
  //                       );
  //                     },
  //                   )),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void setupStateListener(WidgetRef ref) {
    useEffect(() {
      // The engine calls the listener directly, so a pause is seen even when no frame is drawn in the
      // background. Inactive (a dialog, the notification shade) is not a pause and closes nothing.
      // On desktop a window losing focus is inactive too, so coming back from inactive alone sets
      // nothing up again: doing it on every focus change reconnected to the core, reloaded what
      // watches it, and made the home page blink.
      var away = true;
      void handle(AppLifecycleState state) {
        loggy.info("app state: $state");
        if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) away = true;
        if (state == AppLifecycleState.paused) onPause(ref);
        if (state == AppLifecycleState.resumed && away) {
          away = false;
          onResume(ref);
        }
      }

      final initial = WidgetsBinding.instance.lifecycleState;
      if (initial != null) handle(initial);
      final listener = AppLifecycleListener(onStateChange: handle);
      return listener.dispose;
    }, const []);
  }
}


class _KhantLaunchSplash extends StatelessWidget {
  const _KhantLaunchSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF000000),
      child: Material(
        color: Color(0xFF000000),
        child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFFFFD36A), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x66FFC247), blurRadius: 13, spreadRadius: 1),
              BoxShadow(color: Color(0x22FFC247), blurRadius: 28, spreadRadius: 3),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final emblemSize = (constraints.maxWidth * .68).clamp(190.0, 310.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  SizedBox(
                    width: emblemSize,
                    height: emblemSize,
                    child: const CustomPaint(painter: _KhantLaunchLogoPainter()),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'KHANT VPN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFD46B),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.2,
                      shadows: [Shadow(color: Color(0xFFFFB52E), blurRadius: 16)],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'PREMIUM PRIVATE NETWORK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE5D8BE),
                      fontSize: 12,
                      letterSpacing: 2.1,
                    ),
                  ),
                  const Spacer(flex: 2),
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFFC64D)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const Spacer(flex: 3),
                ],
              );
            },
          ),
          ),
        ),
      ),
    );
  }
}

class _KhantLaunchLogoPainter extends CustomPainter {
  const _KhantLaunchLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide * .43;
    final gold = const Color(0xFFFFC342);

    canvas.drawCircle(
      center,
      r * 1.28,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x66FFB51B), const Color(0x22FFB51B), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.3)),
    );
    for (var i = 0; i < 48; i++) {
      final angle = i * 3.141592653589793 * 2 / 48;
      final start = center + Offset.fromDirection(angle, r * 1.02);
      final end = center + Offset.fromDirection(angle, r * (1.13 + (i % 4) * .045));
      canvas.drawLine(
        start,
        end,
        Paint()
          ..strokeWidth = i % 4 == 0 ? 1.8 : 1
          ..color = gold.withValues(alpha: i % 4 == 0 ? .7 : .28),
      );
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = gold.withValues(alpha: .92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFFFF0B2),
    );

    final k = r / 54;
    final mark = Path()
      ..moveTo(center.dx - 17 * k, center.dy - 31 * k)
      ..lineTo(center.dx - 3 * k, center.dy - 31 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 4 * k)
      ..lineTo(center.dx + 23 * k, center.dy - 31 * k)
      ..lineTo(center.dx + 42 * k, center.dy - 31 * k)
      ..cubicTo(center.dx + 29 * k, center.dy - 20 * k, center.dx + 17 * k, center.dy - 9 * k, center.dx + 4 * k, center.dy + 2 * k)
      ..lineTo(center.dx + 34 * k, center.dy + 31 * k)
      ..lineTo(center.dx + 15 * k, center.dy + 31 * k)
      ..lineTo(center.dx - 11 * k, center.dy + 8 * k)
      ..lineTo(center.dx - 15 * k, center.dy + 31 * k)
      ..lineTo(center.dx - 29 * k, center.dy + 31 * k)
      ..lineTo(center.dx - 24 * k, center.dy + 2 * k)
      ..lineTo(center.dx - 43 * k, center.dy - 31 * k)
      ..lineTo(center.dx - 25 * k, center.dy - 31 * k)
      ..lineTo(center.dx - 12 * k, center.dy - 10 * k)
      ..close();

    canvas.drawPath(
      mark,
      Paint()
        ..color = const Color(0xFFFFC43D).withValues(alpha: .55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );
    canvas.drawPath(
      mark,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBE0),
            Color(0xFFFFD85A),
            Color(0xFFE69A08),
            Color(0xFFFFEAA0),
            Color(0xFF9C5A00),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * .75)),
    );

    final swoosh = Path()
      ..moveTo(center.dx - 39 * k, center.dy + 23 * k)
      ..cubicTo(center.dx - 14 * k, center.dy + 5 * k, center.dx + 16 * k, center.dy + 9 * k, center.dx + 39 * k, center.dy - 25 * k)
      ..cubicTo(center.dx + 23 * k, center.dy + 7 * k, center.dx - 10 * k, center.dy + 35 * k, center.dx - 39 * k, center.dy + 23 * k);
    canvas.drawPath(
      swoosh,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * k
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFD45A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      swoosh,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7 * k
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF2C0),
    );

    final crown = Path()
      ..moveTo(center.dx - 16 * k, center.dy - 37 * k)
      ..lineTo(center.dx - 21 * k, center.dy - 55 * k)
      ..lineTo(center.dx - 8 * k, center.dy - 46 * k)
      ..lineTo(center.dx, center.dy - 59 * k)
      ..lineTo(center.dx + 8 * k, center.dy - 46 * k)
      ..lineTo(center.dx + 21 * k, center.dy - 55 * k)
      ..lineTo(center.dx + 16 * k, center.dy - 37 * k)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD45A));
    canvas.drawLine(
      Offset(center.dx - 17 * k, center.dy - 35 * k),
      Offset(center.dx + 17 * k, center.dy - 35 * k),
      Paint()
        ..strokeWidth = 3 * k
        ..color = const Color(0xFFFFF0B2),
    );
    for (final dx in [-21.0, 0.0, 21.0]) {
      canvas.drawCircle(
        Offset(center.dx + dx * k, center.dy + (dx == 0 ? -59 : -55) * k),
        2.5 * k,
        Paint()..color = const Color(0xFFFFF0B2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
