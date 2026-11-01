import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../location/providers/location_provider.dart';
import '../../restaurants/models/restaurant.dart';

final mapsConfiguredProvider = Provider<bool>(
  (ref) =>
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY').trim().isNotEmpty,
);

class RestaurantMapScreen extends ConsumerStatefulWidget {
  const RestaurantMapScreen({required this.restaurant, super.key});

  final Restaurant restaurant;

  @override
  ConsumerState<RestaurantMapScreen> createState() =>
      _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends ConsumerState<RestaurantMapScreen> {
  GoogleMapController? _controller;
  Timer? _timer;
  bool _slow = false;
  int _attempt = 0;

  LatLng get _target => LatLng(
    widget.restaurant.location.latitude,
    widget.restaurant.location.longitude,
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20), () {
      if (mounted && _controller == null) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // GoogleMap owns and disposes its controller with the platform view.
    super.dispose();
  }

  void _retry() {
    setState(() {
      _controller = null;
      _slow = false;
      _attempt++;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(mapsConfiguredProvider);
    final location = ref.watch(locationProvider).location;
    final attempt = _attempt;
    return Scaffold(
      appBar: AppBar(title: const Text('แผนที่ร้าน')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              widget.restaurant.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.restaurant.address),
            const SizedBox(height: 16),
            if (!configured)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppTheme.coralActive,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'แผนที่ยังไม่พร้อมใช้งาน',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ยังแสดงแผนที่ในแอปรุ่นนี้ไม่ได้ คุณสามารถดูที่อยู่ร้านด้านบนได้',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 320,
                  child: GoogleMap(
                    key: ValueKey(_attempt),
                    initialCameraPosition: CameraPosition(
                      target: _target,
                      zoom: 16,
                    ),
                    mapToolbarEnabled: false,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('restaurant'),
                        position: _target,
                        infoWindow: InfoWindow(title: widget.restaurant.name),
                      ),
                      if (location != null)
                        Marker(
                          markerId: const MarkerId('last-location'),
                          position: LatLng(
                            location.latitude,
                            location.longitude,
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                          infoWindow: const InfoWindow(
                            title: 'ตำแหน่งที่ใช้ค้นหาครั้งล่าสุด',
                          ),
                        ),
                    },
                    onMapCreated: (controller) {
                      if (!mounted || attempt != _attempt) return;
                      _timer?.cancel();
                      setState(() {
                        _controller = controller;
                        _slow = false;
                      });
                    },
                  ),
                ),
              ),
              if (_controller == null && !_slow)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'กำลังเปิดแผนที่',
                    semanticsLabel: 'กำลังเปิดแผนที่',
                  ),
                ),
              if (_slow)
                const Text(
                  'เปิดแผนที่นานกว่าปกติ ตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง',
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _controller == null
                    ? null
                    : () async {
                        try {
                          await _controller?.animateCamera(
                            CameraUpdate.newLatLngZoom(_target, 16),
                          );
                        } catch (_) {
                          if (mounted) setState(() => _slow = true);
                        }
                      },
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('กลับมาที่ร้าน'),
              ),
              TextButton(
                onPressed: _retry,
                child: const Text('โหลดแผนที่ใหม่'),
              ),
              const Text(
                'หากแผนที่ว่างหรือไม่แสดงถนน ให้ตรวจสอบการเชื่อมต่อแล้วโหลดใหม่',
                style: TextStyle(color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              location == null
                  ? 'ยังไม่มีตำแหน่งของคุณ แผนที่แสดงตำแหน่งร้านได้โดยไม่ขอสิทธิ์เพิ่ม'
                  : 'หมุดสีน้ำเงินคือตำแหน่งที่ใช้ค้นหาครั้งล่าสุด อาจคลาดเคลื่อนและไม่อัปเดตระหว่างเดินทาง',
            ),
            const SizedBox(height: 8),
            const Text(
              'หมุดร้านอ้างอิงข้อมูลที่อยู่ในแอป ยังไม่มีเส้นทางหรือเวลาเดินทาง',
            ),
          ],
        ),
      ),
    );
  }
}
