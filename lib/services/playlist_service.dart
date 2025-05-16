import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;
  
  // Centralized error handler
  Exception _handleError(String operation, dynamic error) {
    return Exception('Failed to $operation: $error');
  }

  // Check user authentication 
  void _checkAuthentication() {
    if (_userId == null) throw Exception('User not authenticated');
  }

  // Convert Firestore data to Playlist object
  Playlist _convertToPlaylist(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> songsData = data['songs'] ?? [];
    final List<Song> songs = songsData.map((song) => Song.fromJson(song)).toList();
    
    return Playlist(
      id: doc.id,
      name: data['name'] ?? 'Untitled Playlist',
      songs: songs,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  // Save playlist to Firestore
  Future<String> savePlaylist(Playlist playlist) async {
    _checkAuthentication();
    
    final playlistData = {
      'name': playlist.name,
      'songs': playlist.songs.map((song) => song.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': playlist.createdBy.isNotEmpty ? playlist.createdBy : _userId,
      'coverImageUrl': playlist.coverImageUrl,
    };

    try {
      final docRef = await _firestore.collection('playlists').add(playlistData);
      return docRef.id;
    } catch (e) {
      throw _handleError('save playlist', e);
    }
  }

  // Load playlist by ID
  Future<Playlist> loadPlaylist(String playlistId) async {
    try {
      final doc = await _firestore.collection('playlists').doc(playlistId).get();
      if (!doc.exists) throw Exception('Playlist not found');
      
      return _convertToPlaylist(doc);
    } catch (e) {
      throw _handleError('load playlist', e);
    }
  }

  // Get all playlists for current user
  Future<List<Playlist>> getUserPlaylists() async {
    _checkAuthentication();
    
    try {
      final querySnapshot = await _firestore
          .collection('playlists')
          .where('createdBy', isEqualTo: _userId)
          .get();
      
      final results = querySnapshot.docs.map(_convertToPlaylist).toList();
      
      // Sort by createdAt if available
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return results;
    } catch (e) {
      throw _handleError('get user playlists', e);
    }
  }

  // Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    _checkAuthentication();
    
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
    } catch (e) {
      throw _handleError('delete playlist', e);
    }
  }
  
  // Update a playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    _checkAuthentication();
    
    try {
      await _firestore.collection('playlists').doc(playlist.id).update({
        'name': playlist.name,
        'songs': playlist.songs.map((song) => song.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'coverImageUrl': playlist.coverImageUrl,
      });
    } catch (e) {
      throw _handleError('update playlist', e);
    }
  }
}