
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/eclipse_button_painter.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum _Look {
  loading,
  disconnected,
  connecting,
  waiting,
  noProxies,
  connected,
  hotReloading,
  disconnecting,
  failed,
}

_Look _lookOf(AsyncValue<ConnectionStatus> status) => switch (status) {
      AsyncError() => _Look.failed,
      AsyncValue(valueOrNull: Disconnected(connectionFailure: _?)) =>
        _Look.failed,
      AsyncValue(valueOrNull: Disconnected()) => _Look.disconnected,
      AsyncValue(valueOrNull: Connecting()) => _Look.connecting,
      AsyncValue(valueOrNull: Waiting()) => _Look.waiting,
      AsyncValue(valueOrNull: NoAvailableProxies()) => _Look.noProxies,
      AsyncValue(valueOrNull: HotReloading()) => _Look.hotReloading,
      AsyncValue(valueOrNull: Connected()) => _Look.connected,
      AsyncValue(valueOrNull: Disconnecting()) => _Look.disconnecting,
      _ => _Look.loading,
    };

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider);
    final look = _held(_lookOf(status));

    final onTap = switch (status) {
      AsyncData(value: Disconnected()) || AsyncError() => () => _connect(ref),
      AsyncData(
        value: Connected() ||
            Waiting() ||
            NoAvailableProxies() ||
            Connecting() ||
            HotReloading()
      ) =>
        () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
      _ => null,
    };

    final failure = switch (status) {
      AsyncError(:final ConnectionFailure error) => error,
      AsyncValue(valueOrNull: Disconnected(connectionFailure: final failure?)) =>
        failure,
      _ => null,
    };

    final stats = ref.watch(statsNotifierProvider).valueOrNull;
    final activeProxy = ref.watch(activeProxyNotifierProvider).valueOrNull;
    final countryCode = activeProxy?.hasIp == true
        ? activeProxy!.ipinfo.countryCode
        : null;
    final ping = activeProxy?.urlTestDelay ?? 0;

    return _ConnectionButton(
      look: look,
      onTap: onTap,
      onErrorDetails: failure == null
          ? null
          : () => ref
              .read(dialogNotifierProvider.notifier)
              .showCustomAlertFromErr(failure.present(t)),
      errorDetailsLabel: t.connection.errorDetails,
      download: stats?.downlink.toInt() ?? 0,
      upload: stats?.uplink.toInt() ?? 0,
      totalDownload: stats?.downlinkTotal.toInt() ?? 0,
      totalUpload: stats?.uplinkTotal.toInt() ?? 0,
      trafficAvailable: stats?.trafficAvailable ?? false,
      countryCode: countryCode,
      ping: ping,
      label: switch (look) {
        _Look.loading => "",
        _Look.disconnected => t.connection.tapToConnect,
        _Look.connecting => t.connection.connecting,
        _Look.waiting => t.connection.waiting,
        _Look.noProxies => t.connection.noAvailableProxies,
        _Look.connected => t.connection.connected,
        _Look.hotReloading => t.connection.hotReloading,
        _Look.disconnecting => t.connection.disconnecting,
        _Look.failed => t.connection.failed,
      },
      hint: look == _Look.failed ? t.connection.tapToRetry : null,
    );
  }

  _Look _held(_Look look) {
    final shown = useRef(look);
    final until = useRef<DateTime?>(null);
    final rebuild = useState(0);

    final steady = {
      _Look.connected,
      _Look.noProxies,
    }.contains(shown.value);

    final blip = look == _Look.loading;
    var result = look;

    if (steady && blip) {
      until.value ??= DateTime.now().add(_hold);

      if (DateTime.now().isBefore(until.value!)) {
        result = shown.value;
      } else {
        until.value = null;
      }
    } else {
      until.value = null;
    }

    shown.value = result;

    useEffect(() {
      final end = until.value;
      if (end == null) return null;

      final timer = Timer(
        end.difference(DateTime.now()),
        () => rebuild.value++,
      );

      return timer.cancel;
    }, [until.value]);

    return result;
  }

  static const _hold = Duration(milliseconds: 1500);

  Future<void> _connect(WidgetRef ref) async {
    final dialogs = ref.read(dialogNotifierProvider.notifier);

    if (ref.read(activeProfileProvider).valueOrNull == null) {
      await dialogs.showNoActiveProfile();
      ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
      return;
    }

    if (await dialogs.showExperimentalFeatureNotice()) {
      await ref
          .read(connectionNotifierProvider.notifier)
          .toggleConnection();
    }
  }
}

