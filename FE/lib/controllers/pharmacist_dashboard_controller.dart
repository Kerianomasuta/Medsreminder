import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../models/pharmacist_dashboard.dart';
import '../services/pharmacy_api.dart';
import '../services/pharmacy_order_api.dart';

class PharmacistDashboardController extends ChangeNotifier {
  PharmacistDashboardController({
    required this.user,
    PharmacyOrderApi? orderApi,
    PharmacyApi? pharmacyApi,
  }) : _orderApi = orderApi ?? PharmacyOrderApi(),
       _pharmacyApi = pharmacyApi ?? PharmacyApi();

  final AuthUser user;
  final PharmacyOrderApi _orderApi;
  final PharmacyApi _pharmacyApi;

  List<PharmacyOrder> orders = const [];
  Pharmacy? pharmacy;
  bool loading = false;
  bool saving = false;
  bool pharmacyLoading = false;
  String? error;
  String? pharmacyError;

  bool _initialized = false;
  Future<void>? _initializeInFlight;
  Future<void>? _pharmacyInFlight;
  bool _pharmacyLoaded = false;
  List<PharmacyOrder> get activeOrders =>
      orders.where((order) => !order.isHistory).toList(growable: false);

  List<PharmacyOrder> get historyOrders =>
      orders.where((order) => order.isHistory).toList(growable: false);

  Future<void> initialize({bool force = false}) {
    if (_initialized && !force) return Future.value();
    if (_initializeInFlight != null && !force) return _initializeInFlight!;
    final future = _loadAll(force: force);
    _initializeInFlight = future;
    return future.whenComplete(() {
      if (identical(_initializeInFlight, future)) _initializeInFlight = null;
    });
  }

  Future<void> _loadAll({required bool force}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      orders = await _orderApi.listMine();
      _initialized = true;
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> acceptOrder(String id) =>
      _changeOrder(() => _orderApi.accept(id));
  Future<void> rejectOrder(String id, String reason) =>
      _changeOrder(() => _orderApi.reject(id, reason));
  Future<void> markReady(String id) =>
      _changeOrder(() => _orderApi.markReady(id));
  Future<void> shipOrder(
    String id, {
    required String shipperName,
    required String shipperPhone,
  }) => _changeOrder(
    () => _orderApi.ship(
      id,
      shipperName: shipperName,
      shipperPhone: shipperPhone,
    ),
  );
  Future<void> cancelOrder(String id, String reason) =>
      _changeOrder(() => _orderApi.cancel(id, reason));

  Future<void> loadPharmacy({bool force = false}) {
    if (_pharmacyLoaded && !force) return Future.value();
    if (_pharmacyInFlight != null) return _pharmacyInFlight!;
    final future = _loadPharmacy();
    _pharmacyInFlight = future;
    return future.whenComplete(() {
      if (identical(_pharmacyInFlight, future)) _pharmacyInFlight = null;
    });
  }

  Future<void> _loadPharmacy() async {
    pharmacyLoading = true;
    pharmacyError = null;
    notifyListeners();
    try {
      pharmacy = await _pharmacyApi.getForPharmacist(user.id);
      _pharmacyLoaded = true;
    } catch (exception) {
      pharmacyError = exception.toString();
    } finally {
      pharmacyLoading = false;
      notifyListeners();
    }
  }

  Future<void> _changeOrder(Future<PharmacyOrder> Function() action) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final changed = await action();
      final rows = [...orders];
      final index = rows.indexWhere((item) => item.id == changed.id);
      if (index < 0) {
        rows.insert(0, changed);
      } else {
        rows[index] = changed;
      }
      orders = rows;
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _orderApi.close();
    _pharmacyApi.close();
    super.dispose();
  }
}
