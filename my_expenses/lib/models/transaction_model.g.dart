// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as TxType,
      category: fields[3] as String,
      amount: fields[4] as double,
      notes: fields[5] as String,
      paymentMethod: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TxTypeAdapter extends TypeAdapter<TxType> {
  @override
  final int typeId = 1;

  @override
  TxType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TxType.income;
      case 1:
        return TxType.expense;
      default:
        return TxType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TxType obj) {
    switch (obj) {
      case TxType.income:
        writer.writeByte(0);
        break;
      case TxType.expense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
