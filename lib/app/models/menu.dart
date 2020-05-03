class Menu {
  final String id;
  final String restaurantId;
  final String name;
  final String notes;
  final bool hidden;
  final bool onlyForExtras;
  final bool onlyForSides;

  Menu({
    this.id,
    this.restaurantId,
    this.name,
    this.notes,
    this.hidden,
    this.onlyForExtras,
    this.onlyForSides,
  });

  factory Menu.fromMap(Map<String, dynamic> data, String documentID) {
    if (data == null) {
      return null;
    }
    return Menu(
      id: data['id'],
      restaurantId: data['restaurantId'],
      name: data['name'],
      notes: data['notes'],
      hidden: data['hidden'],
      onlyForExtras: data['onlyForExtras'],
      onlyForSides: data['onlyForSides'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantId': restaurantId,
      'name': name,
      'notes': notes,
      'hidden': hidden,
      'onlyForExtras': onlyForExtras,
      'onlyForSides': onlyForSides,
    };
  }

  @override
  String toString() {
    return 'id: $id, restaurantId: $restaurantId, name: $name, notes: $notes';
  }
}
