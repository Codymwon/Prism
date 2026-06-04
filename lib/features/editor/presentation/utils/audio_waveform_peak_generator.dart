import 'dart:io';

/// A utility to deterministically generate pseudo-random peak values
/// for audio files based on their size and content.
class AudioWaveformPeakGenerator {
  /// Calculates the 32-bit FNV-1a checksum of the given bytes.
  static int calculateFnv1a(List<int> bytes) {
    int hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Reads a file's size and up to [maxBytesToRead] from the beginning,
  /// then calculates a combined deterministic seed.
  static Future<int> generateSeedFromFile(File file, {int maxBytesToRead = 16384}) async {
    try {
      if (!await file.exists()) {
        return 0; // Fallback seed
      }
      final size = await file.length();
      final readLen = size < maxBytesToRead ? size : maxBytesToRead;

      final raf = await file.open(mode: FileMode.read);
      final bytes = await raf.read(readLen);
      await raf.close();

      final checksum = calculateFnv1a(bytes);
      return (checksum ^ size) & 0xFFFFFFFF;
    } catch (_) {
      return 0; // Return 0 if file access fails to prevent breaking the UI
    }
  }

  /// Generates a list of [count] peak values in the range [minPeak, maxPeak] deterministically.
  static List<double> generatePeaks({
    required int seed,
    int count = 50,
    double minPeak = 0.1,
    double maxPeak = 1.0,
  }) {
    if (count <= 0) return [];
    if (count == 1) return [maxPeak];

    int state = seed & 0xFFFFFFFF;

    double nextRandomDouble() {
      state = (1103515245 * state + 12345) & 0xFFFFFFFF;
      return state / 4294967296.0;
    }

    final List<double> rawPeaks = [];

    for (int i = 0; i < count; i++) {
      final double r = nextRandomDouble();
      final double t = i / (count - 1);
      final double envelope = 4.0 * t * (1.0 - t);
      final double rawVal = 0.3 + 0.7 * r;
      rawPeaks.add(rawVal * envelope);
    }

    double xMin = rawPeaks[0];
    double xMax = rawPeaks[0];
    for (final val in rawPeaks) {
      if (val < xMin) xMin = val;
      if (val > xMax) xMax = val;
    }

    final double range = xMax - xMin;
    final List<double> normalizedPeaks = [];

    for (final val in rawPeaks) {
      if (range > 0) {
        final double norm = minPeak + (maxPeak - minPeak) * ((val - xMin) / range);
        normalizedPeaks.add(double.parse(norm.toStringAsFixed(4)));
      } else {
        normalizedPeaks.add(maxPeak);
      }
    }

    return normalizedPeaks;
  }
}
