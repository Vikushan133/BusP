class Item {
  final String? id;
  final String userId;
  final String objectName;
  final String busNumber;
  final DateTime date;
  final String time;
  final String location;
  final String description;
  final String? photoUrl;
  final String contactName;
  final String phone;
  final DateTime createdAt;

  Item({
    this.id,
    required this.userId,
    required this.objectName,
    required this.busNumber,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    this.photoUrl,
    required this.contactName,
    required this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'objectName': objectName,
      'busNumber': busNumber,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'description': description,
      'photoUrl': photoUrl,
      'contactName': contactName,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      userId: map['userId'] ?? '',
      objectName: map['objectName'] ?? '',
      busNumber: map['busNumber'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'],
      contactName: map['contactName'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}