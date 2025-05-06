import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/playlist_provider.dart';

class ImportPlaylistPage extends StatefulWidget {
  const ImportPlaylistPage({super.key});

  @override
  State<ImportPlaylistPage> createState() => _ImportPlaylistPageState();
}

class _ImportPlaylistPageState extends State<ImportPlaylistPage> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
  
  Future<void> _importPlaylist() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      setState(() => _error = 'Please enter a playlist link');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Extract playlist ID from link
      final uri = Uri.parse(link);
      final pathSegments = uri.pathSegments;
      
      // Only support spatiplay.com URL format
      String? playlistId;
      
      if ((uri.host == 'spatiplay.com' || uri.host.endsWith('.spatiplay.com')) && 
          pathSegments.length >= 2 && pathSegments[0] == 'playlist') {
        // Handle web link format: https://spatiplay.com/playlist/{id}
        playlistId = pathSegments[1];
      } else {
        throw Exception('Invalid playlist link format. Please enter a valid spatiplay.com URL.');
      }
      
      final playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
      
      // Load playlist by ID
      final success = await playlistProvider.importPlaylist(playlistId);
      
      if (!success) {
        throw Exception('Failed to import playlist');
      }
      
      // Navigate back to homepage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist imported successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Failed to import playlist: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final text = clipboardData!.text!;
      
      // Extract only the spatiplay.com URL if it's part of a larger text
      final RegExp urlRegex = RegExp(
        r'https?:\/\/(www\.)?spatiplay\.com\/playlist\/[a-zA-Z0-9_\-]+',
        caseSensitive: false,
      );
      
      final match = urlRegex.firstMatch(text);
      if (match != null) {
        setState(() {
          _linkController.text = match.group(0)!;
        });
      } else {
        setState(() {
          _linkController.text = text;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Playlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image at the top
            const Icon(
              Icons.playlist_add_check,
              size: 80,
              color: Colors.grey,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Import a Shared Playlist',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Paste a spatiplay playlist link to import it',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Text field for link
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Playlist Link',
                hintText: 'https://spatiplay.com/playlist/...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Paste from clipboard',
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _importPlaylist(),
            ),
            
            const SizedBox(height: 8),
            
            // Error message
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            
            const SizedBox(height: 24),
            
            // Import button
            ElevatedButton(
              onPressed: _isLoading ? null : _importPlaylist,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : const Text('IMPORT PLAYLIST'),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
  }
}