import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../utils/calculator.dart';
import 'big_result_screen.dart';

class AnalyzerScreen extends StatefulWidget {
  final String videoPath;
  final String fileName;
  final int? initialReleaseFrame;
  final int? initialImpactFrame;

  const AnalyzerScreen({
    super.key, 
    required this.videoPath, 
    required this.fileName,
    this.initialReleaseFrame,
    this.initialImpactFrame,
  });

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late VideoPlayerController _controller;
  List<Uint8List> _thumbnails = [];
  bool _isGeneratingThumbnails = true;
  
  int? _releaseFrame;
  int? _impactFrame;
  final double _fps = 30.0;
  final TransformationController _transformationController = TransformationController();

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  void initState() {
    super.initState();
    _releaseFrame = widget.initialReleaseFrame;
    _impactFrame = widget.initialImpactFrame;
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _generateThumbnails();
      });
  }

  Future<void> _generateThumbnails() async {
    final int duration = _controller.value.duration.inMilliseconds;
    final int step = duration ~/ 20;

    for (int i = 0; i < 20; i++) {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: i * step,
        quality: 50,
      );
      if (uint8list != null) {
        setState(() {
          _thumbnails.add(uint8list);
        });
      }
    }
    setState(() {
      _isGeneratingThumbnails = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markRelease() {
    setState(() {
      _releaseFrame = (_controller.value.position.inMilliseconds / 1000 * _fps).round();
    });
  }

  void _markImpact() {
    setState(() {
      _impactFrame = (_controller.value.position.inMilliseconds / 1000 * _fps).round();
    });
  }

  void _calculate() {
    if (_releaseFrame != null && _impactFrame != null) {
      final state = Provider.of<AppState>(context, listen: false);
      final kph = BowlingCalculator.calculateKph(_releaseFrame!, _impactFrame!, _fps, state.pitchLength);
      final mph = BowlingCalculator.kphToMph(kph);
      
      final result = SpeedResult(
        fileName: widget.fileName,
        videoPath: widget.videoPath,
        speedKph: kph,
        speedMph: mph,
        dateTime: DateTime.now(),
        releaseFrame: _releaseFrame!,
        impactFrame: _impactFrame!,
        pitchLength: state.pitchLength,
      );
      
      state.addResult(result);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BigResultScreen(speedKph: kph, speedMph: mph),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canCalculate = _releaseFrame != null && _impactFrame != null && _impactFrame! > _releaseFrame!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: canCalculate ? _calculate : null,
            child: Text(
              widget.initialReleaseFrame != null ? 'Update' : 'Calculate',
              style: TextStyle(
                color: canCalculate ? const Color(0xFF0091FF) : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _controller.value.isInitialized
                  ? Stack(
                      children: [
                        InteractiveViewer(
                          transformationController: _transformationController,
                          maxScale: 5.0,
                          minScale: 1.0,
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _resetZoom,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Reset View',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Frame',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: _isGeneratingThumbnails && _thumbnails.isEmpty
                      ? const Center(child: LinearProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _thumbnails.length,
                          itemBuilder: (context, index) {
                            final int duration = _controller.value.duration.inMilliseconds;
                            final int step = duration ~/ 20;
                            
                            bool isRelease = false;
                            if (_releaseFrame != null) {
                              int closestIndex = (_releaseFrame! / _fps * 1000 / step).round();
                              isRelease = index == closestIndex;
                            }
                            
                            bool isImpact = false;
                            if (_impactFrame != null) {
                              int closestIndex = (_impactFrame! / _fps * 1000 / step).round();
                              isImpact = index == closestIndex;
                            }

                            return GestureDetector(
                              onTap: () {
                                _controller.seekTo(Duration(milliseconds: index * step));
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isRelease ? Colors.green : (isImpact ? Colors.red : Colors.transparent),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: MemoryImage(_thumbnails[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (isRelease || isImpact)
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: isRelease ? Colors.green : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 10),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PlaybackButton(
                      icon: HugeIcons.strokeRoundedPrevious,
                      onPressed: () {
                        final pos = _controller.value.position;
                        _controller.seekTo(pos - const Duration(milliseconds: 33));
                      },
                    ),
                    _PlaybackButton(
                      icon: _controller.value.isPlaying 
                        ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
                      isMain: true,
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                    _PlaybackButton(
                      icon: HugeIcons.strokeRoundedNext,
                      onPressed: () {
                        final pos = _controller.value.position;
                        _controller.seekTo(pos + const Duration(milliseconds: 33));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _MarkButton(
                        label: _releaseFrame != null ? '✓ Release: $_releaseFrame' : 'Mark Release',
                        isMarked: _releaseFrame != null,
                        color: Colors.green,
                        onPressed: _markRelease,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MarkButton(
                        label: _impactFrame != null ? '✓ Impact: $_impactFrame' : 'Mark Impact',
                        isMarked: _impactFrame != null,
                        color: Colors.red,
                        onPressed: _markImpact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;
  final bool isMain;

  const _PlaybackButton({
    required this.icon,
    required this.onPressed,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: HugeIcon(
        icon: icon, 
        color: isMain ? const Color(0xFF0091FF) : Colors.black,
        size: isMain ? 64 : 40,
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  final String label;
  final bool isMarked;
  final Color color;
  final VoidCallback onPressed;

  const _MarkButton({
    required this.label,
    required this.isMarked,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      elevation: 0,
      highlightElevation: 0,
      color: isMarked ? color : Colors.grey[100],
      shape: RoundedCornerShape(24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label,
        style: TextStyle(
          color: isMarked ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RoundedCornerShape extends OutlinedBorder {
  final double radius;
  const RoundedCornerShape(this.radius);
  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  @override
  ShapeBorder scale(double t) => this;
}
