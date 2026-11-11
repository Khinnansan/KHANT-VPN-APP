import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final proxies = ref.watch(proxiesOverviewNotifierProvider);
    final sortBy = ref.watch(proxiesSortNotifierProvider);

    // final selectActiveProxyMutation = useMutation(
    //   initialOnFailure: (error) => CustomToast.error(t.presentShortError(error)).show(context),
    // );

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        surfaceTintColor: Colors.transparent,
        title: Text(t.pages.proxies.title, style: const TextStyle(color: Color(0xFFFFD36A), fontWeight: FontWeight.w900, letterSpacing: .5)),
        actions: [
          IconButton(
            tooltip: t.connection.tapToRetry,
            onPressed: () => ref.invalidate(proxiesOverviewNotifierProvider),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFC857)),
          ),
          PopupMenuButton<ProxiesSort>(
            initialValue: sortBy,
            onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
            icon: const Icon(FluentIcons.arrow_sort_24_regular, color: Color(0xFFFFC857)),
            tooltip: t.pages.proxies.sort,
            itemBuilder: (context) {
              return [...ProxiesSort.values.map((e) => PopupMenuItem(value: e, child: Text(e.present(t))))];
            },
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC857),
        foregroundColor: const Color(0xFF17110A),
        onPressed: () async => await ref.read(proxiesOverviewNotifierProvider.notifier).urlTest("select"),
        tooltip: t.pages.proxies.testDelay,
        child: const Icon(FluentIcons.flash_24_filled),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF080705), Color(0xFF030303), Color(0xFF000000)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(left: 0, right: 0, bottom: 0, height: 180, child: IgnorePointer(child: CustomPaint(painter: _ProxyGoldWavePainter()))),
            proxies.when(
        data: (group) => group != null
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = PlatformUtils.isMobile && width < 600 ? 1 : max(1, (width / 268).floor());
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 112),
                    itemCount: group.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisExtent: 96,
                    ),
                    itemBuilder: (context, index) {
                      final proxy = group.items[index];
                      return ProxyTile(
                        proxy,
                        selected: group.selected == proxy.tag,
                        onTap: () async {
                          await ref.read(proxiesOverviewNotifierProvider.notifier).changeProxy(group.tag, proxy.tag);
                        },
                      );
                    },
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    ref.watch(serviceRunningProvider) ? t.pages.proxies.empty : t.pages.proxies.connectToSeeProxies,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.pages.proxies.loadFailed, textAlign: TextAlign.center),
                const Gap(12),
                TextButton(
                  onPressed: () => ref.invalidate(proxiesOverviewNotifierProvider),
                  child: Text(t.connection.tapToRetry),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
          ],
        ),
      ),
    );
  }
}

class _ProxyGoldWavePainter extends CustomPainter {
  const _ProxyGoldWavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = const Color(0xFFFFB51B).withValues(alpha: .09)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .55, size.height * .95), width: size.width * .9, height: 55), glow);
    for (var i = 0; i < 9; i++) {
      final path = Path()
        ..moveTo(size.width * (.02 + i * .018), size.height * (1.08 - i * .025))
        ..cubicTo(size.width * .30, size.height * (.76 - i * .018), size.width * .72, size.height * (1.16 - i * .02), size.width * (1.08 - i * .012), size.height * (.28 + i * .04));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = i == 0 ? 1.8 : .7..color = const Color(0xFFFFC84A).withValues(alpha: i == 0 ? .52 : .12));
    }
  }
  @override
  bool shouldRepaint(covariant _ProxyGoldWavePainter oldDelegate) => false;
}
