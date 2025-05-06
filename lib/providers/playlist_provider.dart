import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> _userPlaylists = [];
  Playlist _currentPlaylist = Playlist.empty('My Playlist');
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Playlist> get userPlaylists => _userPlaylists;
  Playlist get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Song> get currentSongs => _currentPlaylist.songs;

  // Set current playlist
  void setCurrentPlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  // Create new playlist
  Future<void> createNewPlaylist(String name) async {
    _currentPlaylist = Playlist.empty(name);
    
    // Immediately save the new playlist to Firestore
    try {
      final playlistId = await _playlistService.savePlaylist(_currentPlaylist);
      _currentPlaylist = _currentPlaylist.copyWith(id: playlistId);
      
      // Add to local list
      if (!_userPlaylists.any((p) => p.id == playlistId)) {
        _userPlaylists.add(_currentPlaylist);
      }
    } catch (e) {
      debugPrint('Error creating new playlist: $e');
      _setError('Failed to create playlist: $e');
    }
    
    notifyListeners();
  }

  void addToPlaylist(Song song) {
    if (!_currentPlaylist.containsSong(song.id)) {
      final updatedSongs = List<Song>.from(_currentPlaylist.songs)..add(song);
      _currentPlaylist = _currentPlaylist.copyWith(songs: updatedSongs);
      notifyListeners();
    }
  }

  // Remove song from current playlist - The original method
  void removeFromPlaylist(String songId) {
    final updatedSongs = List<Song>.from(_currentPlaylist.songs)
      ..removeWhere((song) => song.id == songId);
    _currentPlaylist = _currentPlaylist.copyWith(songs: updatedSongs);
    notifyListeners();
  }

  // Add the new removeSongFromPlaylist method that's being called elsewhere
  void removeSongFromPlaylist(String songId) {
    // Simply call the existing method to maintain consistency
    removeFromPlaylist(songId);
  }

  // Add reorderSongs method to allow reordering of songs in playlist
  void reorderSongs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      // Removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }

    final List<Song> updatedSongs = List<Song>.from(_currentPlaylist.songs);
    final Song song = updatedSongs.removeAt(oldIndex);
    updatedSongs.insert(newIndex, song);

    _currentPlaylist = _currentPlaylist.copyWith(songs: updatedSongs);
    notifyListeners();
  }

  // Toggle playlist visibility
  void toggleVisibility() {
    _currentPlaylist = _currentPlaylist.copyWith(isPublic: !_currentPlaylist.isPublic);
    notifyListeners();
  }

  // Rename current playlist
  void renamePlaylist(String newName) {
    _currentPlaylist = _currentPlaylist.copyWith(name: newName);
    notifyListeners();
  }

  // Clear current playlist
  void clearPlaylist() {
    _currentPlaylist = _currentPlaylist.copyWith(songs: []);
    notifyListeners();
  }

  // Save current playlist to Firebase
  Future<String> savePlaylist() async {
    _setLoading(true);
    try {
      final playlistId = await _playlistService.savePlaylist(_currentPlaylist);
      _currentPlaylist = _currentPlaylist.copyWith(id: playlistId);
      
      // Update local playlists array
      final index = _userPlaylists.indexWhere((p) => p.id == playlistId);
      if (index >= 0) {
        _userPlaylists[index] = _currentPlaylist;
      } else {
        _userPlaylists.add(_currentPlaylist);
      }
      
      notifyListeners();
      return playlistId;
    } catch (e) {
      debugPrint('Error saving playlist: $e');
      _setError('Failed to save playlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load playlist by ID
  Future<void> loadPlaylist(String playlistId) async {
    _setLoading(true);
    try {
      final playlist = await _playlistService.loadPlaylist(playlistId);
      _currentPlaylist = playlist;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading playlist: $e');
      _setError('Failed to load playlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Import playlist by ID - NEW METHOD
  Future<bool> importPlaylist(String playlistId) async {
    _setLoading(true);
    _error = null;
    
    try {
      // First, load the shared playlist data
      final playlist = await _playlistService.loadPlaylist(playlistId);
      
      // Create a copy with a different ID to store as user's own
      final importedPlaylist = playlist.copyWith(
        id: null, // Will generate new ID when saved
        name: playlist.name,
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
    } catch (e) {
      debugPrint('Error importing playlist: $e');
      _setError('Failed to import playlist: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load all user playlists
  Future<void> loadUserPlaylists() async {
    _setLoading(true);
    try {
      _userPlaylists = await _playlistService.getUserPlaylists();
      debugPrint('Loaded ${_userPlaylists.length} playlists from Firestore');
      
      // Force UI update
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user playlists: $e');
      _setError('Failed to load playlists: $e');
      _userPlaylists = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Delete playlist
  Future<void> deletePlaylist(String playlistId) async {
    _setLoading(true);
    try {
      await _playlistService.deletePlaylist(playlistId);
      _userPlaylists.removeWhere((playlist) => playlist.id == playlistId);
      
      // If deleted the current playlist, create a new empty one
      if (_currentPlaylist.id == playlistId) {
        _currentPlaylist = Playlist.empty('My Playlist');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      _setError('Failed to delete playlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update current playlist in Firestore
  Future<void> updateCurrentPlaylist() async {
    if (_currentPlaylist.id == null || _currentPlaylist.id!.isEmpty) {
      await savePlaylist();
      return;
    }
    
    _setLoading(true);
    try {
      await _playlistService.updatePlaylist(_currentPlaylist);
      
      // Update local playlists array
      final index = _userPlaylists.indexWhere((p) => p.id == _currentPlaylist.id);
      if (index >= 0) {
        _userPlaylists[index] = _currentPlaylist;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      _setError('Failed to update playlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}