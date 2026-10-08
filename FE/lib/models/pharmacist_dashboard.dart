import 'medicine.dart';

class PharmacyLocationSelection {
  const PharmacyLocationSelection({
    required this.addressText,
    required this.latitude,
    required this.longitude,
  });

  final String addressText;
  final double latitude;
  final double longitude;
}

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.pharmacistId,
    required this.name,
    required this.phoneNumber,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  final String id;
  final String pharmacistId;
  final String name;
  final String phoneNumber;
  final String addressText;
  final double latitude;
  final double longitude;
  final bool isActive;

  factory Pharmacy.fromJson(Map<String, dynamic> json) => Pharmacy(
    id: json['id']?.toString() ?? '',
    pharmacistId: json['pharmacistId']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phoneNumber: json['phoneNumber']?.toString() ?? '',
    addressText: json['addressText']?.toString() ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    isActive: json['isActive'] == true,
  );
}

class PharmacyInput {
  const PharmacyInput({
    required this.pharmacistId,
    required this.name,
    required this.phoneNumber,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  final String pharmacistId;
  final String name;
  final String phoneNumber;
  final String addressText;
  final double latitude;
  final double longitude;
  final bool isActive;

  Map<String, dynamic> toJson({bool includeOwner = true}) => {
    if (includeOwner) 'pharmacistId': pharmacistId,
    'name': name.trim(),
    'phoneNumber': phoneNumber.trim(),
    'addressText': addressText.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'isActive': isActive,
  };
}

class PharmacyInventoryItem {
  const PharmacyInventoryItem({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.stockQuantity,
    required this.pricePerUnit,
    this.medicine,
  });

  final String id;
  final String pharmacyId;
  final String medicineId;
  final int stockQuantity;
  final double pricePerUnit;
  final Medicine? medicine;

  String get displayName => medicine?.name ?? medicineId;
  MedicineUnit? get unit => medicine?.unit;

  factory PharmacyInventoryItem.fromJson(Map<String, dynamic> json) =>
      PharmacyInventoryItem(
        id: json['id']?.toString() ?? '',
        pharmacyId: json['pharmacyId']?.toString() ?? '',
        medicineId: json['medicineId']?.toString() ?? '',
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0,
      );

  PharmacyInventoryItem withMedicine(Medicine? value) => PharmacyInventoryItem(
    id: id,
    pharmacyId: pharmacyId,
    medicineId: medicineId,
    stockQuantity: stockQuantity,
    pricePerUnit: pricePerUnit,
    medicine: value,
  );
}

class InventoryInput {
  const InventoryInput({
    required this.medicineId,
    required this.stockQuantity,
    required this.pricePerUnit,
  });

  final String medicineId;
  final int stockQuantity;
  final double pricePerUnit;

  Map<String, dynamic> toJson() => {
    'medicineId': medicineId,
    'stockQuantity': stockQuantity,
    'pricePerUnit': pricePerUnit,
  };
}

enum PharmacyOrderStatus {
  pendingReview('PENDING_REVIEW', 'Chờ duyệt'),
  preparing('PREPARING', 'Đang chuẩn bị'),
  readyForPickup('READY_FOR_PICKUP', 'Chờ nhận'),
  shipped('SHIPPED', 'Đang giao'),
  completed('COMPLETED', 'Hoàn tất'),
  cancelled('CANCELLED', 'Đã huỷ');

  const PharmacyOrderStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PharmacyOrderStatus fromApi(String? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => PharmacyOrderStatus.pendingReview,
  );
}

enum FulfillmentType {
  pickup('PICKUP', 'Nhận tại quầy'),
  delivery('DELIVERY', 'Giao tận nơi');

  const FulfillmentType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static FulfillmentType fromApi(String? value) =>
      value == 'DELIVERY' ? FulfillmentType.delivery : FulfillmentType.pickup;
}

class PharmacyOrderItem {
  const PharmacyOrderItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String unit;
  final int quantity;
  final String? imageUrl;

  factory PharmacyOrderItem.fromJson(Map<String, dynamic> json) =>
      PharmacyOrderItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        unit: json['unit']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl']?.toString(),
      );
}

class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    required this.orderCode,
    required this.pharmacyId,
    required this.status,
    required this.fulfillmentType,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.recipientName,
    this.recipientPhone,
    this.deliveryAddress,
    this.patientNote,
    this.rejectionReason,
  });

  final String id;
  final String orderCode;
  final String pharmacyId;
  final PharmacyOrderStatus status;
  final FulfillmentType fulfillmentType;
  final double totalAmount;
  final DateTime? createdAt;
  final List<PharmacyOrderItem> items;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryAddress;
  final String? patientNote;
  final String? rejectionReason;

  bool get isHistory =>
      status == PharmacyOrderStatus.completed ||
      status == PharmacyOrderStatus.cancelled;

  factory PharmacyOrder.fromJson(Map<String, dynamic> json) => PharmacyOrder(
    id: json['id']?.toString() ?? '',
    orderCode: json['orderCode']?.toString() ?? '',
    pharmacyId: json['pharmacyId']?.toString() ?? '',
    status: PharmacyOrderStatus.fromApi(json['status']?.toString()),
    fulfillmentType: FulfillmentType.fromApi(
      json['fulfillmentType']?.toString(),
    ),
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    recipientName: json['recipientName']?.toString(),
    recipientPhone: json['recipientPhone']?.toString(),
    deliveryAddress: json['deliveryAddress']?.toString(),
    patientNote: json['patientNote']?.toString(),
    rejectionReason: json['rejectionReason']?.toString(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PharmacyOrderItem.fromJson)
        .toList(growable: false),
  );
}
