import 'package:flutter/material.dart';

class DesignIcons {
  static const IconData journal = Icons.edit_calendar_rounded;
  static const IconData dailyNote = Icons.calendar_today_rounded;
  static const IconData folder = Icons.folder_rounded;
  static const IconData folderOpen = Icons.folder_open_outlined;
  static const IconData addFolder = Icons.create_new_folder_outlined;

  static const IconData add = Icons.add_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData preview = Icons.visibility_outlined;

  static const IconData menu = Icons.menu_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData arrowDown = Icons.keyboard_arrow_down_rounded;

  static const IconData search = Icons.search_rounded;
  static const IconData searchOff = Icons.search_off_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData refresh = Icons.refresh_rounded;

  // Templates
  static const IconData gratitude = Icons.favorite_rounded;
  static const IconData dailyPlan = Icons.checklist_rounded;
  static const IconData reflection = Icons.self_improvement_rounded;
  static const IconData goals = Icons.track_changes_rounded;

  // ── Curated Folder Icons ───────────────────────────────────────────────────
  /// Flat map of DB-persisted string key → IconData.
  /// The 'folder' key is always the default fallback.
  static const Map<String, IconData> folderIcons = {
    // General
    'folder': Icons.folder_rounded,
    'inbox': Icons.inbox_rounded,
    'bookmark': Icons.bookmark_rounded,
    'star': Icons.star_rounded,
    'flag': Icons.flag_rounded,
    'label': Icons.label_rounded,
    'archive': Icons.archive_rounded,
    // Study & Learning
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'science': Icons.science_rounded,
    'psychology': Icons.psychology_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'calculate': Icons.calculate_rounded,
    'quiz': Icons.quiz_rounded,
    'history_edu': Icons.history_edu_rounded,
    // Life
    'home': Icons.home_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'restaurant': Icons.restaurant_rounded,
    'favorite': Icons.favorite_rounded,
    'health_and_safety': Icons.health_and_safety_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'spa': Icons.spa_rounded,
    // Work & Productivity
    'work': Icons.work_rounded,
    'task_alt': Icons.task_alt_rounded,
    'bar_chart': Icons.bar_chart_rounded,
    'code': Icons.code_rounded,
    'build': Icons.build_rounded,
    'settings': Icons.settings_rounded,
    'rocket_launch': Icons.rocket_launch_rounded,
    // Creative
    'palette': Icons.palette_rounded,
    'music_note': Icons.music_note_rounded,
    'movie': Icons.movie_rounded,
    'camera_alt': Icons.camera_alt_rounded,
    'brush': Icons.brush_rounded,
    'auto_stories': Icons.auto_stories_rounded,
    // Travel & Places
    'flight': Icons.flight_rounded,
    'map': Icons.map_rounded,
    'place': Icons.place_rounded,
    'explore': Icons.explore_rounded,
  };

  /// Ordered list of category labels and their icon keys for the picker UI.
  static const List<({String label, List<String> keys})> folderIconCategories = [
    (label: 'General', keys: ['folder', 'inbox', 'bookmark', 'star', 'flag', 'label', 'archive']),
    (label: 'Study', keys: ['school', 'menu_book', 'science', 'psychology', 'lightbulb', 'calculate', 'quiz', 'history_edu']),
    (label: 'Life', keys: ['home', 'fitness_center', 'restaurant', 'favorite', 'health_and_safety', 'self_improvement', 'spa']),
    (label: 'Work', keys: ['work', 'task_alt', 'bar_chart', 'code', 'build', 'settings', 'rocket_launch']),
    (label: 'Creative', keys: ['palette', 'music_note', 'movie', 'camera_alt', 'brush', 'auto_stories']),
    (label: 'Travel', keys: ['flight', 'map', 'place', 'explore']),
  ];

  /// Resolve a DB icon string key to an [IconData], falling back to folder icon.
  static IconData resolveFolder(String key) =>
      folderIcons[key] ?? Icons.folder_rounded;
}