class _ConnectionButton extends HookWidget {
  const _ConnectionButton({
    required this.look,
    required this.onTap,
    required this.onErrorDetails,
    required this.errorDetailsLabel,
    required this.download,
    required this.upload,
    required this.totalDownload,
    required this.totalUpload,
    required this.trafficAvailable,
    required this.countryCode,
    required this.ping,
    required this.label,
    required this.hint,
  });

  final _Look look;
  final VoidCallback? onTap;
  final VoidCallback? onErrorDetails;
  final String errorDetailsLabel;
  final int download;
  final int upload;
  final int totalDownload;
  final int totalUpload;
  final bool trafficAvailable;
  final String? countryCode;
  final int ping;
  final String label;
  final String? hint;

  static const _size = 148.0;
  static const _glow = 110.0;
  static const _gold = Color(0xFFFFC857);

  EclipseLook get _eclipseLook => switch (look) {
        _Look.loading || _Look.disconnected => EclipseLook.idle,
        _Look.connecting => EclipseLook.starting,
        _Look.disconnecting => EclipseLook.stopping,
        _Look.waiting || _Look.hotReloading => EclipseLook.waiting,
        _Look.connected || _Look.noProxies => EclipseLook.connected,
        _Look.failed => EclipseLook.error,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);

    final clock = useMemoized(() => Stopwatch()..start());
    double now() => clock.elapsedMicroseconds / 1e6;

    final eclipseLook = _eclipseLook;

    final change = useRef((
      look: eclipseLook,
      previous: eclipseLook,
      at: -10.0,
      color: _gold,
      previousColor: _gold,
    ));

    final previousLook = usePrevious(look);
    final leftConnected = useRef(-10.0);

    if (change.value.look != eclipseLook) {
      final last = change.value;

      if (last.look == EclipseLook.connected &&
          eclipseLook != EclipseLook.connected) {
        leftConnected.value = now();
      }

      final eased = Color.lerp(
        last.previousColor,
        last.color,
        ((now() - last.at) / .45).clamp(0.0, 1.0),
      )!;

      final skip = previousLook == _Look.loading ||
          (eclipseLook == EclipseLook.connected &&
              now() - leftConnected.value < 2);

      change.value = (
        look: eclipseLook,
        previous: last.look,
        at: skip ? now() - 10 : now(),
        color: _gold,
        previousColor: eased,
      );
    }

    final target = useRef(const EclipseTraffic());

    target.value = EclipseTraffic(
      down: EclipseTraffic.level(download),
      up: EclipseTraffic.level(upload),
    );

    final traffic = useRef(const EclipseTraffic());
    final time = useValueNotifier(0.0);

