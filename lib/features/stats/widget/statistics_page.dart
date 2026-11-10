import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _gold = Color(0xFFFFC857);
const _goldLight = Color(0xFFFFE3A0);
const _panel = Color(0xFF15130F);

class StatisticsPage extends HookConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncStats = ref.watch(statsNotifierProvider);
    final stats = asyncStats.asData?.value ?? SystemInfo.create();
    final available = stats.trafficAvailable;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        surfaceTintColor: Colors.transparent,
        title: Text(t.components.stats.traffic),
      ),
      body: asyncStats.when(
        data: (_) => _StatisticsContent(stats: stats, available: available),
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (_, _) => const Center(
          child: Text('Statistics unavailable', style: TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({required this.stats, required this.available});

  final SystemInfo stats;
  final bool available;

  String _total(int bytes) => bytes < 0 ? '0 B' : bytes.size();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF302516), Color(0xFF15110A), Color(0xFF100F0D)],
            ),
            border: Border.all(color: _gold.withValues(alpha: .42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL DATA TRANSFERRED',
                style: TextStyle(color: _goldLight, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const Gap(12),
              Text(
                available ? _total(stats.downlinkTotal.toInt() + stats.uplinkTotal.toInt()) : '—',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const Gap(5),
              Text(available ? 'Download + Upload' : 'Traffic statistics unavailable',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
        const Gap(16),
        Row(
          children: [
            Expanded(child: _TrafficPanel(
              title: 'DOWNLOAD',
              value: available ? _total(stats.downlinkTotal.toInt()) : '—',
              speed: available ? stats.downlink.toInt().speed() : '—',
              icon: Icons.south_rounded,
            )),
            const Gap(12),
            Expanded(child: _TrafficPanel(
              title: 'UPLOAD',
              value: available ? _total(stats.uplinkTotal.toInt()) : '—',
              speed: available ? stats.uplink.toInt().speed() : '—',
              icon: Icons.north_rounded,
            )),
          ],
        ),
        const Gap(16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _gold.withValues(alpha: .20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _gold, size: 19),
              const Gap(10),
              Expanded(
                child: Text(
                  available
                      ? 'Traffic values are supplied by the VPN core.'
                      : 'Connect to a server to check whether traffic statistics are available.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrafficPanel extends StatelessWidget {
  const _TrafficPanel({required this.title, required this.value, required this.speed, required this.icon});

  final String title;
  final String value;
  final String speed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold, size: 21),
          const Gap(12),
          Text(title, style: const TextStyle(color: _goldLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const Gap(6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const Gap(4),
          Text('Live: $speed', style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
