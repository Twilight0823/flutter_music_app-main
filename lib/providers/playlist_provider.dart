import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  List<Playlist> _userPlaylists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Playlist> get userPlaylists => _userPlaylists;
  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Song> get currentSongs => _currentPlaylist?.songs ?? [];

  // Get current user ID
  String get _userId => _auth.currentUser?.uid ?? '';

  // Private utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }
  
  void _updateCurrentPlaylistInList() {
    if (_currentPlaylist == null || _currentPlaylist!.id.isEmpty) return;
    
    final index = _userPlaylists.indexWhere((p) => p.id == _currentPlaylist!.id);
    if (index >= 0) {
      _userPlaylists[index] = _currentPlaylist!;
    } else {
      _userPlaylists.add(_currentPlaylist!);
    }
  }
  
  // Error handling wrapper for playlist operations
  Future<T> _performPlaylistOperation<T>(
    String operationName,
    Future<T> Function() operation
  ) async {
    _setLoading(true);
    _error = null;
    
    try {
      final result = await operation();
      return result;
    } catch (e) {
      debugPrint('Error $operationName: $e');
      _setError('Failed to $operationName: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Public methods
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set current playlist
  void setCurrentPlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  // Create new playlist
  Future<void> createNewPlaylist(String name) async {
    return _performPlaylistOperation('creating playlist', () async {
      final newPlaylist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        songs: [],
        createdAt: DateTime.now(),
        createdBy: _userId,
      );
      
      // Save to Firestore
      final playlistId = await _playlistService.savePlaylist(newPlaylist);
      final savedPlaylist = newPlaylist.copyWith(id: playlistId);
      
      _userPlaylists.add(savedPlaylist);
      _currentPlaylist = savedPlaylist;
      notifyListeners();
      return;
    });
  }

  // Update playlist attributes
  Future<void> updatePlaylist(
    String playlistId, {
    String? name,
  }) async {
    return _performPlaylistOperation('updating playlist', () async {
      final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
      if (index == -1) throw Exception('Playlist not found');

      final updatedPlaylist = _userPlaylists[index].copyWith(
        name: name ?? _userPlaylists[index].name,
      );

      // Update in Firestore
      await _playlistService.updatePlaylist(updatedPlaylist);

      _userPlaylists[index] = updatedPlaylist;
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = updatedPlaylist;
      }

      notifyListeners();
      return;
    });
  }

  // Song management methods
  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    return _performPlaylistOperation('adding song', () async {
      final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
      if (index == -1) throw Exception('Playlist not found');

      // Check if song already exists
      if (_userPlaylists[index].songs.any((s) => s.id == song.id)) {
        return; // Song already in playlist, do nothing
      }

      final updatedPlaylist = _userPlaylists[index].copyWith(
        songs: [..._userPlaylists[index].songs, song],
      );

      // Update in Firestore
      await _playlistService.updatePlaylist(updatedPlaylist);

      _userPlaylists[index] = updatedPlaylist;
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = updatedPlaylist;
      }

      notifyListeners();
      return;
    });
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    return _performPlaylistOperation('removing song', () async {
      final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
      if (index == -1) throw Exception('Playlist not found');

      final updatedSongs = _userPlaylists[index].songs
          .where((song) => song.id != songId)
          .toList();

      final updatedPlaylist = _userPlaylists[index].copyWith(
        songs: updatedSongs,
      );

      // Update in Firestore
      await _playlistService.updatePlaylist(updatedPlaylist);

      _userPlaylists[index] = updatedPlaylist;
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = updatedPlaylist;
      }

      notifyListeners();
      return;
    });
  }

  // Add reorderSongs method to allow reordering of songs in playlist
  void reorderSongs(int oldIndex, int newIndex) {
    if (_currentPlaylist == null) return;
    
    if (oldIndex < newIndex) {
      // Removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }

    final List<Song> updatedSongs = List<Song>.from(_currentPlaylist?.songs ?? []);
    final Song song = updatedSongs.removeAt(oldIndex);
    updatedSongs.insert(newIndex, song);

    _currentPlaylist = _currentPlaylist?.copyWith(songs: updatedSongs) ?? _currentPlaylist;
    notifyListeners();
  }

  // Rename current playlist
  void renamePlaylist(String newName) {
    if (_currentPlaylist == null) return;
    
    _currentPlaylist = _currentPlaylist?.copyWith(name: newName) ?? _currentPlaylist;
    notifyListeners();
  }

  // Clear current playlist
  void clearPlaylist() {
    _currentPlaylist = null;
    notifyListeners();
  }

  // Save current playlist to Firebase
  Future<String> savePlaylist() async {
    return _performPlaylistOperation('saving playlist', () async {
      if (_currentPlaylist == null) {
        throw Exception('No current playlist to save');
      }
      
      final playlistId = await _playlistService.savePlaylist(_currentPlaylist!);
      _currentPlaylist = _currentPlaylist?.copyWith(id: playlistId) ?? _currentPlaylist;
      
      _updateCurrentPlaylistInList();
      notifyListeners();
      return playlistId;
    });
  }

  // Load playlist by ID
  Future<void> loadPlaylist(String playlistId) async {
    return _performPlaylistOperation('loading playlist', () async {
      final playlist = await _playlistService.loadPlaylist(playlistId);
      _currentPlaylist = playlist;
      notifyListeners();
      return;
    });
  }

  // Import playlist by ID
  Future<bool> importPlaylist(String playlistId) async {
    return _performPlaylistOperation('importing playlist', () async {
      // First, load the shared playlist data
      final playlist = await _playlistService.loadPlaylist(playlistId);
      
      // Create a copy with a new ID and set the current user as creator
      final importedPlaylist = playlist.copyWith(
        id: '', // Will generate new ID when saved
        createdBy: _userId, // Set the current user as creator
      );
      
      // Save the imported playlist to user's account
      final newPlaylistId = await _playlistService.savePlaylist(importedPlaylist);
      
      // Create the final playlist with the new ID
      final finalPlaylist = importedPlaylist.copyWith(id: newPlaylistId);
      
      // Add to user's playlists
      _userPlaylists.add(finalPlaylist);
      
      // Set as current playlist
      _currentPlaylist = finalPlaylist;
      
      debugPrint('Successfully imported playlist: ${finalPlaylist.name}');
      notifyListeners();
      return true;
    });
  }

  // Load all user playlists
  Future<void> loadUserPlaylists() async {
    return _performPlaylistOperation('loading user playlists', () async {
      _userPlaylists = await _playlistService.getUserPlaylists();
      debugPrint('Loaded ${_userPlaylists.length} playlists from Firestore');
      notifyListeners();
      return;
    });
  }

  // Delete playlist
  Future<void> deletePlaylist(String playlistId) async {
    return _performPlaylistOperation('deleting playlist', () async {
      await _playlistService.deletePlaylist(playlistId);
      _userPlaylists.removeWhere((playlist) => playlist.id == playlistId);
      
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = null;
      }
      notifyListeners();
      return;
    });
  }

  // Update current playlist in Firestore
  Future<void> updateCurrentPlaylist() async {
    if (_currentPlaylist == null) return;
    
    if (_currentPlaylist?.id == null || _currentPlaylist!.id.isEmpty) {
      await savePlaylist();
      return;
    }
    
    return _performPlaylistOperation('updating current playlist', () async {
      await _playlistService.updatePlaylist(_currentPlaylist!);
      _updateCurrentPlaylistInList();
      return;
    });
  }

  // Simplified song management for current playlist
  void removeFromPlaylist(String id) {
    if (_currentPlaylist == null) return;
    final updatedSongs = _currentPlaylist!.songs.where((s) => s.id != id).toList();
    _currentPlaylist = _currentPlaylist!.copyWith(songs: updatedSongs);
    notifyListeners();
  }

  void addToPlaylist(Song song) {
    if (_currentPlaylist == null) return;
    if (_currentPlaylist!.songs.any((s) => s.id == song.id)) return;
    final updatedSongs = [..._currentPlaylist!.songs, song];
    _currentPlaylist = _currentPlaylist!.copyWith(songs: updatedSongs);
    notifyListeners();
  }
}