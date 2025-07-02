// lib/models/entry.dart
import 'package:flutter/material.dart';

// This file defines the Entry model for the Mind Garden application.
class Entry {
  final String id; // Unique identifier for the entry
  final String userId; // Identifier for the user who created the entry
  final String title; // Title of the entry
  final String content; // Content of the entry
  final DateTime entryDate; // Date and time when the entry was created
  final String? imageUrl; // Optional URL for an image associated with the entry
  final List<String>? tags; // Optional list of tags associated with the entry
  final String? color; // Stored as hex string
  final String? mood; // New mood field

  // Constructor for Entry class
  Entry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    this.imageUrl,
    this.tags,
    this.color,
    this.mood,
  });

  // Method to convert Entry object to JSON format
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
      mood: json['mood'] as String?,
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
