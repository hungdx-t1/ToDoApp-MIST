class Category {
  final int? id;
  final String name;
  final String hexColor;

  Category({
    this.id,
    required this.name,
    this.hexColor = '#2196F3', // default, màu blue
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hexColor': hexColor, // Lưu string màu
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      hexColor: map['hexColor'] ?? '#2196F3', // fallback về màu blue nếu hex null
    );
  }
}