import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const BowlingSpeedApp(),
    ),
  );
}

class SpeedResult {
  final String fileName;
  final String videoPath;
  final double speedKph;
  final double speedMph;
  final DateTime dateTime;
  final int releaseFrame;
  final int impactFrame;
  final double pitchLength;

  SpeedResult({
    required this.fileName,
    required this.videoPath,
    required this.speedKph,
    required this.speedMph,
    required this.dateTime,
    required this.releaseFrame,
    required this.impactFrame,
    required this.pitchLength,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'videoPath': videoPath,
    'speedKph': speedKph,
    'speedMph': speedMph,
    'dateTime': dateTime.toIso8601String(),
    'releaseFrame': releaseFrame,
    'impactFrame': impactFrame,
    'pitchLength': pitchLength,
  };

  factory SpeedResult.fromJson(Map<String, dynamic> json) => SpeedResult(
    fileName: json['fileName'],
    videoPath: json['videoPath'],
    speedKph: json['speedKph'],
    speedMph: json['speedMph'],
    dateTime: DateTime.parse(json['dateTime']),
    releaseFrame: json['releaseFrame'],
    impactFrame: json['impactFrame'],
    pitchLength: json['pitchLength'],
  );
}

class AppState extends ChangeNotifier {
  List<SpeedResult> _results = [];
  double _pitchLength = 22.0;
  bool _initialized = false;
  bool _isFirstTime = false;
  List<String> _videoQueue = [];
  int _currentQueueIndex = -1;

  List<SpeedResult> get results => _results;
  double get pitchLength => _pitchLength;
  bool get initialized => _initialized;
  bool get isFirstTime => _isFirstTime;
  List<String> get videoQueue => _videoQueue;
  int get currentQueueIndex => _currentQueueIndex;

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load results
    final resultsJson = prefs.getStringList('history') ?? [];
    _results = resultsJson
        .map((item) => SpeedResult.fromJson(jsonDecode(item)))
        .toList();
    
    // Sort results by date descending
    _results.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Load pitch length
    _pitchLength = prefs.getDouble('pitchLength') ?? 22.0;
    
    // Check first time
    _isFirstTime = prefs.getBool('firstTimeDone') != true;
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> setFirstTimeDone() async {
    _isFirstTime = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstTimeDone', true);
    notifyListeners();
  }

  Future<void> setPitchLength(double length) async {
    _pitchLength = length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pitchLength', length);
    notifyListeners();
  }

  Future<void> setVideoQueue(List<String> paths) {
    _videoQueue = paths;
    _currentQueueIndex = paths.isNotEmpty ? 0 : -1;
    notifyListeners();
    return Future.value();
  }

  String? getNextVideo() {
    if (_videoQueue.isEmpty || _currentQueueIndex >= _videoQueue.length - 1) {
      return null;
    }
    _currentQueueIndex++;
    notifyListeners();
    return _videoQueue[_currentQueueIndex];
  }

  Future<void> addResult(SpeedResult result) async {
    _results.insert(0, result);
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = _results.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('history', resultsJson);
    notifyListeners();
  }
}

class BowlingSpeedApp extends StatelessWidget {
  const BowlingSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Bowl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0091FF),
          primary: const Color(0xFF0091FF),
          surface: Colors.white,
          background: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
            displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
