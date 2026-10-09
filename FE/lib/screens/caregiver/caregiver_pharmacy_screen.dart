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
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final mine = await _orderApi.listMine();
      if (mounted) setState(() => _orders = mine);
    } catch (_) {}
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
      await _searchWithCoordinates(location.latitude, location.longitude);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchWithCoordinates(double latitude, double longitude) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final geohash = encodeGeohash(latitude, longitude);
      final results = await Future.wait<Object>([
        _pharmacyApi.list(
          latitude: latitude,
          longitude: longitude,
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

  Future<void> _openOrderDetail(PharmacyOrder initialOrder) async {
    final updated = await showModalBottomSheet<PharmacyOrder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        initialOrder: initialOrder,
        orderApi: _orderApi,
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _orders = [
          for (final o in _orders)
            if (o.id == updated.id) updated else o,
        ];
      });
    }
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
            message: 'Chưa có vị trí để tìm nhà thuốc. Hãy bấm "Dùng vị trí hiện tại".',
          )
        else if (_pharmacies.isEmpty)
          const _EmptyCard(
            icon: Icons.store_mall_directory_outlined,
            message: 'Không tìm thấy nhà thuốc nào trong phạm vi 10 km.',
          ) else ...[
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn gần đây (${_orders.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Tải lại đơn',
                onPressed: _loadOrders,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._orders
              .take(8)
              .map(
                (order) => _OrderCard(
                  key: Key('caregiver-order-${order.id}'),
                  order: order,
                  onTap: () => _openOrderDetail(order),
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
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: _prescriptions.isEmpty
            ? const Center(
                child: Text('Bệnh nhân chưa có đơn thuốc đang hoạt động.'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Đặt thuốc tại ${widget.pharmacy.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<Prescription>(
                            key: const Key('order-prescription'),
                            initialValue: _prescription,
                            decoration: const InputDecoration(
                              labelText: 'Đơn thuốc cần đặt',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF5267F4),
                              ),
                            ),
                            items: _prescriptions
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      p.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (p) =>
                                setState(() => _selectPrescription(p!)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Chọn các thuốc cần đặt:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in _prescription!.items.where(
                            (item) => item.id != null,
                          ))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                key: Key('order-item-${item.id}'),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selected.contains(item.id)
                                        ? const Color(0xFF5267F4)
                                        : const Color(0xFFE2E8F0),
                                    width: _selected.contains(item.id) ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _selected.contains(item.id),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                      activeColor: const Color(0xFF5267F4),
                                      onChanged: (checked) => setState(() {
                                        if (checked == true) {
                                          _selected.add(item.id!);
                                        } else {
                                          _selected.remove(item.id);
                                        }
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.medicineName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Tồn kho: ${item.currentStock}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Ngưỡng báo: ${item.reorderThreshold}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFFB45309),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => setState(() {
                                              _quantities[item.id!] = math.max(
                                                1,
                                                (_quantities[item.id] ?? 1) - 1,
                                              );
                                            }),
                                            icon: const Icon(Icons.remove_rounded, size: 18),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              '${_quantities[item.id] ?? 1}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () => setState(() {
                                              _quantities[item.id!] =
                                                  (_quantities[item.id] ?? 1) + 1;
                                            }),
                                            icon: const Icon(Icons.add_rounded, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
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

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({
    required this.initialOrder,
    required this.orderApi,
  });

  final PharmacyOrder initialOrder;
  final PharmacyOrderApi orderApi;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late PharmacyOrder _order;
  bool _loading = false;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final fresh = await widget.orderApi.getById(_order.id);
      if (mounted) setState(() => _order = fresh);
    } catch (_) {
      // Giữ nguyên initialOrder nếu getById lỗi mạng
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController(text: 'Không có nhu cầu mua nữa');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn thuốc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do bạn muốn hủy đơn:'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('cancel-order-reason-input'),
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Lý do hủy đơn',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            key: const Key('confirm-cancel-order-button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC64E57),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      final updated = await widget.orderApi.cancel(_order.id, reasonController.text);
      if (mounted) {
        setState(() => _order = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hủy đơn ${_order.orderCode}.')),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _completeOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã nhận thuốc'),
        content: const Text(
          'Bạn xác nhận đã nhận đủ thuốc cho đơn hàng này? Số lượng thuốc sẽ được cộng vào tủ thuốc tại nhà của bệnh nhân.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa nhận'),
          ),
          FilledButton(
            key: const Key('confirm-complete-order-button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF249D76),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã nhận thuốc'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      final updated = await widget.orderApi.complete(_order.id);
      if (mounted) {
        setState(() => _order = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hoàn tất đơn ${_order.orderCode}!')),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = const Color(0xFF5267F4),
    Color? valueColor,
    bool isItalic = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? const Color(0xFF1E293B),
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
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
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF7F8FF),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Đơn: ${_order.orderCode}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Chip(
                  label: Text(_order.status.label),
                  backgroundColor: const Color(0xFFE7E9FF),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFieldCard(
                        icon: _order.fulfillmentType == FulfillmentType.pickup
                            ? Icons.storefront_rounded
                            : Icons.local_shipping_rounded,
                        iconColor: _order.fulfillmentType == FulfillmentType.pickup
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF2563EB),
                        label: 'Hình thức nhận thuốc',
                        value: _order.fulfillmentType.label,
                      ),
                      if (_order.recipientName != null && _order.recipientName!.isNotEmpty)
                        _buildFieldCard(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF0284C7),
                          label: 'Người nhận & Số điện thoại',
                          value: '${_order.recipientName}${_order.recipientPhone != null && _order.recipientPhone!.isNotEmpty ? ' • ${_order.recipientPhone}' : ''}',
                        ),
                      if (_order.deliveryAddress != null && _order.deliveryAddress!.isNotEmpty)
                        _buildFieldCard(
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFFE11D48),
                          label: 'Địa chỉ giao hàng',
                          value: _order.deliveryAddress!,
                        ),
                      if (_order.patientNote != null && _order.patientNote!.isNotEmpty)
                        _buildFieldCard(
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFFD97706),
                          label: 'Ghi chú bệnh nhân',
                          value: _order.patientNote!,
                          isItalic: true,
                        ),
                      if (_order.rejectionReason != null && _order.rejectionReason!.isNotEmpty)
                        _buildFieldCard(
                          icon: Icons.error_outline_rounded,
                          iconColor: const Color(0xFFDC2626),
                          valueColor: const Color(0xFFDC2626),
                          label: 'Lý do từ chối / hủy đơn',
                          value: _order.rejectionReason!,
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Danh sách thuốc trong đơn:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      for (final item in _order.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(
                                  '${item.quantity} ${item.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5267F4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: Color(0xFFC64E57))),
                      ],
                      const SizedBox(height: 20),
                      if (_order.status == PharmacyOrderStatus.pendingReview)
                        FilledButton.icon(
                          key: const Key('cancel-order-button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC64E57),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _acting ? null : _cancelOrder,
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(_acting ? 'Đang xử lý...' : 'Hủy đơn này'),
                        ),
                      if (_order.status == PharmacyOrderStatus.readyForPickup ||
                          _order.status == PharmacyOrderStatus.shipped)
                        FilledButton.icon(
                          key: const Key('complete-order-button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF249D76),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _acting ? null : _completeOrder,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(_acting ? 'Đang xử lý...' : 'Đã nhận được thuốc'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({super.key, required this.order, required this.onTap});

  final PharmacyOrder order;
  final VoidCallback onTap;

  (Color text, Color bg, IconData icon) get _statusMeta => switch (order.status) {
    PharmacyOrderStatus.pendingReview => (
      const Color(0xFFD97706),
      const Color(0xFFFEF3C7),
      Icons.access_time_rounded,
    ),
    PharmacyOrderStatus.preparing => (
      const Color(0xFF2563EB),
      const Color(0xFFDBEAFE),
      Icons.hourglass_top_rounded,
    ),
    PharmacyOrderStatus.readyForPickup => (
      const Color(0xFF7C3AED),
      const Color(0xFFEDE9FE),
      Icons.store_rounded,
    ),
    PharmacyOrderStatus.shipped => (
      const Color(0xFF0D9488),
      const Color(0xFFCCFBF1),
      Icons.local_shipping_rounded,
    ),
    PharmacyOrderStatus.completed => (
      const Color(0xFF16A34A),
      const Color(0xFFDCFCE7),
      Icons.check_circle_rounded,
    ),
    PharmacyOrderStatus.cancelled => (
      const Color(0xFFDC2626),
      const Color(0xFFFEE2E2),
      Icons.cancel_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor, statusIcon) = _statusMeta;
    final isPickup = order.fulfillmentType == FulfillmentType.pickup;
    final created = order.createdAt;
    final timeStr = created == null
        ? null
        : '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')} • ${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Glass(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPickup
                                ? const Color(0xFFF3E8FF)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPickup
                                ? Icons.storefront_rounded
                                : Icons.local_shipping_rounded,
                            color: isPickup
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderCode,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (timeStr != null)
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: textColor),
                          const SizedBox(width: 4),
                          Text(
                            order.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.medication_rounded,
                          size: 16,
                          color: Color(0xFF5267F4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.items
                                .map((i) => '${i.name} (x${i.quantity})')
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.fulfillmentType == FulfillmentType.pickup
                          ? 'Nhận tại quầy'
                          : 'Giao tận nơi',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5267F4),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF5267F4),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

