import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../models/medicine.dart';
import '../models/pharmacist_dashboard.dart';
import '../services/medicine_api.dart';
import '../services/pharmacy_api.dart';
import '../services/pharmacy_order_api.dart';

class PharmacistDashboardController extends ChangeNotifier {
  PharmacistDashboardController({
    required this.user,
    PharmacyApi? pharmacyApi,
    PharmacyOrderApi? orderApi,
    MedicineApi? medicineApi,
  }) : _pharmacyApi = pharmacyApi ?? PharmacyApi(),
       _orderApi = orderApi ?? PharmacyOrderApi(),
       _medicineApi = medicineApi ?? MedicineApi();

  final AuthUser user;
  final PharmacyApi _pharmacyApi;
  final PharmacyOrderApi _orderApi;
  final MedicineApi _medicineApi;

  List<Pharmacy> pharmacies = const [];
  List<PharmacyOrder> orders = const [];
  List<Medicine> medicines = const [];
  List<Medicine> catalogMedicines = const [];
  String? selectedPharmacyId;
  bool loading = false;
  bool saving = false;
  String? error;

  bool _initialized = false;
  Future<void>? _initializeInFlight;
  final Map<String, Pharmacy> _detailCache = {};
  final Map<String, List<PharmacyInventoryItem>> _inventoryCache = {};
  final Map<String, Future<List<PharmacyInventoryItem>>> _inventoryInFlight =
      {};

  Pharmacy? get selectedPharmacy {
    final id = selectedPharmacyId;
    if (id == null) return null;
    return _detailCache[id] ??
        pharmacies.where((item) => item.id == id).firstOrNull;
  }

  List<PharmacyInventoryItem> get inventory =>
      _inventoryCache[selectedPharmacyId] ?? const [];

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
    if (force) {
      _detailCache.clear();
      _inventoryCache.clear();
      _inventoryInFlight.clear();
    }
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _pharmacyApi.list(isActive: true),
        _pharmacyApi.list(isActive: false),
        _orderApi.listMine(),
      ]);
      final all = <Pharmacy>[
        ...(results[0] as List<Pharmacy>),
        ...(results[1] as List<Pharmacy>),
      ];
      pharmacies = all
          .where((pharmacy) => pharmacy.pharmacistId == user.id)
          .toList(growable: false);
      orders = results[2] as List<PharmacyOrder>;
      if (selectedPharmacyId == null ||
          !pharmacies.any((item) => item.id == selectedPharmacyId)) {
        selectedPharmacyId = pharmacies.firstOrNull?.id;
      }
      final pharmacyId = selectedPharmacyId;
      if (pharmacyId != null) {
        medicines = await _medicineApi.list();
        catalogMedicines = medicines;
        await Future.wait([
          loadPharmacyDetail(pharmacyId, force: force),
          loadInventory(pharmacyId, force: force),
        ]);
      } else {
        medicines = const [];
        catalogMedicines = const [];
      }
      _initialized = true;
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectPharmacy(String id) async {
    if (selectedPharmacyId == id) return;
    selectedPharmacyId = id;
    error = null;
    notifyListeners();
    try {
      await Future.wait([loadPharmacyDetail(id), loadInventory(id)]);
    } catch (exception) {
      error = exception.toString();
      notifyListeners();
    }
  }

  Future<Pharmacy> loadPharmacyDetail(String id, {bool force = false}) async {
    final cached = _detailCache[id];
    if (!force && cached != null) return cached;
    final pharmacy = await _pharmacyApi.getById(id);
    _detailCache[id] = pharmacy;
    _replacePharmacy(pharmacy);
    notifyListeners();
    return pharmacy;
  }

  Future<List<PharmacyInventoryItem>> loadInventory(
    String pharmacyId, {
    bool force = false,
  }) {
    final cached = _inventoryCache[pharmacyId];
    if (!force && cached != null) {
      return Future.value(cached);
    }
    final inFlight = _inventoryInFlight[pharmacyId];
    if (!force && inFlight != null) {
      return inFlight;
    }
    final future = _pharmacyApi.listInventory(pharmacyId).then((rows) {
      final byId = {for (final medicine in medicines) medicine.id: medicine};
      final enriched = rows
          .map((row) => row.withMedicine(byId[row.medicineId]))
          .toList(growable: false);
      _inventoryCache[pharmacyId] = enriched;
      notifyListeners();
      return enriched;
    });
    _inventoryInFlight[pharmacyId] = future;
    return future.whenComplete(() => _inventoryInFlight.remove(pharmacyId));
  }

  Future<void> savePharmacy(PharmacyInput input) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final currentId = selectedPharmacyId;
      final saved = currentId == null
          ? await _pharmacyApi.create(input)
          : await _pharmacyApi.update(currentId, input);
      _detailCache[saved.id] = saved;
      _replacePharmacy(saved);
      selectedPharmacyId = saved.id;
      _inventoryCache.putIfAbsent(saved.id, () => const []);
      if (currentId == null) {
        try {
          await _reloadMedicines();
        } catch (exception) {
          error = exception.toString();
        }
      }
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> saveInventory(InventoryInput input) async {
    final pharmacyId = selectedPharmacyId;
    if (pharmacyId == null) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _pharmacyApi.upsertInventory(pharmacyId, [input]);
      final rows = [...inventory];
      final medicine = medicines
          .where((item) => item.id == input.medicineId)
          .firstOrNull;
      for (final row in saved) {
        final enriched = row.withMedicine(medicine);
        final index = rows.indexWhere(
          (item) => item.medicineId == row.medicineId,
        );
        if (index < 0) {
          rows.add(enriched);
        } else {
          rows[index] = enriched;
        }
      }
      _inventoryCache[pharmacyId] = rows;
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> searchMedicines({String? search}) async {
    error = null;
    notifyListeners();
    try {
      catalogMedicines = await _medicineApi.list(search: search);
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<Medicine> loadMedicineDetail(String id) => _medicineApi.getById(id);

  Future<void> createMedicines(List<MedicineInput> inputs) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      for (final input in inputs) {
        await _medicineApi.create(input);
      }
      await _reloadMedicines();
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> updateMedicine(String id, MedicineInput input) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _medicineApi.update(id, input);
      await _reloadMedicines();
    } catch (exception) {
      error = exception.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> _reloadMedicines() async {
    medicines = await _medicineApi.list();
    catalogMedicines = medicines;
    final byId = {for (final medicine in medicines) medicine.id: medicine};
    for (final pharmacyId in _inventoryCache.keys.toList()) {
      _inventoryCache[pharmacyId] = _inventoryCache[pharmacyId]!
          .map((row) => row.withMedicine(byId[row.medicineId]))
          .toList(growable: false);
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

  void _replacePharmacy(Pharmacy pharmacy) {
    final rows = [...pharmacies];
    final index = rows.indexWhere((item) => item.id == pharmacy.id);
    if (index < 0) {
      rows.add(pharmacy);
    } else {
      rows[index] = pharmacy;
    }
    pharmacies = rows;
  }

  @override
  void dispose() {
    _pharmacyApi.close();
    _orderApi.close();
    _medicineApi.close();
    super.dispose();
  }
}
