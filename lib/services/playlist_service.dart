import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Save playlist to Firestore
  Future<String> savePlaylist(Playlist playlist) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final playlistData = {
      'name': playlist.name,
      'songs': playlist.songs.map((song) => song.toJson()).toList(),
      'isPublic': playlist.isPublic,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _userId,
    };

    try {
      final docRef = await _firestore.collection('playlists').add(playlistData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save playlist: $e');
    }
  }

  // Load playlist by ID
  Future<Playlist> loadPlaylist(String playlistId) async {
    try {
      final doc = await _firestore.collection('playlists').doc(playlistId).get();
      if (!doc.exists) throw Exception('Playlist not found');
      
      final data = doc.data()!;
      final List<dynamic> songsData = data['songs'] ?? [];
      final List<Song> songs = songsData.map((song) => Song.fromJson(song)).toList();
      
      return Playlist(
        id: doc.id,
        name: data['name'] ?? 'Untitled Playlist',
        songs: songs,
        isPublic: data['isPublic'] ?? false,
        createdBy: data['createdBy'],
      );
    } catch (e) {
      throw Exception('Failed to load playlist: $e');
    }
  }

  // Get all playlists for current user
  Future<List<Playlist>> getUserPlaylists() async {
  if (_userId == null) throw Exception('User not authenticated');
  
  try {
    // Simplified query that doesn't require a complex index
    final querySnapshot = await _firestore
        .collection('playlists')
        .where('createdBy', isEqualTo: _userId)
        .get();
    
    // Sort the results in Dart instead of in the query
    final results = querySnapshot.docs.map((doc) {
      final data = doc.data();
      final List<dynamic> songsData = data['songs'] ?? [];
      final List<Song> songs = songsData.map((song) => Song.fromJson(song)).toList();
      
      return Playlist(
        id: doc.id,
        name: data['name'] ?? 'Untitled Playlist',
        songs: songs,
        isPublic: data['isPublic'] ?? false,
        createdBy: data['createdBy'],
      );
    }).toList();
    
    // Sort by createdAt if available
    results.sort((a, b) {
      final aData = querySnapshot.docs.firstWhere((doc) => doc.id == a.id).data();
      final bData = querySnapshot.docs.firstWhere((doc) => doc.id == b.id).data();
      
      final aTime = aData['createdAt'] as Timestamp?;
      final bTime = bData['createdAt'] as Timestamp?;
      
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime); // Descending order
    });
    
    return results;
  } catch (e) {
    throw Exception('Failed to get user playlists: $e');
  }
}

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }
  
  // Update a playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (playlist.id == null) throw Exception('Playlist ID cannot be null');
    
    try {
      await _firestore.collection('playlists').doc(playlist.id).update({
        'name': playlist.name,
        'songs': playlist.songs.map((song) => song.toJson()).toList(),
        'isPublic': playlist.isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update playlist: $e');
    }
  }
}