import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'telemetry_providers.dart';
import 'telemetry_service.dart';

class TelemetryBoundary extends ConsumerStatefulWidget {
  const TelemetryBoundary({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<TelemetryBoundary> createState() => _TelemetryBoundaryState();
}

class _TelemetryBoundaryState extends ConsumerState<TelemetryBoundary> {
  late final _service = ref.read(telemetryServiceProvider);

  @override
  void initState() {
    super.initState();
    _service.installGlobalErrorHandlers();
  }

  @override
  void dispose() {
    _service.uninstallGlobalErrorHandlers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_service is! NoopTelemetryService) {
      final settings = ref.watch(telemetrySettingsProvider);
      if (settings.hasError && kDebugMode) {
        debugPrint('MueNee telemetry preferences could not be applied.');
      }
    }
    return widget.child;
  }
}
