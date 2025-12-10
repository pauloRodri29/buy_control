import 'package:uuid/uuid.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int quantity;

  ProductModel({
    String? id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
  }) : id = id ?? const Uuid().v1();

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
    };
  }
}
