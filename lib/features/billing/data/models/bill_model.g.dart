// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillItemModelAdapter extends TypeAdapter<BillItemModel> {
  @override
  final int typeId = 2;

  @override
  BillItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillItemModel(
      productName: fields[0] as String,
      price: fields[1] as double,
      quantity: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BillItemModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillModelAdapter extends TypeAdapter<BillModel> {
  @override
  final int typeId = 3;

  @override
  BillModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillModel(
      id: fields[0] as String,
      dateTime: fields[1] as DateTime,
      items: (fields[2] as List).cast<BillItemModel>(),
      totalAmount: fields[3] as double,
      shopName: fields[4] as String,
      shopPhone: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BillModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.shopName)
      ..writeByte(5)
      ..write(obj.shopPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
