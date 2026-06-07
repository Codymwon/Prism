import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';

void main() {
  group('Journal Streak Calculation Tests', () {
    test('Case 1: empty set', () {
      final result = computeStreak({});
      expect(result.streak, equals(0));
      expect(result.totalCount, equals(0));
    });

    test('Case 2: single day (today)', () {
      final today = DateTime(2026, 6, 6);
      final dates = {'2026-06-06'};
      final result = computeStreak(dates, today);
      expect(result.streak, equals(1));
      expect(result.totalCount, equals(1));
    });

    test('Case 3: consecutive-days streak', () {
      final today = DateTime(2026, 6, 6);
      // today, yesterday, day before
      final dates = {'2026-06-06', '2026-06-05', '2026-06-04'};
      final result = computeStreak(dates, today);
      expect(result.streak, equals(3));
      expect(result.totalCount, equals(3));
    });

    test('Case 4: gap-in-streak scenario (today, 2 days ago)', () {
      final today = DateTime(2026, 6, 6);
      // today, 2 days ago (gap yesterday)
      final dates = {'2026-06-06', '2026-06-04'};
      final result = computeStreak(dates, today);
      expect(result.streak, equals(1));
      expect(result.totalCount, equals(2));
    });

    test('Case 5: consecutive-days streak with today missing but yesterday present (today pending)', () {
      final today = DateTime(2026, 6, 6);
      // yesterday, day before yesterday (today is not written yet)
      final dates = {'2026-06-05', '2026-06-04'};
      final result = computeStreak(dates, today);
      expect(result.streak, equals(2));
      expect(result.totalCount, equals(2));
    });
  });
}
