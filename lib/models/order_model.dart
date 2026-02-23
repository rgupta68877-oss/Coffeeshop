import 'package:cloud_firestore/cloud_firestore.dart';

class StatusHistory {
  final String status;
  final String time;

  StatusHistory({required this.status, required this.time});

  factory StatusHistory.fromJson(Map<String, dynamic> json) =>
      StatusHistory(status: json['status'], time: json['time']);

  Map<String, dynamic> toJson() => {'status': status, 'time': time};
}

class OrderItem {
  final String itemId;
  final String name;
  final double price;
  final int qty;
  final String notes;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.qty,
    this.notes = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itemId: json['itemId'],
    name: json['name'],
    price: json['price'].toDouble(),
    qty: json['qty'],
    notes: json['notes'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'price': price,
    'qty': qty,
    'notes': notes,
  };
}

class OrderModel {
  final String orderId;
  final String shopId;
  final String shopName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final List<StatusHistory> statusHistory;
  final String createdAt;

  OrderModel({
    required this.orderId,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.statusHistory,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    orderId: json['orderId'],
    shopId: json['shopId'],
    shopName: json['shopName'],
    customerId: json['customerId'],
    customerName: json['customerName'],
    customerPhone: json['customerPhone'] ?? '',
    items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
    totalAmount: json['totalAmount'].toDouble(),
    status: json['status'],
    statusHistory: (json['statusHistory'] as List)
        .map((s) => StatusHistory.fromJson(s))
        .toList(),
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate().toString()
        : json['createdAt'].toString(),
  );

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'shopId': shopId,
    'shopName': shopName,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'items': items.map((i) => i.toJson()).toList(),
    'totalAmount': totalAmount,
    'status': status,
    'statusHistory': statusHistory.map((s) => s.toJson()).toList(),
    'createdAt': createdAt,
  };
}
