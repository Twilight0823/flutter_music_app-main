import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import '../models/song.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isBuffering = true; // Start with true since it'll buffer when first loaded
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Add a property to track retries
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  AudioService() {
    _setupListeners();
  }

  // Getters for state
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isInitialized && !_isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isLoading => _isBuffering;
  Duration get duration => _duration;
  Duration get position => _position;
  double get progress => _duration.inSeconds > 0 
    ? _position.inSeconds / _duration.inSeconds 
    : 0.0;

  void _setupListeners() {
    // Player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      
      // Update buffering state based on processing state
      final oldBuffering = _isBuffering;
      _isBuffering = playerState.processingState == ProcessingState.loading || 
                      playerState.processingState == ProcessingState.buffering;
      
      // Only notify if there's an actual change in buffering state
      if (oldBuffering != _isBuffering || _isPlaying != playerState.playing) {
        debugPrint('Buffering state change: $_isBuffering, Playing: $_isPlaying');
        notifyListeners();
      }
    });

    // Duration changes
    _audioPlayer.durationStream.listen((newDuration) {
      if (newDuration != null) {
        _duration = newDuration;
        notifyListeners();
      }
    });

    // Position changes
    _audioPlayer.positionStream.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    // Completion listener
    _audioPlayer.processingStateStream.listen((state) {
      // Update buffering state for all processing state changes
      final oldBuffering = _isBuffering;
      _isBuffering = state == ProcessingState.loading || state == ProcessingState.buffering;
      
      // Log state changes for debugging
      debugPrint('Processing state: $state, Buffering: $_isBuffering');
      
      // Handle completion
      if (state == ProcessingState.completed) {
        _position = Duration.zero;
        _isPlaying = false;
      }
      
      // Only notify if there's an actual change in buffering state
      if (oldBuffering != _isBuffering || state == ProcessingState.completed) {
        notifyListeners();
      }
    });
  }
  
  // Method to clear the current song (hide mini player)
  void clearCurrentSong() {
    _currentSong = null;
    _isInitialized = false;
    notifyListeners();
  }
  
  // Simpler playSong method using direct approach from old implementation
  Future<void> playSong(Song song) async {
    // Set buffering to true immediately and notify
    _isBuffering = true;
    _retryCount = 0;
    notifyListeners();
    
    try {
      await _audioPlayer.stop();
      
      // Try with the simple, direct approach first (from your old code)
      final streamUrl = 'https://api.audius.co/v1/tracks/${song.id}/stream?app_name=spatiplay';
      
      debugPrint('Attempting to play from: $streamUrl');
      
      // Set audio source with proper error handling
      await _audioPlayer.setUrl(streamUrl);
      
      // Update current song before playing to ensure UI shows the right song
      _currentSong = song;
      _isInitialized = true;
      notifyListeners();
      
      // Now play the song
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing song with direct method: $e');
      
      // Try fallback methods
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await _retryWithAlternatives(song);
      } else {
        _isInitialized = false;
        _isBuffering = false;
        notifyListeners();
        rethrow; // Pass the error up if all methods fail
      }
    } finally {
      // Make sure we update isBuffering in finally block for error cases
      // The stream listener should handle the success case
      if (!_isInitialized) {
        _isBuffering = false;
        notifyListeners();
      }
    }
  }
  
  // Simplified retry method focusing on working URLs
  Future<void> _retryWithAlternatives(Song song) async {
    // Try these URLs in order - simplified from your original complex approach
    final urlOptions = [
      'https://audius.co/api/v1/tracks/${song.id}/stream',
      'https://api.audius.co/v1/tracks/${song.id}/stream?app_name=spatiplay',
      'https://discoveryprovider.audius.co/v1/tracks/${song.id}/stream?app_name=spatiplay'
    ];
    
    for (final url in urlOptions) {
      try {
        debugPrint('Retrying with URL: $url');
        
        // Set buffering state
        _isBuffering = true;
        notifyListeners();
        
        await _audioPlayer.setUrl(url);
        
        // Update current song before playing
        _currentSong = song;
        _isInitialized = true;
        notifyListeners();
        
      } catch (e) {
        debugPrint('URL $url failed: $e');
        // Continue to the next URL
      }
    }
  }
  
Future<void> stopPlayback() async {
  // Implement this in your AudioService class to stop 
  // the current playback completely before playing a new song
  await _audioPlayer.stop();
  _isPlaying = false;
  notifyListeners();
}

  Future<void> resume() async {
    if (!_isInitialized || _currentSong == null) return;
    await _audioPlayer.play();
    notifyListeners();
  }
  
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _audioPlayer.pause();
    notifyListeners();
  }
  
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _audioPlayer.stop();
    _position = Duration.zero;
    notifyListeners();
  }
  
  Future<void> seekTo(Duration position) async {
    if (!_isInitialized) return;
    
    // Set buffering while seeking
    _isBuffering = true;
    notifyListeners();
    
    await _audioPlayer.seek(position);
    
    // The state listener will update buffering state once seeking is done
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    await _audioPlayer.setVolume(volume);
  }

  void togglePlayPause() {
    if (isPlaying) {
      pause();
    } else {
      resume();
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}