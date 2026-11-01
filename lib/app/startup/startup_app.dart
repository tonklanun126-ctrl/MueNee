import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../core/monitoring/telemetry_boundary.dart';
import '../../core/monitoring/telemetry_providers.dart';
import '../../core/monitoring/telemetry_service.dart';
import '../app.dart';
import '../theme/app_theme.dart';

/// Owns startup outside the router so feature routes never see partial services.
class StartupApp extends ConsumerWidget {
  const StartupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(firebaseStartupProvider);
    if (startup.hasValue && !startup.isLoading) {
      final service = telemetryServiceFor(startup.requireValue.app);
      return ProviderScope(
        overrides: [telemetryServiceProvider.overrideWithValue(service)],
        child: const TelemetryBoundary(child: MueNeeApp()),
      );
    }

    return MaterialApp(
      title: 'MueNee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MueNee')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (startup.isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Text('กำลังเตรียม MueNee…'),
                    ] else ...[
                      const Icon(Icons.cloud_off_outlined, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        'ยังเปิดแอปไม่ได้',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'เริ่มต้นระบบไม่สำเร็จ กรุณาลองอีกครั้ง '
                        'หากยังพบปัญหาให้ติดต่อผู้ดูแลแอป',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(firebaseStartupProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
