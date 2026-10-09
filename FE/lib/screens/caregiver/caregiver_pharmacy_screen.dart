import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/care_network_controller.dart';
import '../../models/care_network.dart';
import '../../models/pharmacist_dashboard.dart';
import '../../models/prescription.dart';
import '../../services/device_location_service.dart';
import '../../services/pharmacy_api.dart';
import '../../services/pharmacy_order_api.dart';
import '../../utils/geohash.dart';
import '../../widgets/widgets.dart';

class CaregiverPharmacyScreen extends StatefulWidget {
  const CaregiverPharmacyScreen({
    super.key,
    required this.controller,
    this.pharmacyApi,
    this.orderApi,
    this.locationProvider,
  });

  final CareNetworkController controller;
  final PharmacyApi? pharmacyApi;
  final PharmacyOrderApi? orderApi;
  final DeviceLocationProvider? locationProvider;

  @override
  State<CaregiverPharmacyScreen> createState() =>
      _CaregiverPharmacyScreenState();
}

class _CaregiverPharmacyScreenState extends State<CaregiverPharmacyScreen> {
  late final PharmacyApi _pharmacyApi;
  late final PharmacyOrderApi _orderApi;
  late final DeviceLocationProvider _locationProvider;
  late final bool _ownsPharmacyApi;
  late final bool _ownsOrderApi;

