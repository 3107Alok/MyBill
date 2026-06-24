import 'package:equatable/equatable.dart';

class Bill extends Equatable {
  final String id;
  final DateTime dateTime;
  final List<BillItem> items;
  final double totalAmount;
  final String shopName;
  final String shopPhone;

  const Bill({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
    required this.shopName,
    required this.shopPhone,
  });

  @override
  List<Object?> get props => [id, dateTime, items, totalAmount, shopName, shopPhone];
}

class BillItem extends Equatable {
  final String productName;
  final double price;
  final int quantity;

  const BillItem({
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  @override
  List<Object?> get props => [productName, price, quantity];
}
