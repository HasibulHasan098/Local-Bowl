import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'analyzer_screen.dart';

class BigResultScreen extends StatelessWidget {
  final double speedKph;
  final double speedMph;

  const BigResultScreen({
    super.key,
    required this.speedKph,
    required this.speedMph,
  });

  Future<void> _pickNextVideo(BuildContext context) async {
    final state = Provider.of<AppState>(context, listen: false);
    
    // Check if we are in folder mode
    final String? nextVideoPath = state.getNextVideo();
    
    if (nextVideoPath != null) {
      if (context.mounted) {
        final fileName = nextVideoPath.split(Platform.pathSeparator).last;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyzerScreen(videoPath: nextVideoPath, fileName: fileName),
          ),
        );
      }
      return;
    }

    // Fallback to single video pick if no queue or queue finished
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalyzerScreen(videoPath: video.path, fileName: video.name),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more videos in the folder or none selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0091FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDashboardSpeed01,
                color: Colors.white,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bowling Speed',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    speedKph.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'km/h',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${speedMph.toStringAsFixed(1)} mph',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: Color(0xFF0091FF), size: 24),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0091FF),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickNextVideo(context),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedVideo01, color: Colors.white, size: 24),
                      label: const Text('Next Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
