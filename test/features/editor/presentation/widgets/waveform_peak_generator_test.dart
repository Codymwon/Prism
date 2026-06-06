import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/features/editor/presentation/utils/audio_waveform_peak_generator.dart';

void main() {
  group('AudioWaveformPeakGenerator', () {
    group('generatePeaks', () {
      test('returns empty list when count is 0', () {
        final peaks = AudioWaveformPeakGenerator.generatePeaks(seed: 42, count: 0);
        expect(peaks, isEmpty);
      });

      test('returns a single peak equal to maxPeak when count is 1', () {
        final peaks = AudioWaveformPeakGenerator.generatePeaks(
          seed: 12345,
          count: 1,
          maxPeak: 0.9,
        );
        expect(peaks, hasLength(1));
        expect(peaks.first, equals(0.9));
      });

      test('returns the correct number of peaks', () {
        final peaks =
            AudioWaveformPeakGenerator.generatePeaks(seed: 99, count: 45);
        expect(peaks, hasLength(45));
      });

      test('all peak values are within [minPeak, maxPeak] range', () {
        const minPeak = 0.1;
        const maxPeak = 1.0;
        final peaks = AudioWaveformPeakGenerator.generatePeaks(
          seed: 777,
          count: 100,
          minPeak: minPeak,
          maxPeak: maxPeak,
        );
        for (final peak in peaks) {
          expect(peak, greaterThanOrEqualTo(minPeak));
          expect(peak, lessThanOrEqualTo(maxPeak));
        }
      });

      test('is deterministic: same seed produces identical peaks', () {
        const seed = 0xDEADBEEF;
        final peaks1 =
            AudioWaveformPeakGenerator.generatePeaks(seed: seed, count: 30);
        final peaks2 =
            AudioWaveformPeakGenerator.generatePeaks(seed: seed, count: 30);
        expect(peaks1, equals(peaks2));
      });

      test('different seeds produce different peak sequences', () {
        final peaks1 =
            AudioWaveformPeakGenerator.generatePeaks(seed: 1, count: 20);
        final peaks2 =
            AudioWaveformPeakGenerator.generatePeaks(seed: 2, count: 20);
        // It is astronomically unlikely that two different LCG seeds produce
        // identical sequences for 20 values
        expect(peaks1, isNot(equals(peaks2)));
      });

      test('seed 0 does not crash and returns the correct number of peaks', () {
        final peaks =
            AudioWaveformPeakGenerator.generatePeaks(seed: 0, count: 10);
        expect(peaks, hasLength(10));
        for (final p in peaks) {
          expect(p, greaterThanOrEqualTo(0.1));
          expect(p, lessThanOrEqualTo(1.0));
        }
      });

      test('first and last peaks are smaller than peak in the middle (envelope)', () {
        // The implementation applies a 4t(1-t) envelope, making middle bars taller.
        final peaks =
            AudioWaveformPeakGenerator.generatePeaks(seed: 500, count: 45);
        final first = peaks.first;
        final last = peaks.last;
        final middle = peaks[22]; // approximately t=0.5 → envelope max
        expect(middle, greaterThan(first));
        expect(middle, greaterThan(last));
      });
    });

    group('calculateFnv1a', () {
      test('returns 2166136261 for empty input (offset basis)', () {
        final hash = AudioWaveformPeakGenerator.calculateFnv1a([]);
        expect(hash, equals(2166136261));
      });

      test('produces consistent hash for given bytes', () {
        final bytes = [0x41, 0x42, 0x43]; // "ABC"
        final hash1 = AudioWaveformPeakGenerator.calculateFnv1a(bytes);
        final hash2 = AudioWaveformPeakGenerator.calculateFnv1a(bytes);
        expect(hash1, equals(hash2));
      });

      test('different byte sequences produce different hashes', () {
        final hashA = AudioWaveformPeakGenerator.calculateFnv1a([1, 2, 3]);
        final hashB = AudioWaveformPeakGenerator.calculateFnv1a([3, 2, 1]);
        expect(hashA, isNot(equals(hashB)));
      });

      test('result is always a non-negative 32-bit integer', () {
        for (int seed = 0; seed < 50; seed++) {
          final hash = AudioWaveformPeakGenerator.calculateFnv1a(
            List.generate(10, (i) => (i + seed) % 256),
          );
          expect(hash, greaterThanOrEqualTo(0));
          expect(hash, lessThanOrEqualTo(0xFFFFFFFF));
        }
      });
    });
  });
}
