import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final String coverImageUrl;
  final String createdBy; // Added createdBy field

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
    this.coverImageUrl = '',
    required this.createdBy, // Required in constructor
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List?)
          ?.map((songJson) => Song.fromJson(songJson as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as DateTime),
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '', // Added to fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs.map((song) => song.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'createdBy': createdBy, // Added to toJson
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    DateTime? createdAt,
    String? coverImageUrl,
    String? createdBy, // Added to copyWith
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdBy: createdBy ?? this.createdBy, // Added to copyWith
    );
  }

  // Get playlist size
  int get songCount => songs.length;

  // Check if playlist contains a song
  bool containsSong(String songId) {
    return songs.any((song) => song.id == songId);
  }

  // Generate a shareable link
  String generateShareLink() {
    return 'https://spatiplay.com/playlist/$id';
  }

  // Create an empty playlist with creator
  factory Playlist.empty(String name, String userId) {
    return Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
      createdBy: userId, // Added userId parameter
    );
  }

  @override
  String toString() {
    return 'Playlist{id: $id, name: $name, songs: ${songs.length}, createdAt: $createdAt, createdBy: $createdBy}';
  }
}