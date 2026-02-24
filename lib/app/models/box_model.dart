import 'package:buy_control/app/models/product_model.dart';
import 'package:uuid/uuid.dart';

class BoxModel {
  final String id;
  String name;
  List<ProductModel> products;
  final DateTime createdAt;
  DateTime updatedAt;

  BoxModel({
    String? id,
    required this.name,
    List<ProductModel>? products,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v1(),
       products = products ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = createdAt ?? DateTime.now();

  factory BoxModel.fromMap(Map<String, dynamic> map) {
    return BoxModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      products: map['products'] != null
          ? (map['products'] as List)
                .map((p) => ProductModel.fromMap(Map<String, dynamic>.from(p)))
                .toList()
          : [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
                ? DateTime.parse(map['createdAt'] as String)
                : map['createdAt'] as DateTime)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is String
                ? DateTime.parse(map['updatedAt'] as String)
                : map['updatedAt'] as DateTime)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'products': products.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BoxModel copyWith({
    String? id,
    String? name,
    String? description,
    List<ProductModel>? products,
    DateTime? createdAt,
  }) {
    return BoxModel(
      id: id ?? this.id,
      name: name ?? this.name,
      products: products ?? this.products,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double calculateTotalPrice() {
    return products.fold(
      0.0,
      (total, product) => total + (product.price * product.quantity),
    );
  }

  int getTotalQuantity() {
    return products.fold(0, (total, product) => total + product.quantity);
  }

  void addProduct(ProductModel product) {
    products.add(product);
    updatedAt = DateTime.now();
  }

  void updateProduct(ProductModel product) {
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
    }
    updatedAt = DateTime.now();
  }

  void updateLastUpdate() {
    updatedAt = DateTime.now();
  }
}
