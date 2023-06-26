import 'dart:convert';

class Event {
  final String timestamp;
  final String level;
  final String message;

  Event({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  factory Event.fromJson(String json) {
    final data = jsonDecode(json);
    return Event(
      timestamp: data['timestamp'],
      level: data['level'],
      message: data['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'level': level,
      'message': message,
    };
  }
}
