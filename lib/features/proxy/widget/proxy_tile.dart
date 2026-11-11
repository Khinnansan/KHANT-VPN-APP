import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _gold = Color(0xFFFFC84A);
const _goldLight = Color(0xFFFFE3A0);

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = proxy.urlTestDelay;
    final validDelay = ConnectionConst.isValidDelay(delay);
    final delayColor = delay <= 0
        ? Colors.white54
        : delay < 180 ? Colors.greenAccent : delay < 450 ? Colors.lightGreen : delay < 800 ? Colors.orangeAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF241A08) : const Color(0xFF0C0B09),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: selected ? _gold : _gold.withValues(alpha: .42), width: selected ? 1.7 : 1),
        boxShadow: selected ? [
          BoxShadow(color: _gold.withValues(alpha: .18), blurRadius: 18, spreadRadius: 1),
          BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 10, offset: const Offset(0, 5)),
        ] : [
          BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: onTap,
          onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IPCountryFlag(
                  countryCode: proxy.ipinfo.countryCode,
                  organization: proxy.ipinfo.org,
                  size: 52,
                  padding: const EdgeInsetsDirectional.only(end: 5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proxy.nameWithDetour,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? _goldLight : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                          fontFamily: PlatformUtils.isWindows ? 'Noto Color Emoji' : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: proxy.type,
                          children: [
                            if (proxy.isGroup)
                              TextSpan(text: ' (${proxy.groupSelectedTagDisplay.trim()})'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: selected ? const Color(0xFFE5C77E) : Colors.white70, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      validDelay ? '$delay ms' : (delay == 0 ? '—' : 'Timeout'),
                      style: TextStyle(color: delayColor, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    selected
                        ? const Icon(Icons.check_circle_rounded, color: _gold, size: 21)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(4, (i) => Container(
                              margin: const EdgeInsets.only(left: 2),
                              width: 4,
                              height: 6.0 + i * 3,
                              decoration: BoxDecoration(color: delayColor.withValues(alpha: .9), borderRadius: BorderRadius.circular(3)),
                            )),
                          ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(selected ? Icons.chevron_right_rounded : Icons.chevron_right_rounded, color: _gold, size: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
