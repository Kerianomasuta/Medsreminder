import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/pharmacist_dashboard.dart';
import '../services/device_location_service.dart';
import '../services/geocoding_api.dart';

class PharmacyLocationPicker extends StatefulWidget {
  const PharmacyLocationPicker({
    super.key,
    required this.onChanged,
    this.initialLocation,
    this.geocodingApi,
    this.locationProvider,
    this.showMap = true,
  });

  final PharmacyLocationSelection? initialLocation;
  final ValueChanged<PharmacyLocationSelection?> onChanged;
  final GeocodingApi? geocodingApi;
  final DeviceLocationProvider? locationProvider;

  /// Kept configurable so the GPS flow can be tested without loading tiles.
  final bool showMap;

  @override
  State<PharmacyLocationPicker> createState() => _PharmacyLocationPickerState();
}

class _PharmacyLocationPickerState extends State<PharmacyLocationPicker> {
  late final MapController _mapController;
  late final GeocodingApi _geocodingApi;
  late final DeviceLocationProvider _locationProvider;
  late final bool _ownsGeocodingApi;

  PharmacyLocationSelection? _selection;
  LatLng? _markerPoint;
  bool _usingDeviceLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialLocation;
    _markerPoint = widget.initialLocation == null
        ? null
        : LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          );
    _mapController = MapController();
    _ownsGeocodingApi = widget.geocodingApi == null;
    _geocodingApi = widget.geocodingApi ?? GeocodingApi();
    _locationProvider = widget.locationProvider ?? DeviceLocationService();
  }

  @override
  void dispose() {
    _mapController.dispose();
    if (_ownsGeocodingApi) _geocodingApi.close();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _usingDeviceLocation = true;
      _error = null;
    });
    try {
      final deviceLocation = await _locationProvider.currentLocation();
      if (!mounted) return;
      final location = await _geocodingApi.reverseGeocode(
        deviceLocation.latitude,
        deviceLocation.longitude,
      );
      if (!mounted) return;
      final point = LatLng(location.latitude, location.longitude);
      setState(() {
        _selection = location;
        _markerPoint = point;
      });
      widget.onChanged(location);
      if (widget.showMap) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(point, 16);
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _usingDeviceLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí nhà thuốc được lấy trực tiếp từ GPS của thiết bị.',
          style: TextStyle(color: Color(0xFF687195)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('use-current-pharmacy-location'),
            onPressed: _usingDeviceLocation ? null : _useCurrentLocation,
            icon: _usingDeviceLocation
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _usingDeviceLocation
                  ? 'Đang lấy vị trí...'
                  : 'Dùng vị trí hiện tại',
            ),
          ),
        ),
        if (widget.showMap && _markerPoint != null) ...[
          const SizedBox(height: 12),
          Text(
            'Vị trí GPS đã xác định',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              key: const Key('pharmacy-location-map'),
              height: 150,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPoint!,
                  initialZoom: 16,
                  minZoom: 16,
                  maxZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.medsreminder.meds_reminder',
                    maxNativeZoom: 19,
                  ),
                  if (_markerPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _markerPoint!,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_pin,
                            size: 46,
                            color: colorScheme.primary,
                            shadows: const [
                              Shadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            key: const Key('pharmacy-location-error'),
            style: TextStyle(color: colorScheme.error),
          ),
        ],
        if (_selection != null) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('confirmed-pharmacy-location'),
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã xác nhận vị trí',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(_selection!.addressText),
                      Text(
                        '${_selection!.latitude.toStringAsFixed(6)}, '
                        '${_selection!.longitude.toStringAsFixed(6)}',
                      ),
                      Text(
                        'Geohash: ${_selection!.geohash}',
                        key: const Key('confirmed-pharmacy-geohash'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
