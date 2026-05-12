class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;

  String get fullAddress => '$street, $area, $city - $pincode';

  DeliveryAddress copyWith({bool? isDefault}) => DeliveryAddress(
        id: id, label: label, name: name, phone: phone,
        street: street, area: area, city: city, pincode: pincode,
        isDefault: isDefault ?? this.isDefault,
      );
}
