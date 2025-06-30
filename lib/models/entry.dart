// lib/models/entry.dart
import 'package:flutter/material.dart';

class Entry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime entryDate;
  final String? imageUrl;
  final List<String>? tags;
  final String? color; // Stored as hex string #AARRGGBB

  Entry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    this.imageUrl,
    this.tags,
    this.color,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      entryDate: DateTime.parse(json['entry_date'] as String),
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      color: json['color'] as String?,
    );
  }

  // Helper to convert hex string to Color
  Color? get displayColor {
    if (color == null || color!.isEmpty) return null;
    final buffer = StringBuffer();
    if (color!.length == 6 || color!.length == 7) buffer.write('ff');
    buffer.write(color!.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}