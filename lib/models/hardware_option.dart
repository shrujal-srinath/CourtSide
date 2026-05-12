class HardwareOption {
  const HardwareOption({
    required this.id,
    required this.name,
    required this.pricePerGame,
    required this.description,
    required this.icon,
    this.isPopular = false,
    this.originalPrice,
    this.isBundle = false,
  });

  final String id;
  final String name;
  final int pricePerGame;
  final String description;
  final String icon;
  final bool isPopular;
  final int? originalPrice;
  final bool isBundle;
}