  List<Pharmacy> _pharmacies = const [];
  List<PharmacyOrder> _orders = const [];
  String? _geohash;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsPharmacyApi = widget.pharmacyApi == null;
    _ownsOrderApi = widget.orderApi == null;
    _pharmacyApi = widget.pharmacyApi ?? PharmacyApi();
    _orderApi = widget.orderApi ?? PharmacyOrderApi();
    _locationProvider = widget.locationProvider ?? DeviceLocationService();
  }

  @override
  void dispose() {
    if (_ownsPharmacyApi) _pharmacyApi.close();
    if (_ownsOrderApi) _orderApi.close();
    super.dispose();
  }

  Future<void> _findNearby() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final location = await _locationProvider.currentLocation();
      final geohash = encodeGeohash(location.latitude, location.longitude);
      final results = await Future.wait<Object>([
        _pharmacyApi.list(
          latitude: location.latitude,
          longitude: location.longitude,
          geohash: geohash,
          radiusKm: 10,
        ),
        _orderApi.listMine(),
      ]);
      if (!mounted) return;
      setState(() {
        _geohash = geohash;
        _pharmacies = results[0] as List<Pharmacy>;
        _orders = results[1] as List<PharmacyOrder>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOrder(Pharmacy pharmacy) async {
    final patientId = widget.controller.selectedPatientId;
    final bundle = widget.controller.bundleFor(patientId);
    if (patientId == null || bundle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn và tải hồ sơ bệnh nhân trước.')),
      );
      return;
    }
    final order = await showModalBottomSheet<PharmacyOrder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOrderSheet(
        pharmacy: pharmacy,
        patientId: patientId,
        bundle: bundle,
        orderApi: _orderApi,
      ),
    );
    if (order == null || !mounted) return;
    setState(() => _orders = [order, ..._orders]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi đơn ${order.orderCode} đến ${pharmacy.name}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScroll(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageIntro(
          'Nhà thuốc gần bạn',
          'Bật vị trí để tìm nhà thuốc trong phạm vi tối đa 10 km',
        ),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Vị trí chỉ được dùng khi bạn nhấn tìm và không được lưu vào tài khoản.',
                style: TextStyle(color: Color(0xFF687195)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('find-nearby-pharmacies'),
                onPressed: _loading ? null : _findNearby,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  _loading ? 'Đang xác định vị trí...' : 'Dùng vị trí hiện tại',
                ),
              ),
              if (_geohash != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Geohash: $_geohash',
                  key: const Key('caregiver-geohash'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF5267F4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  key: const Key('nearby-pharmacy-error'),
                  style: const TextStyle(color: Color(0xFFC64E57)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_geohash == null)
          const _EmptyCard(
            icon: Icons.location_searching_rounded,
            message: 'Chưa có vị trí để tìm nhà thuốc.',
          )
        else if (_pharmacies.isEmpty)
          const _EmptyCard(
            icon: Icons.store_mall_directory_outlined,
            message: 'Không tìm thấy nhà thuốc nào trong phạm vi 10 km.',
          )
        else ...[
          Text(
            '${_pharmacies.length} nhà thuốc trong 10 km',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ..._pharmacies.map(
            (pharmacy) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Glass(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE7E9FF),
                      child: Icon(
                        Icons.local_pharmacy_rounded,
                        color: Color(0xFF5267F4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            pharmacy.addressText,
                            style: const TextStyle(color: Color(0xFF687195)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${pharmacy.distanceKm?.toStringAsFixed(2) ?? '?'} km',
                            key: Key('pharmacy-distance-${pharmacy.id}'),
                            style: const TextStyle(
                              color: Color(0xFF249D76),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      key: Key('order-from-${pharmacy.id}'),
                      onPressed: () => _openOrder(pharmacy),
                      child: const Text('Đặt thuốc'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (_orders.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Đơn gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ..._orders
              .take(5)
              .map(
                (order) => ListTile(
                  key: Key('caregiver-order-${order.id}'),
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: Text(order.orderCode),
                  subtitle: Text(order.status.label),
                ),
              ),
        ],
      ],
    ),
  );
}

class _CreateOrderSheet extends StatefulWidget {
  const _CreateOrderSheet({
    required this.pharmacy,
    required this.patientId,
    required this.bundle,
    required this.orderApi,
  });

  final Pharmacy pharmacy;
  final String patientId;
  final PatientBundle bundle;
  final PharmacyOrderApi orderApi;

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  late final List<Prescription> _prescriptions;
  Prescription? _prescription;
  final Set<String> _selected = {};
  final Map<String, int> _quantities = {};
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _note = TextEditingController();
  FulfillmentType _fulfillment = FulfillmentType.pickup;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prescriptions = widget.bundle.prescriptions
        .where(
          (item) => item.isActive && item.id != null && item.items.isNotEmpty,
        )
        .toList(growable: false);
    if (_prescriptions.isNotEmpty) _selectPrescription(_prescriptions.first);
    _recipientName.text = widget.bundle.detail.fullName;
    _recipientPhone.text = widget.bundle.detail.phone;
  }

  void _selectPrescription(Prescription prescription) {
    _prescription = prescription;
    _selected.clear();
    _quantities.clear();
    final orderable = prescription.items
        .where((item) => item.id != null)
        .toList();
    final lowStock = orderable.where((item) => item.isLowStock).toList();
    for (final item in lowStock.isEmpty ? orderable : lowStock) {
      _selected.add(item.id!);
    }
    for (final item in orderable) {
      _quantities[item.id!] = math.max(
        1,
        item.reorderThreshold - item.currentStock + 1,
      );
    }
  }

  @override
  void dispose() {
    _recipientName.dispose();
    _recipientPhone.dispose();
    _deliveryAddress.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prescription = _prescription;
    if (prescription?.id == null || _selected.isEmpty) {
      setState(() => _error = 'Hãy chọn ít nhất một thuốc.');
      return;
    }
    if (_fulfillment == FulfillmentType.delivery &&
        (_recipientName.text.trim().isEmpty ||
            _recipientPhone.text.trim().isEmpty ||
            _deliveryAddress.text.trim().isEmpty)) {
      setState(() => _error = 'Vui lòng nhập đủ thông tin giao thuốc.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final order = await widget.orderApi.create(
        patientId: widget.patientId,
        pharmacyId: widget.pharmacy.id,
        prescriptionId: prescription!.id!,
        fulfillmentType: _fulfillment,
        recipientName: _recipientName.text,
        recipientPhone: _recipientPhone.text,
        deliveryAddress: _fulfillment == FulfillmentType.delivery
            ? _deliveryAddress.text
            : null,
        patientNote: _note.text,
        items: [
          for (final id in _selected)
            (prescriptionItemId: id, quantity: _quantities[id] ?? 1),
        ],
      );
      if (mounted) Navigator.pop(context, order);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF7F8FF),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: _prescriptions.isEmpty
          ? const Center(
              child: Text('Bệnh nhân chưa có đơn thuốc đang hoạt động.'),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đặt thuốc tại ${widget.pharmacy.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Prescription>(
                    key: const Key('order-prescription'),
                    initialValue: _prescription,
                    decoration: const InputDecoration(
                      labelText: 'Đơn thuốc',
                      border: OutlineInputBorder(),
                    ),
                    items: _prescriptions
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectPrescription(value!)),
                  ),
                  const SizedBox(height: 10),
                  for (final item in _prescription!.items.where(
                    (item) => item.id != null,
                  ))
                    CheckboxListTile(
                      key: Key('order-item-${item.id}'),
                      value: _selected.contains(item.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.medicineName),
                      subtitle: Text(
                        'Tồn ${item.currentStock} · Ngưỡng ${item.reorderThreshold}',
                      ),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(item.id!);
                        } else {
                          _selected.remove(item.id);
                        }
                      }),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => setState(() {
                              _quantities[item.id!] = math.max(
                                1,
                                (_quantities[item.id] ?? 1) - 1,
                              );
                            }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${_quantities[item.id] ?? 1}'),
                          IconButton(
                            onPressed: () => setState(() {
                              _quantities[item.id!] =
                                  (_quantities[item.id] ?? 1) + 1;
                            }),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<FulfillmentType>(
                    key: const Key('order-fulfillment'),
                    initialValue: _fulfillment,
                    decoration: const InputDecoration(
                      labelText: 'Hình thức nhận thuốc',
                      border: OutlineInputBorder(),
                    ),
                    items: FulfillmentType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _fulfillment = value!),
                  ),
                  if (_fulfillment == FulfillmentType.delivery) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _recipientName,
                      decoration: const InputDecoration(
                        labelText: 'Người nhận',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _recipientPhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại người nhận',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('order-delivery-address'),
                      controller: _deliveryAddress,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ giao thuốc',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFC64E57)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const Key('submit-pharmacy-order'),
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? 'Đang gửi...' : 'Gửi đơn đến nhà thuốc',
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Glass(
    padding: const EdgeInsets.all(22),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF687195)),
        const SizedBox(width: 10),
        Flexible(child: Text(message)),
      ],
    ),
  );
}
