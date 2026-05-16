import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import 'analyzer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.initialized && state.isFirstTime) {
        _showPitchLengthDialog(context, isFirstTime: true);
      }
    });
  }

  Future<void> _pickVideo(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null && context.mounted) {
      // Clear queue when picking single video
      Provider.of<AppState>(context, listen: false).setVideoQueue([]);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalyzerScreen(videoPath: video.path, fileName: video.name),
        ),
      );
    }
  }

  Future<void> _pickFolder(BuildContext context) async {
    final String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null && context.mounted) {
      final directory = Directory(directoryPath);
      final List<FileSystemEntity> files = directory.listSync();
      
      final List<String> videoPaths = files
          .where((file) => 
              file is File && 
              (file.path.endsWith('.mp4') || 
               file.path.endsWith('.mov') || 
               file.path.endsWith('.m4v')))
          .map((file) => file.path)
          .toList();

      if (videoPaths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No videos found in the selected folder')),
        );
        return;
      }

      final state = Provider.of<AppState>(context, listen: false);
      await state.setVideoQueue(videoPaths);

      if (context.mounted) {
        final firstVideo = videoPaths[0];
        final fileName = firstVideo.split(Platform.pathSeparator).last;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyzerScreen(videoPath: firstVideo, fileName: fileName),
          ),
        );
      }
    }
  }

  void _showPitchLengthDialog(BuildContext context, {bool isFirstTime = false}) {
    final state = Provider.of<AppState>(context, listen: false);
    final controller = TextEditingController(text: state.pitchLength.toString());

    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isFirstTime ? 'Welcome to Local Bowl' : 'Edit Pitch Length',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the pitch length in yards to get accurate speed calculations.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pitch Length (yards)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.straighten),
              ),
            ),
          ],
        ),
        actions: [
          if (!isFirstTime)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ElevatedButton(
            onPressed: () {
              final length = double.tryParse(controller.text);
              if (length != null) {
                state.setPitchLength(length);
                if (isFirstTime) {
                  state.setFirstTimeDone();
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0091FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isFirstTime ? 'Get Started' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final results = state.results;

    // Group results by date
    final Map<String, List<SpeedResult>> groupedResults = {};
    for (var result in results) {
      final dateStr = DateFormat('MMMM dd, yyyy').format(result.dateTime);
      if (!groupedResults.containsKey(dateStr)) {
        groupedResults[dateStr] = [];
      }
      groupedResults[dateStr]!.add(result);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDashboardSpeed01,
                        color: Color(0xFF0091FF),
                        size: 100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Local Bowl',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pro Speed Analyzer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showPitchLengthDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pitch: ${state.pitchLength} yards',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedPencilEdit01,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _HugeButton(
                            icon: HugeIcons.strokeRoundedVideo01,
                            label: 'Select Video',
                            onPressed: () => _pickVideo(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _HugeButton(
                            icon: HugeIcons.strokeRoundedFolder01,
                            label: 'Select Folder',
                            onPressed: () => _pickFolder(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (results.isNotEmpty)
                      const Row(
                        children: [
                          Text(
                            'History',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedFolder01, color: Colors.grey[300]!, size: 64),
                      const SizedBox(height: 16),
                      Text('No history yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              ...groupedResults.entries.expand((entry) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final result = entry.value[index];
                          return _HistoryItem(result: result);
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ),
                ];
              }),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SpeedResult result;

  const _HistoryItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalyzerScreen(
                videoPath: result.videoPath,
                fileName: result.fileName,
                initialReleaseFrame: result.releaseFrame,
                initialImpactFrame: result.impactFrame,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0091FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDashboardSpeed01,
                    color: Color(0xFF0091FF),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('HH:mm').format(result.dateTime),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.speedKph.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Color(0xFF0091FF),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const Text(
                    'km/h',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HugeButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onPressed;

  const _HugeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            HugeIcon(icon: icon, color: const Color(0xFF0091FF), size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
