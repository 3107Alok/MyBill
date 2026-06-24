import 'package:hive/hive.dart';
import '../../domain/entities/bill.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 2)
class BillItemModel extends BillItem {
  @override
  @HiveField(0)
  final String productName;

  @override
  @HiveField(1)
  final double price;

  @override
  @HiveField(2)
  final int quantity;

  const BillItemModel({
    required this.productName,
    required this.price,
    required this.quantity,
  }) : super(
          productName: productName,
          price: price,
          quantity: quantity,
        );

  factory BillItemModel.fromEntity(BillItem entity) {
    return BillItemModel(
      productName: entity.productName,
      price: entity.price,
      quantity: entity.quantity,
    );
  }

  BillItem toEntity() {
    return BillItem(
      productName: productName,
      price: price,
      quantity: quantity,
    );
  }
}

@HiveType(typeId: 3)
class BillModel extends Bill {
  @override
  @HiveField(0)
  final String id;

  @override
  @HiveField(1)
  final DateTime dateTime;

  @override
  @HiveField(2)
  final List<BillItemModel> items;

  @override
  @HiveField(3)
  final double totalAmount;

  @override
  @HiveField(4)
  final String shopName;

  @override
  @HiveField(5)
  final String shopPhone;

  const BillModel({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
    required this.shopName,
    required this.shopPhone,
  }) : super(
          id: id,
          dateTime: dateTime,
          items: items,
          totalAmount: totalAmount,
          shopName: shopName,
          shopPhone: shopPhone,
        );

  factory BillModel.fromEntity(Bill entity) {
    return BillModel(
      id: entity.id,
      dateTime: entity.dateTime,
      items: entity.items.map((e) => BillItemModel.fromEntity(e)).toList(),
      totalAmount: entity.totalAmount,
      shopName: entity.shopName,
      shopPhone: entity.shopPhone,
    );
  }

  Bill toEntity() {
    return Bill(
      id: id,
      dateTime: dateTime,
      items: items.map((e) => e.toEntity()).toList(),
      totalAmount: totalAmount,
      shopName: shopName,
      shopPhone: shopPhone,
    );
  }
}
