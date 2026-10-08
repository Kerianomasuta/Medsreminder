import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/pharmacist_dashboard.dart';
import '../services/geocoding_api.dart';

class PharmacyLocationPicker extends StatefulWidget {
  const PharmacyLocationPicker({
    super.key,
    required this.onChanged,
    this.initialLocation,
    this.geocodingApi,
    this.showMap = true,
  });

  final PharmacyLocationSelection? initialLocation;
  final ValueChanged<PharmacyLocationSelection?> onChanged;
  final GeocodingApi? geocodingApi;

  /// Kept configurable so the search flow can be tested without loading tiles.
  final bool showMap;

  @override
  State<PharmacyLocationPicker> createState() => _PharmacyLocationPickerState();
}

class _PharmacyLocationPickerState extends State<PharmacyLocationPicker> {
  static const _hoChiMinhCity = LatLng(10.7769, 106.7009);

  late final TextEditingController _addressController;
  late final MapController _mapController;
  late final GeocodingApi _geocodingApi;
  late final bool _ownsGeocodingApi;

  PharmacyLocationSelection? _selection;
  LatLng? _markerPoint;
  List<PharmacyLocationSelection> _results = const [];
  bool _searching = false;
  bool _resolvingPoint = false;
  String? _error;
  int _operation = 0;

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
    _addressController = TextEditingController(
      text: widget.initialLocation?.addressText,
    );
    _mapController = MapController();
    _ownsGeocodingApi = widget.geocodingApi == null;
    _geocodingApi = widget.geocodingApi ?? GeocodingApi();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController.dispose();
    if (_ownsGeocodingApi) _geocodingApi.close();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _addressController.text.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _error = 'Nhập ít nhất 3 ký tự để tìm địa chỉ.';
      });
      return;
    }

    final operation = ++_operation;
    setState(() {
      _searching = true;
      _results = const [];
      _error = null;
    });
    try {
      final results = await _geocodingApi.searchAddress(query);
      if (!mounted || operation != _operation) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'Không tìm thấy địa chỉ phù hợp tại Việt Nam.';
        }
      });
    } catch (exception) {
      if (!mounted || operation != _operation) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted && operation == _operation) {
        setState(() => _searching = false);
      }
    }
  }

  void _chooseResult(PharmacyLocationSelection location) {
    ++_operation;
    final point = LatLng(location.latitude, location.longitude);
    _addressController.text = location.addressText;
    setState(() {
      _selection = location;
      _markerPoint = point;
      _results = const [];
      _error = null;
      _searching = false;
      _resolvingPoint = false;
    });
    if (widget.showMap) _mapController.move(point, 16);
    widget.onChanged(location);
  }

  Future<void> _choosePoint(LatLng point) async {
    final operation = ++_operation;
    setState(() {
      _selection = null;
      _markerPoint = point;
      _results = const [];
      _error = null;
      _resolvingPoint = true;
    });
    widget.onChanged(null);
    try {
      final location = await _geocodingApi.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (!mounted || operation != _operation) return;
      _addressController.text = location.addressText;
      setState(() {
        _selection = location;
        _error = null;
      });
      widget.onChanged(location);
    } catch (exception) {
      if (!mounted || operation != _operation) return;
      setState(() => _error = exception.toString());
    } finally {
      if (mounted && operation == _operation) {
        setState(() => _resolvingPoint = false);
      }
    }
  }

  void _invalidateSelection(String _) {
    if (_selection == null) return;
    ++_operation;
    setState(() {
      _selection = null;
      _results = const [];
      _error = 'Địa chỉ đã thay đổi. Hãy tìm và chọn lại vị trí.';
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('pharmacy-address-search'),
                controller: _addressController,
                minLines: 1,
                maxLines: 2,
                textInputAction: TextInputAction.search,
                onChanged: _invalidateSelection,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ nhà thuốc',
                  hintText: 'Ví dụ: 123 Nguyễn Huệ, Quận 1, TP.HCM',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: FilledButton.tonalIcon(
                key: const Key('search-pharmacy-address'),
                onPressed: _searching || _resolvingPoint ? null : _search,
                icon: _searching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text('Tìm'),
              ),
            ),
          ],
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (var index = 0; index < _results.length; index++) ...[
                  ListTile(
                    key: Key('address-result-$index'),
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      _results[index].addressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _chooseResult(_results[index]),
                  ),
                  if (index < _results.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        if (widget.showMap) ...[
          const SizedBox(height: 12),
          Text(
            'Chạm bản đồ để điều chỉnh vị trí',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPoint ?? _hoChiMinhCity,
                  initialZoom: _markerPoint == null ? 12 : 16,
                  minZoom: 4,
                  maxZoom: 19,
                  onTap: (_, point) => _choosePoint(point),
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
        if (_resolvingPoint) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          const Text('Đang xác định địa chỉ tại vị trí đã chọn...'),
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
                      Text(
                        '${_selection!.latitude.toStringAsFixed(6)}, '
                        '${_selection!.longitude.toStringAsFixed(6)}',
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
