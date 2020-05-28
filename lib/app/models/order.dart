const int ORDER_ON_HOLD = 0;
const int ORDER_PLACED = 1;
const int ORDER_ACCEPTED = 2;
const int ORDER_DISPATCHED = 3;
const int ORDER_REJECTED = 4;
const int ORDER_CANCELLED = 5;

class Order {
  final String id;
  int orderNumber;
  final String restaurantId;
  final String restaurantName;
  final String managerId;
  final String userId;
  final double timestamp;
  int status;
  final String name;
  final String deliveryAddress;
  String paymentMethod;
  final List<Map<String, dynamic>> orderItems;
  String notes;
  bool isBlocked;

  Order({
    this.id,
    this.orderNumber,
    this.restaurantId,
    this.restaurantName,
    this.managerId,
    this.userId,
    this.timestamp,
    this.status,
    this.name,
    this.deliveryAddress,
    this.paymentMethod,
    this.orderItems,
    this.notes,
    this.isBlocked,
  });

  factory Order.fromMap(Map<String, dynamic> data, String documentID) {
    if (data == null) {
      return null;
    }
    List<Map<String, dynamic>> orderItems;
    if (data['orderItems'] != null) {
      orderItems = List.from(data['orderItems']);
    } else {
      orderItems = List<Map<String, dynamic>>();
    }
    return Order(
      id: data['id'],
      orderNumber: data['orderNumber'],
      restaurantId: data['restaurantId'],
      restaurantName: data['restaurantName'],
      managerId: data['managerId'],
      userId: data['userId'],
      timestamp: data['timestamp'],
      status: data['status'],
      name: data['name'],
      deliveryAddress: data['deliveryAddress'],
      paymentMethod: data['paymentMethod'],
      orderItems: orderItems,
      notes: data['notes'],
      isBlocked: data['isBlocked'],
    );
  }

  double get orderTotal {
    double total = 0;
    orderItems.forEach((element) {
      Map<String, dynamic> item = element;
      total += item['lineTotal'];
    });
    return total;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'managerId': managerId,
      'userId': userId,
      'timestamp': timestamp,
      'status': status,
      'name': name,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod ?? '',
      'orderItems': orderItems ?? [],
      'notes': notes,
      'isBlocked': isBlocked ?? false,
    };
  }

  String get statusString {
    String stString = '';
    switch (status) {
      case ORDER_ON_HOLD:
        stString = 'On hold';
        break;
      case ORDER_PLACED:
        stString = 'Placed, pending';
        break;
      case ORDER_ACCEPTED:
        stString = 'Accepted, in progress';
        break;
      case ORDER_DISPATCHED:
        stString = 'Completed, dispatched';
        break;
      case ORDER_REJECTED:
        stString = 'Rejected by staff';
        break;
      case ORDER_CANCELLED:
        stString = 'Cancelled by patron';
        break;
    }
    return stString;
  }

  @override
  String toString() {
    return 'id: $id, orderNumber: $orderNumber, restaurantId: $restaurantId, restaurantName: $restaurantName, managerId: $managerId, userId: $userId, timestamp: $timestamp, status: $status, name: $name, deliveryAddress: $deliveryAddress, paymentMethod: $paymentMethod, orderItems: $orderItems, notes: $notes, isBlocked: $isBlocked';
  }

}
