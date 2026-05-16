class BowlingCalculator {
  static double calculateKph(int releaseFrame, int impactFrame, double fps, double distanceYards) {
    if (impactFrame <= releaseFrame) return 0.0;
    
    double timeSeconds = (impactFrame - releaseFrame) / fps;
    double distanceMeters = distanceYards * 0.9144;
    double velocityMps = distanceMeters / timeSeconds;
    
    return velocityMps * 3.6;
  }

  static double kphToMph(double kph) {
    return kph * 0.621371;
  }
}
