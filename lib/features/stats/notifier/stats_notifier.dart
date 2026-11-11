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
          .map(
            (event) => event.match(
              (_) => SystemInfo.create(),
              (info) => info.copyWith((message) {
                // The pinned Hiddify Core fills the byte counters in ReadStatus
                // but currently leaves traffic_available unset (false). A valid
                // SystemInfo event while the VPN service is running means these
                // counters are available, including legitimate zero values.
                message.trafficAvailable = true;
              }),
            ),
          );
    } else {
      return Stream.value(SystemInfo.create());
    }
  }
}
