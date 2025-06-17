import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart'; // For actual video playback
// import 'package:chewie/chewie.dart'; // For UI controls for video player

class VideoCarouselWidget extends StatefulWidget {
  final List<String> videoUrls;

  const VideoCarouselWidget({super.key, required this.videoUrls});

  @override
  State<VideoCarouselWidget> createState() => _VideoCarouselWidgetState();
}

class _VideoCarouselWidgetState extends State<VideoCarouselWidget> {
  // VideoPlayerController? _controller;
  // ChewieController? _chewieController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // _initializePlayer(widget.videoUrls.first); // Initialize with the first video
  }

  // Future<void> _initializePlayer(String videoUrl) async {
  //   _controller?.dispose();
  //   _chewieController?.dispose();

  //   _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
  //   await _controller!.initialize();
  //   _chewieController = ChewieController(
  //     videoPlayerController: _controller!,
  //     autoPlay: false,
  //     looping: false,
  //     // aspectRatio: 16/9, // Adjust as needed
  //     // placeholder: const Center(child: CircularProgressIndicator()), // Show while loading
  //     // errorBuilder: (context, errorMessage) {
  //     //   return Center(child: Text("Video Error: $errorMessage", style: TextStyle(color: Colors.white)));
  //     // },
  //   );
  //   setState(() {});
  // }

  @override
  void dispose() {
    // _controller?.dispose();
    // _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrls.isEmpty) {
      return const Text("No videos available for this gift yet.",
          style: TextStyle(color: Colors.white70));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey),
            ),
            // child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            //     ? Chewie(controller: _chewieController!)
            //     : Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.white54)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 60, color: Colors.white54),
                  SizedBox(height: 8),
                  Text(
                      "Video Player Placeholder\nVideo ${(_currentIndex + 1)}: ${widget.videoUrls[_currentIndex].split('/').last}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        if (widget.videoUrls.length > 1)
          SizedBox(
            height: 80, // Adjust height for thumbnails
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.videoUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // _initializePlayer(widget.videoUrls[index]);
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: Container(
                    width: 120, // Thumbnail width
                    margin: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index
                            ? Colors.amberAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black26,
                      // image: DecorationImage( // For actual video thumbnails
                      //   image: NetworkImage("https://your-thumbnail-service.com/thumb?url=${widget.videoUrls[index]}"),
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                    child: Center(
                        child: Icon(Icons.play_arrow,
                            color: Colors.white,
                            size: _currentIndex == index ? 30 : 20)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
