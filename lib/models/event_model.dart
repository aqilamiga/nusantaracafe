import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final int quota;
  final int registeredUsersCount;
  final String imageUrl;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.quota,
    required this.registeredUsersCount,
    required this.imageUrl,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      quota: map['quota'] ?? 0,
      registeredUsersCount: map['registeredUsersCount'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'quota': quota,
      'registeredUsersCount': registeredUsersCount,
      'imageUrl': imageUrl,
    };
  }
}