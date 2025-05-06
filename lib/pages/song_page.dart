import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../providers/playlist_provider.dart';

class SongPage extends StatefulWidget {
  final Song song;
  final bool shouldPlayOnLoad;

  const SongPage({
    super.key,
    required this.song,
    this.shouldPlayOnLoad = true,
  });

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> with AutomaticKeepAliveClientMixin {
  // Keep the state alive to prevent rebuilding when navigating
  @override
  bool get wantKeepAlive => true;

  // Pre-cached image for smoother transitions
  late ImageProvider? _backgroundImage;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize image but don't precache yet
    if (widget.song.imageUrl.isNotEmpty) {
      _backgroundImage = NetworkImage(widget.song.imageUrl);
    }

    // Play song after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldPlayOnLoad) {
        _playCurrentSong();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Precache image here instead of initState
    if (widget.song.imageUrl.isNotEmpty && _backgroundImage != null) {
      precacheImage(_backgroundImage as ImageProvider<Object>, context).then((_) {
        if (mounted) {
          setState(() {
            _imageLoaded = true;
          });
        }
      }).catchError((e) {
        // Image failed to load
        if (mounted) {
          setState(() {
            _backgroundImage = null;
          });
        }
      });
    }
  }
  
  void _playCurrentSong() {
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (audioService.currentSong?.id != widget.song.id) {
      audioService.playSong(widget.song);
    }
  }
  
