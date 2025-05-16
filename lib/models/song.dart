class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String imageUrl;
  final String audioUrl;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
  });

  factory Song.fromAudiusJson(Map<String, dynamic> json) {
    // Extract the artist name
    final String artistName = json['user']['name'] ?? 'Unknown Artist';
    
    // Extract artwork URL with fallback to default
    String artworkUrl = '';
    if (json['artwork'] != null && json['artwork']['150x150'] != null) {
      artworkUrl = json['artwork']['150x150'];
    } else if (json['artwork'] != null && json['artwork']['480x480'] != null) {
      artworkUrl = json['artwork']['480x480'];
    }

    // UPDATED STREAMING URL APPROACH
    // Get the correct streaming URL using the updated endpoint structure
    String streamUrl = '';
    final String trackId = json['id']?.toString() ?? '';
    
    if (trackId.isNotEmpty) {
      // Use the updated API endpoint structure
      // Note: We're now using the official api.audius.co domain with v1 prefix
      streamUrl = 'https://discovery-au-01.audius.openplayer.org/v1/tracks/$trackId/stream?app_name=spatiplay';
    }

    return Song(
      id: trackId,
      title: json['title'] ?? 'Unknown Title',
      artist: artistName,
      album: json['album'] ?? 'Unknown Album',
      imageUrl: artworkUrl,
      audioUrl: streamUrl,
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? 'Unknown Album',
      imageUrl: json['imageUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      duration: Duration(seconds: json['duration'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    String? audioUrl,
    Duration? duration,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
    );
  }

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artist: $artist, album: $album}';
  }
}