    useEffect(() {
      if (still) return null;

      var last = now();

      final timer = Timer.periodic(
        const Duration(milliseconds: 33),
        (_) {
          final at = now();

          double follow(double from, double to) {
            return from +
                (to - from) *
                    (1 - math.exp(-(at - last) / (to > from ? .8 : 2.5)));
          }

          final t = traffic.value;

          traffic.value = EclipseTraffic(
            down: follow(t.down, target.value.down),
            up: follow(t.up, target.value.up),
          );

          last = at;

          final settled = change.value.look == EclipseLook.idle &&
              at - change.value.at > 1;

          if (!settled) {
            time.value = at;
          }
        },
      );

      return timer.cancel;
    }, [still]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          hint: hint,
          child: SizedBox.square(
            dimension: _size,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -_glow,
                  top: -_glow,
                  right: -_glow,
                  bottom: -_glow,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder(
                        valueListenable: time,
                        builder: (context, t, _) {
                          final c = change.value;

                          return CustomPaint(
                            isComplex: true,
                            willChange: true,
                            painter: EclipseButtonPainter(
                              frame: EclipseFrame(
                                look: c.look,
                                previous: c.previous,
                                since: still ? 10 : now() - c.at,
                                time: still ? 0 : now(),
                                color: c.color,
                                previousColor: c.previousColor,
                              ),
                              radius: _size / 2,
                              traffic: traffic.value,
                              dark: true,
                              drawLogo: true,
                              logoOpacity:
                                  look == _Look.loading ? .38 : 1,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Material(
                  key: const ValueKey("home_connection_button"),
                  shape: const CircleBorder(),
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    focusColor: Colors.amber.withValues(alpha: .2),
                    onTap: onTap,
                  ),
                ),
                if (look == _Look.failed && onErrorDetails != null)
                  Positioned.fromRect(
                    rect: EclipseButtonPainter.errorBadgeRect(
                      const Offset(_size / 2, _size / 2),
                      _size / 2,
                    ).inflate(8),
                    child: Semantics(
                      button: true,
                      label: errorDetailsLabel,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onErrorDetails,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Gap(24),
        ExcludeSemantics(
          child: Column(
            children: [
              AnimatedText(
                label,
                style: theme.textTheme.titleMedium,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: hint == null
                    ? const SizedBox.shrink()
                    : Text(
                        hint!,
                        key: ValueKey(hint),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (look == _Look.connected && countryCode != null) ...[
          _ConnectionMeta(countryCode: countryCode!, ping: ping),
          const Gap(12),
        ],
        const Gap(22),
        _ConnectionDurationCard(active: look == _Look.connected),
        const Gap(8),
        _DataUsageCard(
          download: look == _Look.connected ? totalDownload : 0,
          upload: look == _Look.connected ? totalUpload : 0,
          available: look != _Look.connected || trafficAvailable,
        ),
      ],
    );
  }
}

class _ConnectionDurationCard extends HookWidget {
  const _ConnectionDurationCard({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final elapsed = useState(Duration.zero);
    final stopwatch = useMemoized(() => Stopwatch());
    useEffect(() {
      stopwatch
        ..reset();
      elapsed.value = Duration.zero;
      if (!active) return null;
      stopwatch.start();
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value = stopwatch.elapsed;
      });
      return () {
        timer.cancel();
        stopwatch.stop();
      };
    }, [active]);
    String two(int value) => value.toString().padLeft(2, '0');
    final duration = elapsed.value;
    final label = '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF100E0B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857).withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFFFC857), size: 20),
          const Gap(10),
          const Text('Connection time', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Gap(10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DataUsageCard extends StatelessWidget {
  const _DataUsageCard({
    required this.download,
    required this.upload,
    required this.available,
  });

  final int download;
  final int upload;
  final bool available;

  static const _gold = Color(0xFFFFC857);
  static const _muted = Color(0xFFBDB5A8);

  String _formatBytes(int bytes) {
    final value = bytes < 0 ? 0.0 : bytes.toDouble();
    if (value >= 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(2)} KB';
    }
    return '${value.toStringAsFixed(0)} B';
  }

  @override
  Widget build(BuildContext context) {
    final total = download + upload;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF100E0B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: .055),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.data_usage_rounded, color: _gold, size: 18),
              const Gap(8),
              const Text(
                'DATA USED',
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                available ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                color: available ? Colors.greenAccent : _muted,
                size: 17,
              ),
            ],
          ),
          const Gap(13),
          Row(
            children: [
              Expanded(
                child: _DataUsageValue(
                  icon: Icons.south_rounded,
                  label: 'Download',
                  value: available ? _formatBytes(download) : '—',
                ),
              ),
              Container(width: 1, height: 42, color: _gold.withValues(alpha: .28)),
              const Gap(9),
              Expanded(
                child: _DataUsageValue(
                  icon: Icons.north_rounded,
                  label: 'Upload',
                  value: available ? _formatBytes(upload) : '—',
                ),
              ),
              const Gap(9),
              Container(width: 1, height: 42, color: _gold.withValues(alpha: .28)),
              const Gap(9),
              Expanded(
                child: _DataUsageValue(
                  icon: Icons.storage_rounded,
                  label: 'Total',
                  value: available ? _formatBytes(total) : '—',
                  emphasize: true,
                ),
              ),
            ],
          ),
          if (!available) ...[
            const Gap(8),
            const Text(
              'Waiting for traffic data from the VPN core.',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataUsageValue extends StatelessWidget {
  const _DataUsageValue({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD77D), size: 16),
            const Gap(5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFBDB5A8), fontSize: 10),
              ),
            ),
          ],
        ),
        const Gap(7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasize ? const Color(0xFFFFC857) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ConnectionMeta extends StatelessWidget {
  const _ConnectionMeta({required this.countryCode, required this.ping});

  final String countryCode;
  final int ping;

  static const _names = <String, String>{
    'SG': 'Singapore',
    'JP': 'Japan',
    'US': 'United States',
    'DE': 'Germany',
    'TH': 'Thailand',
    'HK': 'Hong Kong',
    'GB': 'United Kingdom',
    'KR': 'South Korea',
    'TW': 'Taiwan',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
    'IN': 'India',
    'FR': 'France',
    'NL': 'Netherlands',
    'CA': 'Canada',
    'AU': 'Australia',
    'MM': 'Myanmar',
  };

  String get _flag {
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '🌐';
    return String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 65));
  }

  @override
  Widget build(BuildContext context) {
    final name = _names[countryCode.toUpperCase()] ?? countryCode.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF100E0B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC857).withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_flag, style: const TextStyle(fontSize: 17)),
          const Gap(8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Gap(14),
          Container(width: 1, height: 20, color: const Color(0xFFFFC857).withValues(alpha: .35)),
          const Gap(14),
          const Icon(Icons.wifi_rounded, size: 17, color: Colors.white),
          const Gap(6),
          Text(
            ping > 0 ? '$ping ms' : '— ms',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SpeedStatsCard extends StatelessWidget {
  const _SpeedStatsCard({
    required this.download,
    required this.upload,
    required this.connected,
  });

  final int download;
  final int upload;
  final bool connected;

  static const _gold = Color(0xFFFFC857);
  static const _goldLight = Color(0xFFFFE6A6);

  String _formatSpeed(int bytes) {
    final value = bytes < 0 ? 0 : bytes;

    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }

    if (value >= 1024) {
      return '${(value / 1024).toStringAsFixed(2)} KB/s';
    }

    return '${value.toStringAsFixed(2)} B/s';
  }

  Widget _speedItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: .10),
              border: Border.all(
                color: _gold.withValues(alpha: .5),
              ),
            ),
            child: Icon(
              icon,
              color: _goldLight,
              size: 21,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF30251A),
            const Color(0xFF17120E),
            const Color(0xFF241A10),
          ],
        ),
        border: Border.all(
          color: _gold.withValues(alpha: .65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: .10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? Colors.greenAccent : Colors.grey,
                  boxShadow: connected
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: .5),
                            blurRadius: 7,
                          ),
                        ]
                      : null,
                ),
              ),
              const Gap(7),
              Text(
                connected ? 'LIVE NETWORK SPEED' : 'NETWORK SPEED',
                style: TextStyle(
                  color: _goldLight.withValues(alpha: .85),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bolt_rounded,
                color: _gold.withValues(alpha: .85),
                size: 17,
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _speedItem(
                icon: Icons.arrow_downward_rounded,
                title: 'Download',
                value: _formatSpeed(download),
              ),
              Container(
                width: 1,
                height: 43,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: _gold.withValues(alpha: .35),
              ),
              _speedItem(
                icon: Icons.arrow_upward_rounded,
                title: 'Upload',
                value: _formatSpeed(upload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
