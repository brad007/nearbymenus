class Item {
  final String id;
  final String sectionId;
  final String name;
  final String description;
  final double price;
  final bool isExtra;
  final bool isSide;

  Item({
    this.id,
    this.sectionId,
    this.name,
    this.description,
    this.price,
    this.isExtra,
    this.isSide,
  });

  factory Item.fromMap(Map<String, dynamic> data, String documentID) {
    if (data == null) {
      return null;
    }
    return Item(
      id: data['id'],
      sectionId: data['sectionId'],
      name: data['name'],
      description: data['description'],
      price: data['price'],
      isExtra: data['isExtra'],
      isSide: data['isSide'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sectionId': sectionId,
      'name': name,
      'description': description,
      'price': price,
      'isExtra': isExtra,
      'isSide': isSide,
    };
  }

  @override
  String toString() {
    return 'id: $id, sectionId: $sectionId, name: $name, description: $description, price: $price, isExtra: $isExtra, isSide: $isSide';
  }

}
