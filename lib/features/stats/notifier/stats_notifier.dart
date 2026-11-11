import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/stats/data/stats_data_providers.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/init_signal.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_notifier.g.dart';

@riverpod
class StatsNotifier extends _$StatsNotifier with AppLogger {
  @override
  Stream<SystemInfo> build() {
    ref.disposeDelay(const Duration(seconds: 10));
    final serviceRunning = ref.watch(serviceRunningProvider);
    // the core gets a new gRPC channel when the app comes back from the background
    ref.watch(coreRestartSignalProvider);
    if (serviceRunning) {
      return ref
          .watch(statsRepositoryProvider)
          .watchStats()
          .map((event) {
            final info = event.getOrElse((_) => SystemInfo.create());
            // The pinned Hiddify Core returns valid byte counters from ReadStatus,
            // but currently leaves traffic_available unset (false). A received
            // SystemInfo event while the VPN service is running is the signal
            // that these counters are available, including legitimate zero values.
            return info.copyWith((message) {
              message.trafficAvailable = true;
            });
          });
    } else {
      return Stream.value(SystemInfo.create());
    }
  }
}
