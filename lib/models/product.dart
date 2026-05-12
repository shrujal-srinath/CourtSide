class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.image,
    required this.category,
    required this.description,
    this.brand = '',
    this.reviewCount = 0,
    this.inStock = true,
    this.specifications = const {},
    this.tags = const [],
  });

  final String id;
  final String name;
  final int price;
  final int originalPrice;
  final double rating;
  final String image;
  final String category;
  final String description;
  final String brand;
  final int reviewCount;
  final bool inStock;
  final Map<String, String> specifications;
  final List<String> tags;

  int get discountPercent => originalPrice == 0
      ? 0
      : ((originalPrice - price) / originalPrice * 100).round();
}

class ProductReview {
  const ProductReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.date,
    this.helpfulCount = 0,
    this.verified = true,
  });

  final String id;
  final String userName;
  final double rating;
  final String title;
  final String comment;
  final String date;
  final int helpfulCount;
  final bool verified;
}
