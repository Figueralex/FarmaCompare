class Product {
  final String id;
  final String name;
  final String activeIngredient;
  final String presentation;
  final double price;
  final double? originalPrice;
  final String pharmacyName;
  final String imageUrl;
  final String productUrl;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.activeIngredient,
    required this.presentation,
    required this.price,
    this.originalPrice,
    required this.pharmacyName,
    required this.imageUrl,
    required this.productUrl,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPresentation = json['presentation'] as String? ?? '';
    double? parsedOriginalPrice;
    String cleanPresentation = rawPresentation;

    if (rawPresentation.contains(' || original_price:')) {
      final parts = rawPresentation.split(' || original_price:');
      cleanPresentation = parts[0];
      parsedOriginalPrice = double.tryParse(parts[1]);
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      activeIngredient: json['active_ingredient'] as String? ?? '',
      presentation: cleanPresentation,
      price: (json['price_usd'] as num).toDouble(),
      originalPrice: parsedOriginalPrice,
      pharmacyName: json['pharmacy_name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      productUrl: json['product_url'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