  void _showAddToPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<PlaylistProvider>(
          builder: (context, provider, child) {
            final playlists = provider.userPlaylists;
            
            if (playlists.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('No playlists available. Create a playlist first.'),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length + 1, // +1 for the header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Add to Playlist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
                
                final playlist = playlists[index - 1];
                final bool songExists = playlist.songs.any((s) => s.id == widget.song.id);
                
                return ListTile(
                  title: Text(playlist.name),
                  trailing: songExists 
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.add),
                  onTap: () async {
                    // Set the current playlist
                    provider.setCurrentPlaylist(playlist);
                    
                    if (songExists) {
                      // Remove song from the current playlist
                      provider.removeFromPlaylist(widget.song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed from ${playlist.name}')),
                        );
                      }
                    } else {
                      // Add song to the current playlist
                      provider.addToPlaylist(widget.song);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${playlist.name}')),
                        );
                      }
                    }
                    
                    // Save changes to the playlist
                    await provider.updateCurrentPlaylist();
                    
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildPlayPauseButton(AudioService audioService, bool isCurrentSong, bool isPlaying) {
    // Use fixed size container to prevent layout shifts
    return SizedBox(
      width: 72,
      height: 72,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: audioService.isBuffering && isCurrentSong
            ? Container(
                key: const ValueKey('loading'),
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 5,
                ),
              )
            : IconButton(
                key: ValueKey(isPlaying ? 'pause' : 'play'),
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Theme.of(context).colorScheme.primary,
                ),
                iconSize: 72,
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (isCurrentSong) {
                    audioService.togglePlayPause();
                  } else {
                    audioService.playSong(widget.song);
                  }
                },
              ),
      ),
    );
  }

  Future<void> _playPreviousSong(AudioService audioService) async {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final currentPlaylist = playlistProvider.currentPlaylist;
    
    if (currentPlaylist.songs.isNotEmpty) {
      // Find current song index in playlist
      final currentIndex = currentPlaylist.songs.indexWhere((s) => s.id == widget.song.id);
      
      if (currentIndex > 0) {
        // Stop current song first
        await audioService.stopPlayback();
        
        // Get previous song in playlist
        final previousSong = currentPlaylist.songs[currentIndex - 1];
        
        // Navigate with fade transition
        if (context.mounted) {
          // Create the page before transition
          final nextPage = SongPage(
            song: previousSong,
            shouldPlayOnLoad: true, // Auto-play after navigation completes
          );
          
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (context, animation, secondaryAnimation) => nextPage,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      }
    }
  }

  Future<void> _playNextSong(AudioService audioService) async {
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    final currentPlaylist = playlistProvider.currentPlaylist;
    
    if (currentPlaylist.songs.isNotEmpty) {
      // Find current song index in playlist
      final currentIndex = currentPlaylist.songs.indexWhere((s) => s.id == widget.song.id);
      
      if (currentIndex != -1 && currentIndex < currentPlaylist.songs.length - 1) {
        // Stop current song first
        await audioService.stopPlayback();
        
        // Get next song in playlist
        final nextSong = currentPlaylist.songs[currentIndex + 1];
        
        // Navigate with fade transition
        if (context.mounted) {
          // Create the page before transition
          final nextPage = SongPage(
            song: nextSong,
            shouldPlayOnLoad: true, // Auto-play after navigation completes
          );
          
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder: (context, animation, secondaryAnimation) => nextPage,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.black, // Set base color to prevent white flash
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Now Playing', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.white),
            onPressed: _showAddToPlaylistDialog,
            tooltip: 'Add to playlist',
          ),
        ],
      ),
      body: Consumer<AudioService>(
        builder: (context, audioService, child) {
          final isCurrentSong = audioService.currentSong?.id == widget.song.id;
          final isPlaying = isCurrentSong && audioService.isPlaying;
          
          return Stack(
            children: [
              // Background Image with Frosted Glass Effect
              _buildFrostedGlassBackground(context),
              
              // Content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Song image
                            Hero(
                              tag: 'song_image_${widget.song.id}',
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: _imageLoaded && _backgroundImage != null
                                    ? Image(
                                        image: _backgroundImage as ImageProvider<Object>,
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        filterQuality: FilterQuality.medium,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.music_note,
                                          size: 120,
                                        ),
                                      )
                                    : Container(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 120,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Song title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                widget.song.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Artist name
                            Text(
                              widget.song.artist,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Playback controls - Fixed height to prevent layout shifts
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress & time
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(audioService.position),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _formatDuration(audioService.duration),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          
                          // Seek bar
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Theme.of(context).colorScheme.primary,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.white,
                              trackHeight: 4.0,
                            ),
                            child: Slider(
                              value: audioService.position.inSeconds.toDouble(),
                              min: 0,
                              max: audioService.duration.inSeconds.toDouble() > 0 
                                  ? audioService.duration.inSeconds.toDouble() 
                                  : 1,
                              onChanged: (value) {
                                audioService.seekTo(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          
                          // Control buttons - Fixed height container to prevent layout shifts
                          SizedBox(
                            height: 72, // Fixed height to prevent shifts
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Previous song button
                                IconButton(
                                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                                  iconSize: 36,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _playPreviousSong(audioService),
                                ),
                                
                                // Rewind 10s
                                IconButton(
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                  iconSize: 36,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    final newPosition = audioService.position - const Duration(seconds: 10);
                                    audioService.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                                  },
                                ),
                                
                                // Play/Pause - Fixed size container
                                _buildPlayPauseButton(audioService, isCurrentSong, isPlaying),
                                
                                // Forward 10s
                                IconButton(
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                  iconSize: 36,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    final newPosition = audioService.position + const Duration(seconds: 10);
                                    if (newPosition < audioService.duration) {
                                      audioService.seekTo(newPosition);
                                    }
                                  },
                                ),
                                
                                // Next song button
                                IconButton(
                                  icon: const Icon(Icons.skip_next, color: Colors.white),
                                  iconSize: 36,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _playNextSong(audioService),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFrostedGlassBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image (blurred)
        if (_imageLoaded && _backgroundImage != null)
          Image(
            image: _backgroundImage as ImageProvider<Object>,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Reduce memory usage and image quality to help with pipeline issues
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          )
        else
          Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
            
        // Frosted glass effect - Use simpler filter to reduce pipeline pressure
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Add this method to your AudioService class
// 
// Future<void> stopPlayback() async {
//   // Implement this in your AudioService class to stop 
//   // the current playback completely before playing a new song
//   await _audioPlayer.stop();
//   _isPlaying = false;
//   notifyListeners();
// }