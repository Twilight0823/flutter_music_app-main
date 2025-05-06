import 'package:flutter/material.dart';
import 'package:music_app/providers/playlist_provider.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/song.dart';
import '../pages/song_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final Song? currentSong = audioService.currentSong;
        
        if (currentSong == null) {
          return const SizedBox.shrink(); // No song playing
        }
        
        return GestureDetector(
          onTap: () {
            // Navigate to song page WITHOUT restarting the music
            // Fixed by NOT calling playSong again in navigation
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => SongPage(song: currentSong),
              ),
            );
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: audioService.progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                ),
                
                // Song info and controls
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Song image
                        Hero(
                          tag: 'song_image_${currentSong.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: currentSong.imageUrl.isNotEmpty
                                ? Image.network(
                                    currentSong.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 48),
                                  )
                                : const Icon(Icons.music_note, size: 48),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Song info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentSong.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                currentSong.artist,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Controls
                        // Show loading indicator when buffering
                        audioService.isBuffering
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: audioService.togglePlayPause,
                            ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // Get playlist provider
                            final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
                            final currentPlaylist = playlistProvider.currentPlaylist;
                            
                            if (currentPlaylist.songs.isNotEmpty) {
                              // Find current song index in playlist
                              final currentIndex = currentPlaylist.songs.indexWhere((s) => s.id == currentSong.id);
                              
                              if (currentIndex != -1 && currentIndex < currentPlaylist.songs.length - 1) {
                                // Play next song in playlist
                                final nextSong = currentPlaylist.songs[currentIndex + 1];
                                audioService.playSong(nextSong);
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            // Stop music and clear the current song to hide mini player
                            audioService.stop();
                            audioService.clearCurrentSong();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}