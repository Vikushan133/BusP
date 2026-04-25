class Problem {
  final String? id;
  final String userId;
  final String busLine;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String? photoUrl;
  final bool isAnonymous;
  final String status;
  final DateTime createdAt;

  Problem({
    this.id,
    required this.userId,
    required this.busLine,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    this.photoUrl,
    required this.isAnonymous,
    this.status = 'submitted',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'busLine': busLine,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Problem.fromMap(Map<String, dynamic> map) {
    return Problem(
      id: map['id'],
      userId: map['userId'] ?? '',
      busLine: map['busLine'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      photoUrl: map['photoUrl'],
      isAnonymous: map['isAnonymous'] ?? false,
      status: map['status'] ?? 'submitted',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}