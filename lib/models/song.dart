class Song {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String audioUrl;
  final int duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
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
      imageUrl: artworkUrl,
      audioUrl: streamUrl,
      duration: (json['duration'] ?? 0).toInt(),
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      imageUrl: json['imageUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
    };
  }
}