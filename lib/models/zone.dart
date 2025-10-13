class Zone {
  final String name;
  final double price;
  final int capacity;

  Zone({
    required this.name,
    required this.price,
    required this.capacity,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'capacity': capacity,
    };
  }
}