import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final int maxQuota; // <-- Pastikan properti ini bernama maxQuota
  final int registeredUsersCount;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.maxQuota,
    required this.registeredUsersCount,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxQuota: map['maxQuota'] ?? map['quota'] ?? 0, // Fallback jika di Firestore dinamai quota
      registeredUsersCount: map['registeredUsersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'maxQuota': maxQuota,
      'registeredUsersCount': registeredUsersCount,
    };
  }
}