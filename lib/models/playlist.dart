import 'song.dart';

class Playlist {
  final String? id;
  final String name;
  final List<Song> songs;
  final bool isPublic;
  final String? createdBy;

  Playlist({
    this.id,
    required this.name,
    required this.songs,
    this.isPublic = false,
    this.createdBy,
  });

  // Copy constructor with optional parameter updates
  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    bool? isPublic,
    String? createdBy,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
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
    if (id == null) throw Exception('Playlist ID is required for sharing');
    return 'https://spatiplay.com/playlist/$id';
  }

  // Create an empty playlist
  factory Playlist.empty(String name) {
    return Playlist(
      name: name,
      songs: [],
      isPublic: false,
    );
  }

  @override
  String toString() {
    return 'Playlist{id: $id, name: $name, songs: ${songs.length}, isPublic: $isPublic}';
  }
}