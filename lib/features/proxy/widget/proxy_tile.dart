import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2B2111) : const Color(0xFF15130F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFFFFC857) : const Color(0xFF6D572F).withValues(alpha: .35),
        ),
      ),
      child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        proxy.nameWithDetour,
        overflow: TextOverflow.ellipsis,
        style: (PlatformUtils.isWindows ? const TextStyle(fontFamily: FontFamily.emoji) : const TextStyle()).copyWith(
          color: selected ? const Color(0xFFFFE3A0) : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: IPCountryFlag(
        countryCode: proxy.ipinfo.countryCode,
        organization: proxy.ipinfo.org,
        size: 40,
        padding: const EdgeInsetsDirectional.only(end: 8),
      ),
      subtitle: Text.rich(
        TextSpan(
          text: proxy.type,
          children: [
            if (proxy.isGroup)
              TextSpan(
                text: ' (${proxy.groupSelectedTagDisplay.trim()})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        children: [
          if (proxy.urlTestDelay != 0)
            Text(
              ConnectionConst.isValidDelay(proxy.urlTestDelay) ? '${proxy.urlTestDelay} ms' : "×",
              style: TextStyle(color: delayColor(context, proxy.urlTestDelay), fontWeight: FontWeight.w800),
            ),

          if (proxy.download > 0) Text("⬩", style: Theme.of(context).textTheme.bodySmall),
        ],
      ),

      selected: selected,
      selectedTileColor: const Color(0xFF3A2B12),
      onTap: onTap,
      onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      horizontalTitleGap: 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    ),
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 800 => Colors.lightGreen,
        < 1500 => Colors.orange,
        _ => Colors.redAccent,
      };
    }
    return switch (delay) {
      < 800 => Colors.green,
      < 1500 => Colors.deepOrangeAccent,
      _ => Colors.red,
    };
  }
}
