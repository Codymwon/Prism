import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Prism'**
  String get appName;

  /// No description provided for @shared_app_shell_tab_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get shared_app_shell_tab_notes;

  /// No description provided for @shared_app_shell_tab_journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get shared_app_shell_tab_journal;

  /// No description provided for @shared_app_shell_tab_graph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get shared_app_shell_tab_graph;

  /// No description provided for @shared_app_shell_tab_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shared_app_shell_tab_settings;

  /// No description provided for @shared_app_shell_tutorial_journal_nav_title.
  ///
  /// In en, this message translates to:
  /// **'Calendar Navigation'**
  String get shared_app_shell_tutorial_journal_nav_title;

  /// No description provided for @shared_app_shell_tutorial_journal_nav_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap the calendar icon to expand the monthly calendar view and navigate across all dates in your vault history.'**
  String get shared_app_shell_tutorial_journal_nav_desc;

  /// No description provided for @shared_app_shell_tutorial_journal_strip_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Quick Strip'**
  String get shared_app_shell_tutorial_journal_strip_title;

  /// No description provided for @shared_app_shell_tutorial_journal_strip_desc.
  ///
  /// In en, this message translates to:
  /// **'Quickly slide or tap between the last 7 days to keep your reflection streak alive without opening the full calendar view.'**
  String get shared_app_shell_tutorial_journal_strip_desc;

  /// No description provided for @shared_app_shell_tutorial_journal_streak_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak & Grid'**
  String get shared_app_shell_tutorial_journal_streak_title;

  /// No description provided for @shared_app_shell_tutorial_journal_streak_desc.
  ///
  /// In en, this message translates to:
  /// **'Track your active daily writing streak and visualize your consistency over the last 28 days with the contribution grid.'**
  String get shared_app_shell_tutorial_journal_streak_desc;

  /// No description provided for @shared_app_shell_tutorial_journal_template_title.
  ///
  /// In en, this message translates to:
  /// **'Reflection Templates'**
  String get shared_app_shell_tutorial_journal_template_title;

  /// No description provided for @shared_app_shell_tutorial_journal_template_desc.
  ///
  /// In en, this message translates to:
  /// **'Select an expert journal template (Gratitude, Daily Plan, Reflection, Goals) to quickly structure your writing, or start typing in a blank daily page.'**
  String get shared_app_shell_tutorial_journal_template_desc;

  /// No description provided for @shared_app_shell_tutorial_notes_nav_title.
  ///
  /// In en, this message translates to:
  /// **'Virtual Folders & Tags'**
  String get shared_app_shell_tutorial_notes_nav_title;

  /// No description provided for @shared_app_shell_tutorial_notes_nav_desc.
  ///
  /// In en, this message translates to:
  /// **'Open the sidebar navigation drawer to organize your notes into virtual folders or browse tag indexes across your vault.'**
  String get shared_app_shell_tutorial_notes_nav_desc;

  /// No description provided for @shared_app_shell_tutorial_notes_folders_title.
  ///
  /// In en, this message translates to:
  /// **'Virtual Folders'**
  String get shared_app_shell_tutorial_notes_folders_title;

  /// No description provided for @shared_app_shell_tutorial_notes_folders_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap any virtual folder card in the horizontal row to filter the notes list below. Tap the \"All Notes\" card to reset the filter.'**
  String get shared_app_shell_tutorial_notes_folders_desc;

  /// No description provided for @shared_app_shell_tutorial_notes_daily_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Reflection Logs'**
  String get shared_app_shell_tutorial_notes_daily_title;

  /// No description provided for @shared_app_shell_tutorial_notes_daily_desc.
  ///
  /// In en, this message translates to:
  /// **'Access today\'\'s dedicated calendar note immediately. Jot down reflections with templates (Gratitude, Reflection, Goals), hit word count targets, and grow your daily writing streak.'**
  String get shared_app_shell_tutorial_notes_daily_desc;

  /// No description provided for @shared_app_shell_tutorial_notes_graph_title.
  ///
  /// In en, this message translates to:
  /// **'Mindmap Thought Graph'**
  String get shared_app_shell_tutorial_notes_graph_title;

  /// No description provided for @shared_app_shell_tutorial_notes_graph_desc.
  ///
  /// In en, this message translates to:
  /// **'Explore your connected mind network. Watch notes become nodes and wikilinks become edges in a dynamic 2D graph layout.'**
  String get shared_app_shell_tutorial_notes_graph_desc;

  /// No description provided for @shared_app_shell_tutorial_notes_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create & Link Notes'**
  String get shared_app_shell_tutorial_notes_create_title;

  /// No description provided for @shared_app_shell_tutorial_notes_create_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap the floating \"+\" button to create a new note. Within any note, simply type double brackets [[like this]] to link ideas together and expand your brain.'**
  String get shared_app_shell_tutorial_notes_create_desc;

  /// No description provided for @shared_storage_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get shared_storage_permission_title;

  /// No description provided for @shared_storage_permission_desc.
  ///
  /// In en, this message translates to:
  /// **'Prism is private and offline-first. Your notes are stored directly inside your custom folder on this device.\n\nTo read and write note files in your documents vault, Android requires the \"All Files Access\" permission.'**
  String get shared_storage_permission_desc;

  /// No description provided for @shared_storage_permission_grant_button.
  ///
  /// In en, this message translates to:
  /// **'Grant Storage Access'**
  String get shared_storage_permission_grant_button;

  /// No description provided for @shared_storage_permission_secondary_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap above, then enable the toggle for Prism in the Android settings screen. Once enabled, press back to return here.'**
  String get shared_storage_permission_secondary_desc;

  /// No description provided for @shared_storage_permission_loading_label.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get shared_storage_permission_loading_label;

  /// No description provided for @shared_tutorial_overlay_label.
  ///
  /// In en, this message translates to:
  /// **'Tutorial overlay'**
  String get shared_tutorial_overlay_label;

  /// No description provided for @shared_tutorial_overlay_step_counter.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String shared_tutorial_overlay_step_counter(int current, int total);

  /// No description provided for @shared_tutorial_overlay_skip_tour.
  ///
  /// In en, this message translates to:
  /// **'Skip Tour'**
  String get shared_tutorial_overlay_skip_tour;

  /// No description provided for @shared_tutorial_overlay_back_button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get shared_tutorial_overlay_back_button;

  /// No description provided for @shared_tutorial_overlay_got_it_button.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get shared_tutorial_overlay_got_it_button;

  /// No description provided for @shared_tutorial_overlay_next_button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get shared_tutorial_overlay_next_button;

  /// No description provided for @editor_screen_editor_mode.
  ///
  /// In en, this message translates to:
  /// **'EDITOR MODE'**
  String get editor_screen_editor_mode;

  /// No description provided for @editor_screen_live_preview.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get editor_screen_live_preview;

  /// No description provided for @editor_screen_source_mode.
  ///
  /// In en, this message translates to:
  /// **'Plain Text'**
  String get editor_screen_source_mode;

  /// No description provided for @editor_screen_reading_view.
  ///
  /// In en, this message translates to:
  /// **'Reading View'**
  String get editor_screen_reading_view;

  /// No description provided for @editor_screen_backlinks.
  ///
  /// In en, this message translates to:
  /// **'Backlinks'**
  String get editor_screen_backlinks;

  /// No description provided for @editor_screen_show_backlinks_semantics.
  ///
  /// In en, this message translates to:
  /// **'Show backlinks'**
  String get editor_screen_show_backlinks_semantics;

  /// No description provided for @editor_screen_organize_folders_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Organize into folders'**
  String get editor_screen_organize_folders_tooltip;

  /// No description provided for @editor_screen_settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Editor Settings'**
  String get editor_screen_settings_tooltip;

  /// Snackbar message when image attachment fails
  ///
  /// In en, this message translates to:
  /// **'Failed to attach image: {error}'**
  String editor_screen_failed_image_attach(String error);

  /// No description provided for @editor_merge_comparison_note_not_found.
  ///
  /// In en, this message translates to:
  /// **'Conflict note not found.'**
  String get editor_merge_comparison_note_not_found;

  /// No description provided for @editor_merge_comparison_not_conflicted.
  ///
  /// In en, this message translates to:
  /// **'This note is not marked as conflicted.'**
  String get editor_merge_comparison_not_conflicted;

  /// No description provided for @editor_merge_comparison_original_deleted.
  ///
  /// In en, this message translates to:
  /// **'Original note was deleted or not found.'**
  String get editor_merge_comparison_original_deleted;

  /// No description provided for @editor_merge_comparison_failed_load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load note contents: {error}'**
  String editor_merge_comparison_failed_load(Object error);

  /// No description provided for @editor_merge_comparison_discarded_success.
  ///
  /// In en, this message translates to:
  /// **'Conflicted copy discarded. Keeping original note.'**
  String get editor_merge_comparison_discarded_success;

  /// No description provided for @editor_merge_comparison_discard_error.
  ///
  /// In en, this message translates to:
  /// **'Error discarding conflicted copy: {error}'**
  String editor_merge_comparison_discard_error(Object error);

  /// No description provided for @editor_merge_comparison_replaced_success.
  ///
  /// In en, this message translates to:
  /// **'Original note replaced with conflicted copy contents.'**
  String get editor_merge_comparison_replaced_success;

  /// No description provided for @editor_merge_comparison_replace_error.
  ///
  /// In en, this message translates to:
  /// **'Error resolving conflict: {error}'**
  String editor_merge_comparison_replace_error(Object error);

  /// No description provided for @editor_merge_comparison_merged_markers.
  ///
  /// In en, this message translates to:
  /// **'Notes merged with Git conflict markers. Please resolve manually.'**
  String get editor_merge_comparison_merged_markers;

  /// No description provided for @editor_merge_comparison_merge_error.
  ///
  /// In en, this message translates to:
  /// **'Error merging notes: {error}'**
  String editor_merge_comparison_merge_error(Object error);

  /// No description provided for @editor_merge_comparison_compare_resolve.
  ///
  /// In en, this message translates to:
  /// **'Compare & Resolve'**
  String get editor_merge_comparison_compare_resolve;

  /// No description provided for @editor_merge_comparison_tab_original.
  ///
  /// In en, this message translates to:
  /// **'Original Note'**
  String get editor_merge_comparison_tab_original;

  /// No description provided for @editor_merge_comparison_tab_conflict.
  ///
  /// In en, this message translates to:
  /// **'Conflicted Copy'**
  String get editor_merge_comparison_tab_conflict;

  /// No description provided for @editor_merge_comparison_empty_note.
  ///
  /// In en, this message translates to:
  /// **'Note is empty.'**
  String get editor_merge_comparison_empty_note;

  /// No description provided for @editor_merge_comparison_how_to_resolve.
  ///
  /// In en, this message translates to:
  /// **'How would you like to resolve this conflict?'**
  String get editor_merge_comparison_how_to_resolve;

  /// No description provided for @editor_merge_comparison_keep_original.
  ///
  /// In en, this message translates to:
  /// **'Keep Original'**
  String get editor_merge_comparison_keep_original;

  /// No description provided for @editor_merge_comparison_keep_conflicted.
  ///
  /// In en, this message translates to:
  /// **'Keep Conflicted'**
  String get editor_merge_comparison_keep_conflicted;

  /// No description provided for @editor_merge_comparison_merge_both.
  ///
  /// In en, this message translates to:
  /// **'Merge Both Copies'**
  String get editor_merge_comparison_merge_both;

  /// No description provided for @editor_merge_comparison_resolution_error.
  ///
  /// In en, this message translates to:
  /// **'Resolution Error'**
  String get editor_merge_comparison_resolution_error;

  /// No description provided for @editor_merge_comparison_back_to_notes.
  ///
  /// In en, this message translates to:
  /// **'Back to Notes'**
  String get editor_merge_comparison_back_to_notes;

  /// No description provided for @editor_audio_player_sheet_voice_recording.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording'**
  String get editor_audio_player_sheet_voice_recording;

  /// No description provided for @editor_backlinks_panel_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 backlink} other{{count} backlinks}}'**
  String editor_backlinks_panel_title(num count);

  /// No description provided for @editor_conflict_banner_message.
  ///
  /// In en, this message translates to:
  /// **'Conflicted Copy: Review and resolve changes.'**
  String get editor_conflict_banner_message;

  /// No description provided for @editor_write_mode_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Note Title'**
  String get editor_write_mode_title_hint;

  /// No description provided for @editor_write_mode_content_hint.
  ///
  /// In en, this message translates to:
  /// **'Start writing… use [[note]] for links, #tag for tags'**
  String get editor_write_mode_content_hint;

  /// No description provided for @editor_formatting_toolbar_tooltip_bullet_list.
  ///
  /// In en, this message translates to:
  /// **'Bullet List'**
  String get editor_formatting_toolbar_tooltip_bullet_list;

  /// No description provided for @editor_formatting_toolbar_tooltip_heading.
  ///
  /// In en, this message translates to:
  /// **'Heading (H1–H4)'**
  String get editor_formatting_toolbar_tooltip_heading;

  /// No description provided for @editor_formatting_toolbar_tooltip_attach_image.
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get editor_formatting_toolbar_tooltip_attach_image;

  /// No description provided for @editor_formatting_toolbar_tooltip_dictate.
  ///
  /// In en, this message translates to:
  /// **'Dictate (Voice-to-Text)'**
  String get editor_formatting_toolbar_tooltip_dictate;

  /// No description provided for @editor_formatting_toolbar_recording_status.
  ///
  /// In en, this message translates to:
  /// **'Recording {time}...'**
  String editor_formatting_toolbar_recording_status(Object time);

  /// No description provided for @editor_formatting_toolbar_cancel_discard_semantics.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Discard recording'**
  String get editor_formatting_toolbar_cancel_discard_semantics;

  /// No description provided for @editor_formatting_toolbar_cancel_discard_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel & Discard'**
  String get editor_formatting_toolbar_cancel_discard_tooltip;

  /// No description provided for @editor_formatting_toolbar_save_insert_semantics.
  ///
  /// In en, this message translates to:
  /// **'Save & Insert recording'**
  String get editor_formatting_toolbar_save_insert_semantics;

  /// No description provided for @editor_inline_audio_file_not_found.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found: {fileName}'**
  String editor_inline_audio_file_not_found(Object fileName);

  /// No description provided for @editor_inline_audio_add_bookmark_title.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get editor_inline_audio_add_bookmark_title;

  /// No description provided for @editor_inline_audio_bookmark_at_time.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String editor_inline_audio_bookmark_at_time(Object time);

  /// No description provided for @editor_inline_audio_annotation_hint.
  ///
  /// In en, this message translates to:
  /// **'Annotation (optional)'**
  String get editor_inline_audio_annotation_hint;

  /// No description provided for @editor_inline_audio_add_bookmark_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark at current position'**
  String get editor_inline_audio_add_bookmark_tooltip;

  /// No description provided for @editor_inline_audio_database_error.
  ///
  /// In en, this message translates to:
  /// **'Database Error: {error}'**
  String editor_inline_audio_database_error(Object error);

  /// No description provided for @editor_wikilink_autocomplete_link_to_note.
  ///
  /// In en, this message translates to:
  /// **'Link to note'**
  String get editor_wikilink_autocomplete_link_to_note;

  /// No description provided for @editor_wikilink_autocomplete_ghost_note.
  ///
  /// In en, this message translates to:
  /// **'Ghost note'**
  String get editor_wikilink_autocomplete_ghost_note;

  /// No description provided for @editor_wikilink_autocomplete_words.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String editor_wikilink_autocomplete_words(num count);

  /// No description provided for @editor_wikilink_autocomplete_create_note.
  ///
  /// In en, this message translates to:
  /// **'Create new note'**
  String get editor_wikilink_autocomplete_create_note;

  /// No description provided for @folders_add_folder_add_icon.
  ///
  /// In en, this message translates to:
  /// **'Add icon'**
  String get folders_add_folder_add_icon;

  /// No description provided for @folders_add_folder_change_icon.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get folders_add_folder_change_icon;

  /// No description provided for @folders_add_folder_remove_icon.
  ///
  /// In en, this message translates to:
  /// **'✕ Remove'**
  String get folders_add_folder_remove_icon;

  /// No description provided for @folders_add_folder_hint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folders_add_folder_hint;

  /// No description provided for @folders_edit_folder_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Folder'**
  String get folders_edit_folder_title;

  /// No description provided for @folders_edit_folder_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String folders_edit_folder_error(Object error);

  /// No description provided for @folders_edit_folder_not_found.
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get folders_edit_folder_not_found;

  /// No description provided for @folders_edit_folder_save.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get folders_edit_folder_save;

  /// No description provided for @folders_assign_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Organize Note'**
  String get folders_assign_dialog_title;

  /// No description provided for @folders_assign_dialog_error_folders.
  ///
  /// In en, this message translates to:
  /// **'Error loading folders: {error}'**
  String folders_assign_dialog_error_folders(Object error);

  /// No description provided for @folders_assign_dialog_error_assignments.
  ///
  /// In en, this message translates to:
  /// **'Error loading assignments: {error}'**
  String folders_assign_dialog_error_assignments(Object error);

  /// No description provided for @folders_assign_dialog_empty.
  ///
  /// In en, this message translates to:
  /// **'No virtual folders created yet. Add them from the sidebar drawer first!'**
  String get folders_assign_dialog_empty;

  /// No description provided for @folders_drawer_no_notes.
  ///
  /// In en, this message translates to:
  /// **'No notes found in this workspace'**
  String get folders_drawer_no_notes;

  /// No description provided for @folders_drawer_random_note_error.
  ///
  /// In en, this message translates to:
  /// **'Error finding random note: {error}'**
  String folders_drawer_random_note_error(Object error);

  /// No description provided for @folders_drawer_manage_templates.
  ///
  /// In en, this message translates to:
  /// **'Manage Templates'**
  String get folders_drawer_manage_templates;

  /// No description provided for @folders_drawer_manage_macros.
  ///
  /// In en, this message translates to:
  /// **'Manage Macros'**
  String get folders_drawer_manage_macros;

  /// No description provided for @folders_drawer_folder_menu_title.
  ///
  /// In en, this message translates to:
  /// **'Folder: {folderName}'**
  String folders_drawer_folder_menu_title(Object folderName);

  /// No description provided for @folders_drawer_edit_details.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get folders_drawer_edit_details;

  /// No description provided for @folders_drawer_delete_warning.
  ///
  /// In en, this message translates to:
  /// **'This will delete the \"{folderName}\" category organization. None of the physical markdown files will be deleted.'**
  String folders_drawer_delete_warning(Object folderName);

  /// No description provided for @folders_icon_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get folders_icon_picker_title;

  /// No description provided for @folders_color_picker_hex_code.
  ///
  /// In en, this message translates to:
  /// **'HEX CODE'**
  String get folders_color_picker_hex_code;

  /// No description provided for @folders_color_picker_hue.
  ///
  /// In en, this message translates to:
  /// **'HUE ({value}°)'**
  String folders_color_picker_hue(Object value);

  /// No description provided for @folders_color_picker_saturation.
  ///
  /// In en, this message translates to:
  /// **'SATURATION ({value}%)'**
  String folders_color_picker_saturation(Object value);

  /// No description provided for @folders_color_picker_brightness.
  ///
  /// In en, this message translates to:
  /// **'BRIGHTNESS ({value}%)'**
  String folders_color_picker_brightness(Object value);

  /// No description provided for @folders_tag_cloud_title.
  ///
  /// In en, this message translates to:
  /// **'TAG INDEX'**
  String get folders_tag_cloud_title;

  /// No description provided for @folders_tag_cloud_error.
  ///
  /// In en, this message translates to:
  /// **'Error index: {error}'**
  String folders_tag_cloud_error(Object error);

  /// No description provided for @folders_tag_cloud_empty.
  ///
  /// In en, this message translates to:
  /// **'No tags parsed yet. Add #tags to your notes to auto-index them.'**
  String get folders_tag_cloud_empty;

  /// No description provided for @folders_stats_board_title.
  ///
  /// In en, this message translates to:
  /// **'WORKSPACE OVERVIEW'**
  String get folders_stats_board_title;

  /// No description provided for @folders_stats_board_error.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats: {error}'**
  String folders_stats_board_error(Object error);

  /// No description provided for @folders_stats_board_notes_created.
  ///
  /// In en, this message translates to:
  /// **'Notes Created'**
  String get folders_stats_board_notes_created;

  /// No description provided for @folders_stats_board_words_written.
  ///
  /// In en, this message translates to:
  /// **'Words Written'**
  String get folders_stats_board_words_written;

  /// No description provided for @folders_stats_board_backlinks_formed.
  ///
  /// In en, this message translates to:
  /// **'Backlinks Formed'**
  String get folders_stats_board_backlinks_formed;

  /// No description provided for @folders_status_panel_loading_path.
  ///
  /// In en, this message translates to:
  /// **'Loading path...'**
  String get folders_status_panel_loading_path;

  /// No description provided for @folders_status_panel_ready.
  ///
  /// In en, this message translates to:
  /// **'Local Safe / Private Sync Ready'**
  String get folders_status_panel_ready;

  /// No description provided for @graph_screen_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String graph_screen_error(Object error);

  /// No description provided for @graph_empty_state_title.
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get graph_empty_state_title;

  /// No description provided for @graph_empty_state_description.
  ///
  /// In en, this message translates to:
  /// **'Start linking notes with [[wikilinks]] and your graph will grow here'**
  String get graph_empty_state_description;

  /// No description provided for @graph_header_title.
  ///
  /// In en, this message translates to:
  /// **'Graph View'**
  String get graph_header_title;

  /// No description provided for @graph_header_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your connected ideas'**
  String get graph_header_subtitle;

  /// No description provided for @graph_header_reset_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get graph_header_reset_tooltip;

  /// No description provided for @graph_header_replay_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Replay animation'**
  String get graph_header_replay_tooltip;

  /// No description provided for @graph_header_settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Graph settings'**
  String get graph_header_settings_tooltip;

  /// No description provided for @graph_settings_panel_title.
  ///
  /// In en, this message translates to:
  /// **'Graph Settings'**
  String get graph_settings_panel_title;

  /// No description provided for @graph_settings_panel_repulsion_force.
  ///
  /// In en, this message translates to:
  /// **'Node Spacing'**
  String get graph_settings_panel_repulsion_force;

  /// No description provided for @graph_settings_panel_link_spring_distance.
  ///
  /// In en, this message translates to:
  /// **'Connection Length'**
  String get graph_settings_panel_link_spring_distance;

  /// No description provided for @graph_settings_panel_spring_stiffness.
  ///
  /// In en, this message translates to:
  /// **'Connection Tension'**
  String get graph_settings_panel_spring_stiffness;

  /// No description provided for @graph_settings_panel_simulation_damping.
  ///
  /// In en, this message translates to:
  /// **'Motion Smoothness'**
  String get graph_settings_panel_simulation_damping;

  /// No description provided for @graph_settings_panel_repulsion_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Adjust how far unconnected notes sit from each other'**
  String get graph_settings_panel_repulsion_tooltip;

  /// No description provided for @graph_settings_panel_link_spring_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Adjust the length of links between related notes'**
  String get graph_settings_panel_link_spring_tooltip;

  /// No description provided for @graph_settings_panel_spring_stiffness_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Adjust the tension of links between related notes'**
  String get graph_settings_panel_spring_stiffness_tooltip;

  /// No description provided for @graph_settings_panel_simulation_damping_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Control how quickly nodes settle into place'**
  String get graph_settings_panel_simulation_damping_tooltip;

  /// No description provided for @graph_settings_panel_drag_to_pin.
  ///
  /// In en, this message translates to:
  /// **'Drag to Pin'**
  String get graph_settings_panel_drag_to_pin;

  /// No description provided for @graph_settings_panel_color_by.
  ///
  /// In en, this message translates to:
  /// **'Color by'**
  String get graph_settings_panel_color_by;

  /// No description provided for @graph_settings_panel_tag_colors.
  ///
  /// In en, this message translates to:
  /// **'Tag Colors'**
  String get graph_settings_panel_tag_colors;

  /// No description provided for @graph_settings_panel_no_tags.
  ///
  /// In en, this message translates to:
  /// **'No tags found'**
  String get graph_settings_panel_no_tags;

  /// No description provided for @graph_settings_panel_reset_defaults.
  ///
  /// In en, this message translates to:
  /// **'Reset Defaults'**
  String get graph_settings_panel_reset_defaults;

  /// No description provided for @graph_settings_panel_reset_hsl.
  ///
  /// In en, this message translates to:
  /// **'Reset (HSL Hash)'**
  String get graph_settings_panel_reset_hsl;

  /// No description provided for @journal_screen_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String journal_screen_error(Object error);

  /// No description provided for @journal_screen_start_with_template.
  ///
  /// In en, this message translates to:
  /// **'START WITH A TEMPLATE'**
  String get journal_screen_start_with_template;

  /// No description provided for @journal_screen_default_template_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Reflection'**
  String get journal_screen_default_template_title;

  /// No description provided for @journal_empty_state_future_day_title.
  ///
  /// In en, this message translates to:
  /// **'A future day'**
  String get journal_empty_state_future_day_title;

  /// No description provided for @journal_empty_state_no_entry_title.
  ///
  /// In en, this message translates to:
  /// **'No entry yet'**
  String get journal_empty_state_no_entry_title;

  /// No description provided for @journal_empty_state_future_day_desc.
  ///
  /// In en, this message translates to:
  /// **'Come back on this day to start writing'**
  String get journal_empty_state_future_day_desc;

  /// No description provided for @journal_empty_state_no_entry_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap below to start your entry for today'**
  String get journal_empty_state_no_entry_desc;

  /// No description provided for @journal_empty_state_start_writing_button.
  ///
  /// In en, this message translates to:
  /// **'Start Writing'**
  String get journal_empty_state_start_writing_button;

  /// No description provided for @journal_entry_card_default_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Reflection'**
  String get journal_entry_card_default_title;

  /// No description provided for @journal_entry_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{subtitle} • {count, plural, =1{1 word} other{{count} words}}'**
  String journal_entry_card_subtitle(num count, Object subtitle);

  /// No description provided for @journal_entry_card_empty_content.
  ///
  /// In en, this message translates to:
  /// **'No text written yet. Tap to start writing…'**
  String get journal_entry_card_empty_content;

  /// No description provided for @journal_entry_card_continue_writing_button.
  ///
  /// In en, this message translates to:
  /// **'Continue writing'**
  String get journal_entry_card_continue_writing_button;

  /// No description provided for @journal_entry_card_checklist_header.
  ///
  /// In en, this message translates to:
  /// **'DAILY MINDFUL CHECKLIST'**
  String get journal_entry_card_checklist_header;

  /// No description provided for @journal_header_title_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get journal_header_title_today;

  /// No description provided for @journal_header_entries_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry} other{{count} entries}}'**
  String journal_header_entries_count(num count);

  /// No description provided for @journal_streak_grid_title.
  ///
  /// In en, this message translates to:
  /// **'Day Active Streak'**
  String get journal_streak_grid_title;

  /// No description provided for @journal_streak_grid_consistency_grid.
  ///
  /// In en, this message translates to:
  /// **'Consistency Grid'**
  String get journal_streak_grid_consistency_grid;

  /// No description provided for @journal_templates_row_gratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get journal_templates_row_gratitude;

  /// No description provided for @journal_templates_row_daily_plan.
  ///
  /// In en, this message translates to:
  /// **'Daily Plan'**
  String get journal_templates_row_daily_plan;

  /// No description provided for @journal_templates_row_reflection.
  ///
  /// In en, this message translates to:
  /// **'Reflection'**
  String get journal_templates_row_reflection;

  /// No description provided for @journal_templates_row_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get journal_templates_row_goals;

  /// No description provided for @notes_list_screen_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String notes_list_screen_error(Object error);

  /// No description provided for @notes_list_screen_new_folder_tooltip.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get notes_list_screen_new_folder_tooltip;

  /// No description provided for @notes_list_screen_search_results_title.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RESULTS'**
  String get notes_list_screen_search_results_title;

  /// No description provided for @notes_list_screen_recent_notes_title.
  ///
  /// In en, this message translates to:
  /// **'RECENT NOTES'**
  String get notes_list_screen_recent_notes_title;

  /// No description provided for @notes_list_screen_all_notes_tooltip.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get notes_list_screen_all_notes_tooltip;

  /// No description provided for @notes_list_screen_all_notes_title.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get notes_list_screen_all_notes_title;

  /// No description provided for @notes_list_screen_journal_logs_title.
  ///
  /// In en, this message translates to:
  /// **'Journal Logs'**
  String get notes_list_screen_journal_logs_title;

  /// No description provided for @notes_list_screen_no_notes_found_search.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get notes_list_screen_no_notes_found_search;

  /// No description provided for @notes_list_screen_workspace_awaits_title.
  ///
  /// In en, this message translates to:
  /// **'Your workspace awaits'**
  String get notes_list_screen_workspace_awaits_title;

  /// No description provided for @notes_list_screen_search_help_desc.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get notes_list_screen_search_help_desc;

  /// No description provided for @notes_list_screen_create_help_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first note'**
  String get notes_list_screen_create_help_desc;

  /// No description provided for @notes_list_screen_delete_warning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the note and its file.'**
  String get notes_list_screen_delete_warning;

  /// No description provided for @notes_list_screen_folders_count.
  ///
  /// In en, this message translates to:
  /// **'Folders • {total, plural, =1{1 folder} other{{total} folders}}'**
  String notes_list_screen_folders_count(num total);

  /// No description provided for @notes_list_screen_all_notes_count.
  ///
  /// In en, this message translates to:
  /// **'All Notes • {count, plural, =1{1 note} other{{count} notes}}'**
  String notes_list_screen_all_notes_count(num count);

  /// No description provided for @notes_list_screen_journal_logs_count.
  ///
  /// In en, this message translates to:
  /// **'Journal Logs • {count, plural, =1{1 note} other{{count} notes}}'**
  String notes_list_screen_journal_logs_count(num count);

  /// No description provided for @notes_list_screen_uncategorized_count.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized • {count, plural, =1{1 note} other{{count} notes}}'**
  String notes_list_screen_uncategorized_count(num count);

  /// No description provided for @notes_list_screen_custom_folder_count.
  ///
  /// In en, this message translates to:
  /// **'{name} • {count, plural, =1{1 note} other{{count} notes}}'**
  String notes_list_screen_custom_folder_count(num count, Object name);

  /// No description provided for @notes_grouped_empty_state_title.
  ///
  /// In en, this message translates to:
  /// **'Organize your thoughts'**
  String get notes_grouped_empty_state_title;

  /// No description provided for @notes_search_bar_open_drawer_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open drawer'**
  String get notes_search_bar_open_drawer_tooltip;

  /// No description provided for @notes_search_bar_hint.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get notes_search_bar_hint;

  /// No description provided for @notes_sort_bottom_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get notes_sort_bottom_sheet_title;

  /// No description provided for @notes_sort_bottom_sheet_last_updated_title.
  ///
  /// In en, this message translates to:
  /// **'Last Updated (Recent)'**
  String get notes_sort_bottom_sheet_last_updated_title;

  /// No description provided for @notes_sort_bottom_sheet_last_updated_desc.
  ///
  /// In en, this message translates to:
  /// **'Recently edited notes and folders float to the top'**
  String get notes_sort_bottom_sheet_last_updated_desc;

  /// No description provided for @notes_sort_bottom_sheet_date_created_title.
  ///
  /// In en, this message translates to:
  /// **'Date Created'**
  String get notes_sort_bottom_sheet_date_created_title;

  /// No description provided for @notes_sort_bottom_sheet_date_created_desc.
  ///
  /// In en, this message translates to:
  /// **'Newest folders and notes listed first'**
  String get notes_sort_bottom_sheet_date_created_desc;

  /// No description provided for @notes_sort_bottom_sheet_alphabetical_title.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical (A–Z)'**
  String get notes_sort_bottom_sheet_alphabetical_title;

  /// No description provided for @notes_sort_bottom_sheet_alphabetical_desc.
  ///
  /// In en, this message translates to:
  /// **'Sort notes and folders by name alphabetically'**
  String get notes_sort_bottom_sheet_alphabetical_desc;

  /// No description provided for @notes_tag_filter_banner_filtered_by.
  ///
  /// In en, this message translates to:
  /// **'Filtered by tag: #{tag}'**
  String notes_tag_filter_banner_filtered_by(Object tag);

  /// No description provided for @notes_vault_selector_switch_error.
  ///
  /// In en, this message translates to:
  /// **'Error switching workspace: {error}'**
  String notes_vault_selector_switch_error(Object error);

  /// No description provided for @notes_vault_selector_create_error.
  ///
  /// In en, this message translates to:
  /// **'Error creating workspace: {error}'**
  String notes_vault_selector_create_error(Object error);

  /// No description provided for @notes_vault_selector_title.
  ///
  /// In en, this message translates to:
  /// **'Switch Workspace'**
  String get notes_vault_selector_title;

  /// No description provided for @notes_vault_selector_empty.
  ///
  /// In en, this message translates to:
  /// **'No workspaces found'**
  String get notes_vault_selector_empty;

  /// No description provided for @notes_vault_selector_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading workspaces: {error}'**
  String notes_vault_selector_error_loading(Object error);

  /// No description provided for @notes_vault_selector_hint.
  ///
  /// In en, this message translates to:
  /// **'Workspace Name'**
  String get notes_vault_selector_hint;

  /// No description provided for @notes_vault_selector_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Workspace name can only contain letters, numbers, spaces, underscores, and hyphens.'**
  String get notes_vault_selector_validation_error;

  /// No description provided for @notes_vault_selector_title_default.
  ///
  /// In en, this message translates to:
  /// **'My Workspace'**
  String get notes_vault_selector_title_default;

  /// No description provided for @onboarding_screen_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Absolute Privacy'**
  String get onboarding_screen_slide1_title;

  /// No description provided for @onboarding_screen_slide1_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy-First Notebook'**
  String get onboarding_screen_slide1_subtitle;

  /// No description provided for @onboarding_screen_slide1_desc.
  ///
  /// In en, this message translates to:
  /// **'Your notes live completely private on your device in standard Markdown. No accounts, no tracking, pure offline speed and security.'**
  String get onboarding_screen_slide1_desc;

  /// No description provided for @onboarding_screen_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Wikilink Connections'**
  String get onboarding_screen_slide2_title;

  /// No description provided for @onboarding_screen_slide2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Visual Relational Thinking'**
  String get onboarding_screen_slide2_subtitle;

  /// No description provided for @onboarding_screen_slide2_desc.
  ///
  /// In en, this message translates to:
  /// **'Connect thoughts effortlessly by typing [[wikilinks]]. Explore relationships dynamically with automatic backlink indexes.'**
  String get onboarding_screen_slide2_desc;

  /// No description provided for @onboarding_screen_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Thought Graph Map'**
  String get onboarding_screen_slide3_title;

  /// No description provided for @onboarding_screen_slide3_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive Mindmap'**
  String get onboarding_screen_slide3_subtitle;

  /// No description provided for @onboarding_screen_slide3_desc.
  ///
  /// In en, this message translates to:
  /// **'Watch your connected notes blossom into an interactive force-directed graph. Visually navigate and spot patterns in your thinking.'**
  String get onboarding_screen_slide3_desc;

  /// No description provided for @onboarding_screen_slide4_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Journaling'**
  String get onboarding_screen_slide4_title;

  /// No description provided for @onboarding_screen_slide4_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Reflective Habit Building'**
  String get onboarding_screen_slide4_subtitle;

  /// No description provided for @onboarding_screen_slide4_desc.
  ///
  /// In en, this message translates to:
  /// **'Build healthy writing rituals with structured daily templates (Gratitude, Reflection, Goals), set word count targets, and track your active writing streak.'**
  String get onboarding_screen_slide4_desc;

  /// No description provided for @onboarding_screen_slide5_title.
  ///
  /// In en, this message translates to:
  /// **'Editorial Aesthetics'**
  String get onboarding_screen_slide5_title;

  /// No description provided for @onboarding_screen_slide5_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Friction-Free Design'**
  String get onboarding_screen_slide5_subtitle;

  /// No description provided for @onboarding_screen_slide5_desc.
  ///
  /// In en, this message translates to:
  /// **'Crafted with premium typography and beautiful palettes—Clean Paper, Midnight OLED, and the warm Sepia theme.'**
  String get onboarding_screen_slide5_desc;

  /// No description provided for @onboarding_screen_slide6_title.
  ///
  /// In en, this message translates to:
  /// **'Smart Productivity'**
  String get onboarding_screen_slide6_title;

  /// No description provided for @onboarding_screen_slide6_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Speech & Custom Macros'**
  String get onboarding_screen_slide6_subtitle;

  /// No description provided for @onboarding_screen_slide6_desc.
  ///
  /// In en, this message translates to:
  /// **'Dictate notes offline with real-time text formatting and high-fidelity audio attachments. Insert template checklists and custom macros in one tap.'**
  String get onboarding_screen_slide6_desc;

  /// No description provided for @onboarding_screen_start_writing_semantic.
  ///
  /// In en, this message translates to:
  /// **'Start Writing'**
  String get onboarding_screen_start_writing_semantic;

  /// No description provided for @onboarding_screen_start_writing_label.
  ///
  /// In en, this message translates to:
  /// **'Start Writing'**
  String get onboarding_screen_start_writing_label;

  /// No description provided for @onboarding_screen_next_slide_semantic.
  ///
  /// In en, this message translates to:
  /// **'Next slide'**
  String get onboarding_screen_next_slide_semantic;

  /// No description provided for @onboarding_loading_title.
  ///
  /// In en, this message translates to:
  /// **'Setting up Prism…'**
  String get onboarding_loading_title;

  /// No description provided for @onboarding_loading_description.
  ///
  /// In en, this message translates to:
  /// **'Preparing onboarding guides and setting up workspace.'**
  String get onboarding_loading_description;

  /// No description provided for @onboarding_vault_setup_folder_picker_error.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder picker: {error}'**
  String onboarding_vault_setup_folder_picker_error(Object error);

  /// No description provided for @onboarding_vault_setup_name_required_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the main folder.'**
  String get onboarding_vault_setup_name_required_error;

  /// No description provided for @onboarding_vault_setup_invalid_chars_error.
  ///
  /// In en, this message translates to:
  /// **'Workspace name can only contain letters, numbers, spaces, underscores, and hyphens.'**
  String get onboarding_vault_setup_invalid_chars_error;

  /// No description provided for @onboarding_vault_setup_folder_required_error.
  ///
  /// In en, this message translates to:
  /// **'Please select a storage folder.'**
  String get onboarding_vault_setup_folder_required_error;

  /// No description provided for @onboarding_vault_setup_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get onboarding_vault_setup_permission_title;

  /// No description provided for @onboarding_vault_setup_permission_desc.
  ///
  /// In en, this message translates to:
  /// **'To write and sync note files inside your chosen documents folder, Android requires the \"All Files Access\" permission.'**
  String get onboarding_vault_setup_permission_desc;

  /// No description provided for @onboarding_vault_setup_permission_retry_desc.
  ///
  /// In en, this message translates to:
  /// **'Please enable All Files Access for Prism and tap Next again.'**
  String get onboarding_vault_setup_permission_retry_desc;

  /// No description provided for @onboarding_vault_setup_import_success.
  ///
  /// In en, this message translates to:
  /// **'Found existing workspaces in \"{hubName}\". Imported and opened \"{activeVault}\".'**
  String onboarding_vault_setup_import_success(
    Object activeVault,
    Object hubName,
  );

  /// No description provided for @onboarding_vault_setup_import_error.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}. Please try again.'**
  String onboarding_vault_setup_import_error(Object error);

  /// No description provided for @onboarding_vault_setup_setup_error.
  ///
  /// In en, this message translates to:
  /// **'Setup failed: {error}. Please try again.'**
  String onboarding_vault_setup_setup_error(Object error);

  /// No description provided for @onboarding_vault_setup_config_location_title.
  ///
  /// In en, this message translates to:
  /// **'Workspace Storage Location'**
  String get onboarding_vault_setup_config_location_title;

  /// No description provided for @onboarding_vault_setup_name_vault_title.
  ///
  /// In en, this message translates to:
  /// **'Name your first workspace'**
  String get onboarding_vault_setup_name_vault_title;

  /// No description provided for @onboarding_vault_setup_choose_location_desc.
  ///
  /// In en, this message translates to:
  /// **'Prism stores all your notes directly on your device. Choose where your main storage folder (Prism Hub) lives. You can switch between multiple workspaces later.'**
  String get onboarding_vault_setup_choose_location_desc;

  /// No description provided for @onboarding_vault_setup_first_vault_desc.
  ///
  /// In en, this message translates to:
  /// **'This will be your private notebook folder created on this device.'**
  String get onboarding_vault_setup_first_vault_desc;

  /// No description provided for @onboarding_vault_setup_vault_location_label.
  ///
  /// In en, this message translates to:
  /// **'Workspace Location'**
  String get onboarding_vault_setup_vault_location_label;

  /// No description provided for @onboarding_vault_setup_device_storage_label.
  ///
  /// In en, this message translates to:
  /// **'Device storage'**
  String get onboarding_vault_setup_device_storage_label;

  /// No description provided for @onboarding_vault_setup_device_storage_desc.
  ///
  /// In en, this message translates to:
  /// **'Allows Prism data to be accessed by other apps.'**
  String get onboarding_vault_setup_device_storage_desc;

  /// No description provided for @onboarding_vault_setup_app_storage_label.
  ///
  /// In en, this message translates to:
  /// **'App storage'**
  String get onboarding_vault_setup_app_storage_label;

  /// No description provided for @onboarding_vault_setup_app_storage_desc_android.
  ///
  /// In en, this message translates to:
  /// **'Your data will not be accessible to other apps.'**
  String get onboarding_vault_setup_app_storage_desc_android;

  /// No description provided for @onboarding_vault_setup_app_storage_desc_warning.
  ///
  /// In en, this message translates to:
  /// **'Android will delete your data if you uninstall Prism.'**
  String get onboarding_vault_setup_app_storage_desc_warning;

  /// No description provided for @onboarding_vault_setup_hub_name_label.
  ///
  /// In en, this message translates to:
  /// **'Prism Hub Name'**
  String get onboarding_vault_setup_hub_name_label;

  /// No description provided for @onboarding_vault_setup_hub_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Prism Hub, My Notes, Second Brain'**
  String get onboarding_vault_setup_hub_name_hint;

  /// No description provided for @onboarding_vault_setup_location_selected.
  ///
  /// In en, this message translates to:
  /// **'Location selected'**
  String get onboarding_vault_setup_location_selected;

  /// No description provided for @onboarding_vault_setup_choose_folder_prompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a folder'**
  String get onboarding_vault_setup_choose_folder_prompt;

  /// No description provided for @onboarding_vault_setup_location_creation_desc.
  ///
  /// In en, this message translates to:
  /// **'Prism will create your main directory inside this folder.'**
  String get onboarding_vault_setup_location_creation_desc;

  /// No description provided for @onboarding_vault_setup_choose_folder_warning.
  ///
  /// In en, this message translates to:
  /// **'Choose a storage folder above to continue'**
  String get onboarding_vault_setup_choose_folder_warning;

  /// No description provided for @onboarding_vault_setup_vault_name_label.
  ///
  /// In en, this message translates to:
  /// **'Workspace Name'**
  String get onboarding_vault_setup_vault_name_label;

  /// No description provided for @onboarding_vault_setup_vault_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Workspace, Personal, Research'**
  String get onboarding_vault_setup_vault_name_hint;

  /// No description provided for @onboarding_vault_setup_telemetry_title.
  ///
  /// In en, this message translates to:
  /// **'Help improve Prism with anonymous diagnostics'**
  String get onboarding_vault_setup_telemetry_title;

  /// No description provided for @onboarding_vault_setup_telemetry_desc.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous crash reports and feature usage to help us improve Prism. Your notes, titles, and search queries are strictly private and never collected.'**
  String get onboarding_vault_setup_telemetry_desc;

  /// No description provided for @onboarding_vault_setup_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Begin'**
  String get onboarding_vault_setup_confirm_button;

  /// No description provided for @onboarding_vault_setup_back_button.
  ///
  /// In en, this message translates to:
  /// **'Back to step 1'**
  String get onboarding_vault_setup_back_button;

  /// No description provided for @onboarding_vault_setup_back_button_step2.
  ///
  /// In en, this message translates to:
  /// **'Back to step 2'**
  String get onboarding_vault_setup_back_button_step2;

  /// No description provided for @onboarding_vault_setup_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Diagnostics'**
  String get onboarding_vault_setup_privacy_title;

  /// No description provided for @onboarding_vault_setup_privacy_desc.
  ///
  /// In en, this message translates to:
  /// **'Prism is built from the ground up to respect your privacy. Choose whether you would like to share anonymous usage data and crash reports to help us improve the app.'**
  String get onboarding_vault_setup_privacy_desc;

  /// No description provided for @onboarding_vault_setup_default_hub_name.
  ///
  /// In en, this message translates to:
  /// **'Prism Hub'**
  String get onboarding_vault_setup_default_hub_name;

  /// No description provided for @onboarding_vault_setup_default_vault_name.
  ///
  /// In en, this message translates to:
  /// **'My Workspace'**
  String get onboarding_vault_setup_default_vault_name;

  /// No description provided for @onboarding_visual_journal_todays_entry.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Entry'**
  String get onboarding_visual_journal_todays_entry;

  /// No description provided for @onboarding_visual_journal_gratitude_heading.
  ///
  /// In en, this message translates to:
  /// **'## 🙏 Gratitude'**
  String get onboarding_visual_journal_gratitude_heading;

  /// No description provided for @onboarding_visual_journal_word_count.
  ///
  /// In en, this message translates to:
  /// **'185 / 250 words'**
  String get onboarding_visual_journal_word_count;

  /// No description provided for @onboarding_visual_productivity_date.
  ///
  /// In en, this message translates to:
  /// **'📅 Date'**
  String get onboarding_visual_productivity_date;

  /// No description provided for @onboarding_visual_productivity_todo.
  ///
  /// In en, this message translates to:
  /// **'☑️ Todo'**
  String get onboarding_visual_productivity_todo;

  /// No description provided for @onboarding_visual_themes_clean_paper.
  ///
  /// In en, this message translates to:
  /// **'Clean Paper'**
  String get onboarding_visual_themes_clean_paper;

  /// No description provided for @onboarding_visual_themes_midnight_oled.
  ///
  /// In en, this message translates to:
  /// **'Midnight OLED'**
  String get onboarding_visual_themes_midnight_oled;

  /// No description provided for @onboarding_visual_themes_warm_sepia.
  ///
  /// In en, this message translates to:
  /// **'Warm Sepia'**
  String get onboarding_visual_themes_warm_sepia;

  /// No description provided for @onboarding_visual_wikilinks_brain_map.
  ///
  /// In en, this message translates to:
  /// **'Brain Map'**
  String get onboarding_visual_wikilinks_brain_map;

  /// No description provided for @onboarding_visual_wikilinks_wikilink_label.
  ///
  /// In en, this message translates to:
  /// **'[[ wikilink ]]'**
  String get onboarding_visual_wikilinks_wikilink_label;

  /// No description provided for @settings_attachments_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Attachments'**
  String get settings_attachments_title;

  /// No description provided for @settings_attachments_section_header.
  ///
  /// In en, this message translates to:
  /// **'ATTACHED FILES'**
  String get settings_attachments_section_header;

  /// No description provided for @settings_attachments_error.
  ///
  /// In en, this message translates to:
  /// **'Error loading attachments: {error}'**
  String settings_attachments_error(Object error);

  /// No description provided for @settings_attachments_storage_consumed.
  ///
  /// In en, this message translates to:
  /// **'Storage Consumed'**
  String get settings_attachments_storage_consumed;

  /// No description provided for @settings_attachments_count_saved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment saved} other{{count} attachments saved}}'**
  String settings_attachments_count_saved(num count);

  /// No description provided for @settings_attachments_clean_orphaned.
  ///
  /// In en, this message translates to:
  /// **'Clean Orphaned'**
  String get settings_attachments_clean_orphaned;

  /// No description provided for @settings_attachments_orphaned_warning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unlinked recording is taking up {size} space.} other{{count} unlinked recordings are taking up {size} space.}}'**
  String settings_attachments_orphaned_warning(num count, Object size);

  /// No description provided for @settings_attachments_play_recording_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Play Recording'**
  String get settings_attachments_play_recording_tooltip;

  /// No description provided for @settings_attachments_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No Attachments Found'**
  String get settings_attachments_empty_title;

  /// No description provided for @settings_attachments_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Voice recordings kept when editing notes will appear here.'**
  String get settings_attachments_empty_desc;

  /// No description provided for @settings_attachments_delete_confirm_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this audio recording from your device? This action cannot be undone.'**
  String get settings_attachments_delete_confirm_desc;

  /// No description provided for @settings_attachments_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Attachment deleted.'**
  String get settings_attachments_delete_success;

  /// No description provided for @settings_attachments_delete_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String settings_attachments_delete_error(Object error);

  /// No description provided for @settings_attachments_purge_orphaned_title.
  ///
  /// In en, this message translates to:
  /// **'Purge Orphaned Files'**
  String get settings_attachments_purge_orphaned_title;

  /// No description provided for @settings_attachments_purge_orphaned_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all {count} unlinked recordings ({size}) from your device storage? Notes will not be affected.'**
  String settings_attachments_purge_orphaned_desc(Object count, Object size);

  /// No description provided for @settings_attachments_purge_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully cleaned up {count} orphaned files.'**
  String settings_attachments_purge_success(Object count);

  /// No description provided for @settings_attachments_purge_error.
  ///
  /// In en, this message translates to:
  /// **'Error purging files: {error}'**
  String settings_attachments_purge_error(Object error);

  /// No description provided for @settings_attachments_purge_all_button.
  ///
  /// In en, this message translates to:
  /// **'Purge All'**
  String get settings_attachments_purge_all_button;

  /// No description provided for @settings_cloud_sync_init_error.
  ///
  /// In en, this message translates to:
  /// **'Error initializing sync service: {error}'**
  String settings_cloud_sync_init_error(Object error);

  /// No description provided for @settings_cloud_sync_signout_success.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully.'**
  String get settings_cloud_sync_signout_success;

  /// No description provided for @settings_cloud_sync_signout_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String settings_cloud_sync_signout_error(Object error);

  /// No description provided for @settings_cloud_sync_passphrase_empty.
  ///
  /// In en, this message translates to:
  /// **'Passphrase cannot be empty'**
  String get settings_cloud_sync_passphrase_empty;

  /// No description provided for @settings_cloud_sync_configured_success.
  ///
  /// In en, this message translates to:
  /// **'Sync configured successfully!'**
  String get settings_cloud_sync_configured_success;

  /// No description provided for @settings_cloud_sync_disable_title.
  ///
  /// In en, this message translates to:
  /// **'Disable Sync for {vaultName}?'**
  String settings_cloud_sync_disable_title(Object vaultName);

  /// No description provided for @settings_cloud_sync_disable_desc.
  ///
  /// In en, this message translates to:
  /// **'Would you like to keep your encrypted backup on Google Drive, or delete it from the cloud?'**
  String get settings_cloud_sync_disable_desc;

  /// No description provided for @settings_cloud_sync_keep_cloud_button.
  ///
  /// In en, this message translates to:
  /// **'Keep in Cloud'**
  String get settings_cloud_sync_keep_cloud_button;

  /// No description provided for @settings_cloud_sync_delete_cloud_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete cloud data: {error}'**
  String settings_cloud_sync_delete_cloud_error(Object error);

  /// No description provided for @settings_cloud_sync_delete_cloud_success.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup for {vaultName} deleted successfully.'**
  String settings_cloud_sync_delete_cloud_success(Object vaultName);

  /// No description provided for @settings_cloud_sync_sync_success.
  ///
  /// In en, this message translates to:
  /// **'Sync successful! Uploaded: {uploaded}, Downloaded: {downloaded}'**
  String settings_cloud_sync_sync_success(Object downloaded, Object uploaded);

  /// No description provided for @settings_cloud_sync_purge_title.
  ///
  /// In en, this message translates to:
  /// **'Purge All Cloud Backups?'**
  String get settings_cloud_sync_purge_title;

  /// No description provided for @settings_cloud_sync_purge_desc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all synced vaults and files from your Google Drive AppData folder and sign you out.'**
  String get settings_cloud_sync_purge_desc;

  /// No description provided for @settings_cloud_sync_purge_passphrase_prompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your global sync passphrase to confirm:'**
  String get settings_cloud_sync_purge_passphrase_prompt;

  /// No description provided for @settings_cloud_sync_passphrase_label.
  ///
  /// In en, this message translates to:
  /// **'Sync Passphrase'**
  String get settings_cloud_sync_passphrase_label;

  /// No description provided for @settings_cloud_sync_passphrase_incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect passphrase!'**
  String get settings_cloud_sync_passphrase_incorrect;

  /// No description provided for @settings_cloud_sync_purge_everything_button.
  ///
  /// In en, this message translates to:
  /// **'Purge Everything'**
  String get settings_cloud_sync_purge_everything_button;

  /// No description provided for @settings_cloud_sync_purge_success_msg.
  ///
  /// In en, this message translates to:
  /// **'All cloud data purged and signed out successfully!'**
  String get settings_cloud_sync_purge_success_msg;

  /// No description provided for @settings_cloud_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get settings_cloud_sync_title;

  /// No description provided for @settings_cloud_sync_section_header.
  ///
  /// In en, this message translates to:
  /// **'Global Selective Sync'**
  String get settings_cloud_sync_section_header;

  /// No description provided for @settings_cloud_sync_section_desc.
  ///
  /// In en, this message translates to:
  /// **'Secure your notes with end-to-end encryption. Toggle sync for each vault individually and keep your data backed up on Google Drive.'**
  String get settings_cloud_sync_section_desc;

  /// No description provided for @settings_cloud_sync_gdrive_header.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Connection'**
  String get settings_cloud_sync_gdrive_header;

  /// No description provided for @settings_cloud_sync_gdrive_desc.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google Drive account to enable cloud backups.'**
  String get settings_cloud_sync_gdrive_desc;

  /// No description provided for @settings_cloud_sync_connect_button.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get settings_cloud_sync_connect_button;

  /// No description provided for @settings_cloud_sync_disconnect_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Account'**
  String get settings_cloud_sync_disconnect_tooltip;

  /// No description provided for @settings_cloud_sync_security_header.
  ///
  /// In en, this message translates to:
  /// **'Security & Encryption'**
  String get settings_cloud_sync_security_header;

  /// No description provided for @settings_cloud_sync_e2e_title.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption Active'**
  String get settings_cloud_sync_e2e_title;

  /// No description provided for @settings_cloud_sync_e2e_desc.
  ///
  /// In en, this message translates to:
  /// **'All notes are encrypted on-device before syncing.'**
  String get settings_cloud_sync_e2e_desc;

  /// No description provided for @settings_custom_macros_title.
  ///
  /// In en, this message translates to:
  /// **'Toolbar Macros'**
  String get settings_custom_macros_title;

  /// No description provided for @settings_custom_macros_desc.
  ///
  /// In en, this message translates to:
  /// **'Define 3 to 5 custom text injection macros for your accessory formatting toolbar.'**
  String get settings_custom_macros_desc;

  /// No description provided for @settings_custom_macros_add_button.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Macro'**
  String get settings_custom_macros_add_button;

  /// No description provided for @settings_custom_macros_reset_button.
  ///
  /// In en, this message translates to:
  /// **'Reset Default Macros'**
  String get settings_custom_macros_reset_button;

  /// No description provided for @settings_custom_macros_reset_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Macros'**
  String get settings_custom_macros_reset_confirm_title;

  /// No description provided for @settings_custom_macros_reset_confirm_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all macros to their defaults? This will erase your custom edits.'**
  String get settings_custom_macros_reset_confirm_desc;

  /// No description provided for @settings_custom_macros_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Macros reset to defaults.'**
  String get settings_custom_macros_reset_success;

  /// No description provided for @settings_custom_macros_reset_error.
  ///
  /// In en, this message translates to:
  /// **'Error resetting macros: {error}'**
  String settings_custom_macros_reset_error(Object error);

  /// No description provided for @settings_custom_macros_card_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hold card to reorder'**
  String get settings_custom_macros_card_tooltip;

  /// No description provided for @settings_custom_macros_editor_title_add.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Macro'**
  String get settings_custom_macros_editor_title_add;

  /// No description provided for @settings_custom_macros_editor_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Macro'**
  String get settings_custom_macros_editor_title_edit;

  /// No description provided for @settings_custom_macros_label_field.
  ///
  /// In en, this message translates to:
  /// **'BUTTON LABEL'**
  String get settings_custom_macros_label_field;

  /// No description provided for @settings_custom_macros_text_field.
  ///
  /// In en, this message translates to:
  /// **'MACRO INJECTION TEXT'**
  String get settings_custom_macros_text_field;

  /// No description provided for @settings_custom_macros_label_required.
  ///
  /// In en, this message translates to:
  /// **'Label is required'**
  String get settings_custom_macros_label_required;

  /// No description provided for @settings_custom_macros_text_required.
  ///
  /// In en, this message translates to:
  /// **'Injection text is required'**
  String get settings_custom_macros_text_required;

  /// No description provided for @settings_custom_macros_placeholder_title.
  ///
  /// In en, this message translates to:
  /// **'TAP DYNAMIC PLACEHOLDERS TO INSERT:'**
  String get settings_custom_macros_placeholder_title;

  /// No description provided for @settings_custom_macros_placeholder_desc.
  ///
  /// In en, this message translates to:
  /// **'You can use dynamic placeholders like \'{\'\'{\'datetime\'}\'\'}\' to insert the current date and time automatically.'**
  String get settings_custom_macros_placeholder_desc;

  /// No description provided for @settings_custom_templates_title.
  ///
  /// In en, this message translates to:
  /// **'Custom Templates'**
  String get settings_custom_templates_title;

  /// No description provided for @settings_custom_templates_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Template'**
  String get settings_custom_templates_create_button;

  /// No description provided for @settings_custom_templates_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading templates: {error}'**
  String settings_custom_templates_error_loading(String error);

  /// No description provided for @settings_custom_templates_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No Custom Templates'**
  String get settings_custom_templates_empty_title;

  /// No description provided for @settings_custom_templates_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'Create templates to quickly structure new notes. Templates support the \'{\'\'{\'datetime\'}\'\'}\' placeholder.'**
  String get settings_custom_templates_empty_desc;

  /// No description provided for @settings_custom_templates_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get settings_custom_templates_delete_confirm_title;

  /// No description provided for @settings_custom_templates_delete_confirm_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete the template \"{name}\"? This action cannot be undone.'**
  String settings_custom_templates_delete_confirm_desc(String name);

  /// No description provided for @settings_custom_templates_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Template deleted.'**
  String get settings_custom_templates_delete_success;

  /// No description provided for @settings_custom_templates_delete_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete template: {error}'**
  String settings_custom_templates_delete_error(String error);

  /// No description provided for @settings_custom_templates_template_card_words.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String settings_custom_templates_template_card_words(num count);

  /// No description provided for @settings_custom_templates_template_card_open_editor.
  ///
  /// In en, this message translates to:
  /// **'Open in Editor'**
  String get settings_custom_templates_template_card_open_editor;

  /// No description provided for @settings_custom_templates_create_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get settings_custom_templates_create_dialog_title;

  /// No description provided for @settings_custom_templates_create_dialog_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly Review'**
  String get settings_custom_templates_create_dialog_hint;

  /// No description provided for @settings_custom_templates_create_dialog_validation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a template name'**
  String get settings_custom_templates_create_dialog_validation;

  /// No description provided for @settings_custom_templates_create_success.
  ///
  /// In en, this message translates to:
  /// **'Template created. Open it from the list to write content.'**
  String get settings_custom_templates_create_success;

  /// No description provided for @settings_editor_pref_title.
  ///
  /// In en, this message translates to:
  /// **'Editor Preferences'**
  String get settings_editor_pref_title;

  /// No description provided for @settings_editor_pref_section_general.
  ///
  /// In en, this message translates to:
  /// **'Text & Layout'**
  String get settings_editor_pref_section_general;

  /// No description provided for @settings_editor_pref_show_line_numbers.
  ///
  /// In en, this message translates to:
  /// **'Display Line Numbers'**
  String get settings_editor_pref_show_line_numbers;

  /// No description provided for @settings_editor_pref_show_line_numbers_desc.
  ///
  /// In en, this message translates to:
  /// **'Show logical line numbers in the editor margin'**
  String get settings_editor_pref_show_line_numbers_desc;

  /// No description provided for @settings_editor_pref_bracket_pairing.
  ///
  /// In en, this message translates to:
  /// **'Auto-pair Brackets & Quotes'**
  String get settings_editor_pref_bracket_pairing;

  /// No description provided for @settings_editor_pref_bracket_pairing_desc.
  ///
  /// In en, this message translates to:
  /// **'Automatically insert closing brackets and quotes'**
  String get settings_editor_pref_bracket_pairing_desc;

  /// No description provided for @settings_editor_pref_font_family.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get settings_editor_pref_font_family;

  /// No description provided for @settings_editor_pref_font_size.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settings_editor_pref_font_size;

  /// No description provided for @settings_editor_pref_line_width.
  ///
  /// In en, this message translates to:
  /// **'Line width'**
  String get settings_editor_pref_line_width;

  /// No description provided for @settings_editor_pref_gated_premium.
  ///
  /// In en, this message translates to:
  /// **'Get Prism Pro to unlock this preference'**
  String get settings_editor_pref_gated_premium;

  /// No description provided for @settings_journal_pref_title.
  ///
  /// In en, this message translates to:
  /// **'Journal Preferences'**
  String get settings_journal_pref_title;

  /// No description provided for @settings_journal_pref_section_behavior.
  ///
  /// In en, this message translates to:
  /// **'Reflections Startup'**
  String get settings_journal_pref_section_behavior;

  /// No description provided for @settings_journal_pref_auto_create.
  ///
  /// In en, this message translates to:
  /// **'Auto-create Daily Note on Launch'**
  String get settings_journal_pref_auto_create;

  /// No description provided for @settings_journal_pref_auto_create_desc.
  ///
  /// In en, this message translates to:
  /// **'Open or create today\'\'s journal note when launching the app'**
  String get settings_journal_pref_auto_create_desc;

  /// No description provided for @settings_journal_pref_week_start.
  ///
  /// In en, this message translates to:
  /// **'Start of Week'**
  String get settings_journal_pref_week_start;

  /// No description provided for @settings_journal_pref_week_start_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose which day starts the calendar strip and habit streak calculation.'**
  String get settings_journal_pref_week_start_desc;

  /// No description provided for @settings_journal_pref_week_start_sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settings_journal_pref_week_start_sunday;

  /// No description provided for @settings_journal_pref_week_start_monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settings_journal_pref_week_start_monday;

  /// No description provided for @settings_journal_pref_section_habits.
  ///
  /// In en, this message translates to:
  /// **'Habits & Consistency'**
  String get settings_journal_pref_section_habits;

  /// No description provided for @settings_journal_pref_show_streaks.
  ///
  /// In en, this message translates to:
  /// **'Show Streaks & Consistency Grid'**
  String get settings_journal_pref_show_streaks;

  /// No description provided for @settings_journal_pref_show_streaks_desc.
  ///
  /// In en, this message translates to:
  /// **'Display consecutive days counter and activity matrix in the daily journal.'**
  String get settings_journal_pref_show_streaks_desc;

  /// No description provided for @settings_custom_macros_reset_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settings_custom_macros_reset_tooltip;

  /// No description provided for @settings_custom_macros_header.
  ///
  /// In en, this message translates to:
  /// **'Quick Macros'**
  String get settings_custom_macros_header;

  /// No description provided for @settings_custom_macros_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Macro'**
  String get settings_custom_macros_delete_tooltip;

  /// No description provided for @settings_custom_macros_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_custom_macros_cancel_button;

  /// No description provided for @settings_custom_macros_reset_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settings_custom_macros_reset_confirm_button;

  /// No description provided for @settings_custom_macros_label_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Date, Todo, Tag'**
  String get settings_custom_macros_label_hint;

  /// No description provided for @settings_custom_macros_label_length_error.
  ///
  /// In en, this message translates to:
  /// **'Label must be 12 chars or less'**
  String get settings_custom_macros_label_length_error;

  /// No description provided for @settings_custom_macros_text_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter text, templates, tags, or placeholders…'**
  String get settings_custom_macros_text_hint;

  /// No description provided for @settings_custom_macros_placeholder_date_desc.
  ///
  /// In en, this message translates to:
  /// **'Current Date'**
  String get settings_custom_macros_placeholder_date_desc;

  /// No description provided for @settings_custom_macros_placeholder_time_desc.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get settings_custom_macros_placeholder_time_desc;

  /// No description provided for @settings_custom_macros_placeholder_datetime_desc.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get settings_custom_macros_placeholder_datetime_desc;

  /// No description provided for @settings_custom_macros_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get settings_custom_macros_save_button;

  /// No description provided for @settings_custom_macros_cannot_delete_desc.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete (Min 3 required)'**
  String get settings_custom_macros_cannot_delete_desc;

  /// No description provided for @settings_custom_macros_create_button_label.
  ///
  /// In en, this message translates to:
  /// **'Create Macro'**
  String get settings_custom_macros_create_button_label;

  /// No description provided for @settings_custom_templates_create_button_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get settings_custom_templates_create_button_tooltip;

  /// No description provided for @settings_custom_templates_manager_header.
  ///
  /// In en, this message translates to:
  /// **'Template Manager'**
  String get settings_custom_templates_manager_header;

  /// No description provided for @settings_custom_templates_manager_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage reusable page templates for note creation.'**
  String get settings_custom_templates_manager_desc;

  /// No description provided for @settings_custom_templates_list_header.
  ///
  /// In en, this message translates to:
  /// **'TEMPLATES'**
  String get settings_custom_templates_list_header;

  /// No description provided for @settings_custom_templates_edit_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Template Content'**
  String get settings_custom_templates_edit_tooltip;

  /// No description provided for @settings_custom_templates_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get settings_custom_templates_delete_tooltip;

  /// No description provided for @settings_custom_templates_create_dialog_prompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for the new template:'**
  String get settings_custom_templates_create_dialog_prompt;

  /// No description provided for @settings_custom_templates_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_custom_templates_cancel_button;

  /// No description provided for @settings_custom_templates_create_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to create template: {error}'**
  String settings_custom_templates_create_error(String error);

  /// No description provided for @settings_custom_templates_create_dialog_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get settings_custom_templates_create_dialog_confirm_button;

  /// No description provided for @settings_custom_templates_delete_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settings_custom_templates_delete_confirm_button;

  /// No description provided for @settings_editor_pref_font_size_default.
  ///
  /// In en, this message translates to:
  /// **'{fontSize} (Default)'**
  String settings_editor_pref_font_size_default(String fontSize);

  /// No description provided for @settings_editor_pref_select_font_size.
  ///
  /// In en, this message translates to:
  /// **'Select Font Size'**
  String get settings_editor_pref_select_font_size;

  /// No description provided for @settings_editor_pref_line_width_default.
  ///
  /// In en, this message translates to:
  /// **'{lineWidth} (Default)'**
  String settings_editor_pref_line_width_default(String lineWidth);

  /// No description provided for @settings_editor_pref_select_line_width.
  ///
  /// In en, this message translates to:
  /// **'Select Line Width'**
  String get settings_editor_pref_select_line_width;

  /// No description provided for @settings_editor_pref_section_behaviors.
  ///
  /// In en, this message translates to:
  /// **'Editor Behaviors'**
  String get settings_editor_pref_section_behaviors;

  /// No description provided for @settings_editor_pref_show_backlinks.
  ///
  /// In en, this message translates to:
  /// **'Show Backlinks by Default'**
  String get settings_editor_pref_show_backlinks;

  /// No description provided for @settings_editor_pref_show_backlinks_desc.
  ///
  /// In en, this message translates to:
  /// **'Display the backlinks panel at the bottom of notes'**
  String get settings_editor_pref_show_backlinks_desc;

  /// No description provided for @settings_journal_pref_section_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Streaks'**
  String get settings_journal_pref_section_calendar;

  /// No description provided for @settings_journal_pref_select_week_start.
  ///
  /// In en, this message translates to:
  /// **'Select Start of Week'**
  String get settings_journal_pref_select_week_start;

  /// No description provided for @settings_manage_vaults_relocate_migrate_success.
  ///
  /// In en, this message translates to:
  /// **'Storage location relocated and vaults migrated.'**
  String get settings_manage_vaults_relocate_migrate_success;

  /// No description provided for @settings_manage_vaults_relocate_change_success.
  ///
  /// In en, this message translates to:
  /// **'Storage location changed.'**
  String get settings_manage_vaults_relocate_change_success;

  /// No description provided for @settings_manage_vaults_relocate_error.
  ///
  /// In en, this message translates to:
  /// **'Error relocating storage: {error}'**
  String settings_manage_vaults_relocate_error(String error);

  /// No description provided for @settings_manage_vaults_create_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Create New Vault'**
  String get settings_manage_vaults_create_dialog_title;

  /// No description provided for @settings_manage_vaults_create_dialog_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Personal'**
  String get settings_manage_vaults_create_dialog_hint;

  /// No description provided for @settings_manage_vaults_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_manage_vaults_cancel_button;

  /// No description provided for @settings_manage_vaults_create_dialog_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get settings_manage_vaults_create_dialog_confirm_button;

  /// No description provided for @settings_manage_vaults_create_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to create vault: {error}'**
  String settings_manage_vaults_create_error(String error);

  /// No description provided for @settings_manage_vaults_rename_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Rename Vault'**
  String get settings_manage_vaults_rename_dialog_title;

  /// No description provided for @settings_manage_vaults_rename_dialog_label.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get settings_manage_vaults_rename_dialog_label;

  /// No description provided for @settings_manage_vaults_rename_dialog_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get settings_manage_vaults_rename_dialog_confirm_button;

  /// No description provided for @settings_manage_vaults_rename_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename vault: {error}'**
  String settings_manage_vaults_rename_error(String error);

  /// No description provided for @settings_manage_vaults_delete_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Vault \"{vaultName}\"?'**
  String settings_manage_vaults_delete_dialog_title(String vaultName);

  /// No description provided for @settings_manage_vaults_delete_dialog_desc_warning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this vault directory and all notes inside it from this device. This cannot be undone.'**
  String get settings_manage_vaults_delete_dialog_desc_warning;

  /// No description provided for @settings_manage_vaults_delete_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get settings_manage_vaults_delete_confirm_button;

  /// No description provided for @settings_theme_gallery_applied_success.
  ///
  /// In en, this message translates to:
  /// **'Theme applied successfully!'**
  String get settings_theme_gallery_applied_success;

  /// No description provided for @settings_theme_gallery_apply_button.
  ///
  /// In en, this message translates to:
  /// **'Use Theme'**
  String get settings_theme_gallery_apply_button;

  /// No description provided for @settings_theme_gallery_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated editorial layouts & typography'**
  String get settings_theme_gallery_subtitle;

  /// No description provided for @settings_theme_gallery_live_preview_header.
  ///
  /// In en, this message translates to:
  /// **'LIVE SCREEN PREVIEW'**
  String get settings_theme_gallery_live_preview_header;

  /// No description provided for @settings_theme_gallery_try_premium_label.
  ///
  /// In en, this message translates to:
  /// **'Try premium colors in the mockup'**
  String get settings_theme_gallery_try_premium_label;

  /// No description provided for @settings_theme_gallery_live_preview_toggle.
  ///
  /// In en, this message translates to:
  /// **'Live Preview Mode'**
  String get settings_theme_gallery_live_preview_toggle;

  /// No description provided for @settings_theme_gallery_light_editorial_header.
  ///
  /// In en, this message translates to:
  /// **'LIGHT EDITORIAL PALETTES'**
  String get settings_theme_gallery_light_editorial_header;

  /// No description provided for @settings_theme_gallery_tab_list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get settings_theme_gallery_tab_list;

  /// No description provided for @settings_theme_gallery_tab_editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settings_theme_gallery_tab_editor;

  /// No description provided for @settings_theme_gallery_tab_graph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get settings_theme_gallery_tab_graph;

  /// No description provided for @settings_main_pro_tile_upgrade_button.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get settings_main_pro_tile_upgrade_button;

  /// No description provided for @settings_main_section_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_main_section_appearance;

  /// No description provided for @settings_main_appearance_font_family.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get settings_main_appearance_font_family;

  /// No description provided for @settings_main_appearance_font_family_default.
  ///
  /// In en, this message translates to:
  /// **'{font} (Default)'**
  String settings_main_appearance_font_family_default(String font);

  /// No description provided for @settings_main_appearance_select_font_family.
  ///
  /// In en, this message translates to:
  /// **'Select Font Family'**
  String get settings_main_appearance_select_font_family;

  /// No description provided for @settings_main_section_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_main_section_preferences;

  /// No description provided for @settings_main_section_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync & Data'**
  String get settings_main_section_sync;

  /// No description provided for @settings_main_export_title.
  ///
  /// In en, this message translates to:
  /// **'Vault Export'**
  String get settings_main_export_title;

  /// No description provided for @settings_main_export_desc.
  ///
  /// In en, this message translates to:
  /// **'Download all notes as ZIP, PDF or JSON'**
  String get settings_main_export_desc;

  /// No description provided for @settings_main_section_gestures.
  ///
  /// In en, this message translates to:
  /// **'Gestures & Feedback'**
  String get settings_main_section_gestures;

  /// No description provided for @settings_main_section_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settings_main_section_subscription;

  /// No description provided for @settings_main_pro_status_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription & billing'**
  String get settings_main_pro_status_desc;

  /// No description provided for @settings_main_pro_customer_center_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to open Customer Center: {error}'**
  String settings_main_pro_customer_center_error(String error);

  /// No description provided for @settings_export_bottom_sheet_choose_format.
  ///
  /// In en, this message translates to:
  /// **'Choose a format to export your notes'**
  String get settings_export_bottom_sheet_choose_format;

  /// No description provided for @settings_export_bottom_sheet_exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get settings_export_bottom_sheet_exporting;

  /// No description provided for @settings_export_bottom_sheet_complete.
  ///
  /// In en, this message translates to:
  /// **'Export Complete'**
  String get settings_export_bottom_sheet_complete;

  /// No description provided for @settings_export_bottom_sheet_notes_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}} · {sizeStr}'**
  String settings_export_bottom_sheet_notes_count(int count, String sizeStr);

  /// No description provided for @settings_export_bottom_sheet_done_button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get settings_export_bottom_sheet_done_button;

  /// No description provided for @settings_export_format_json_label.
  ///
  /// In en, this message translates to:
  /// **'JSON export'**
  String get settings_export_format_json_label;

  /// No description provided for @settings_export_format_json_desc.
  ///
  /// In en, this message translates to:
  /// **'All notes, tags, backlinks and folder names in a structured JSON file'**
  String get settings_export_format_json_desc;

  /// No description provided for @settings_export_format_zip_label.
  ///
  /// In en, this message translates to:
  /// **'ZIP archive'**
  String get settings_export_format_zip_label;

  /// No description provided for @settings_export_format_zip_desc.
  ///
  /// In en, this message translates to:
  /// **'All markdown notes and attachments in a single ZIP file'**
  String get settings_export_format_zip_desc;

  /// No description provided for @settings_export_format_pdf_compiled_label.
  ///
  /// In en, this message translates to:
  /// **'Single PDF'**
  String get settings_export_format_pdf_compiled_label;

  /// No description provided for @settings_export_format_pdf_compiled_desc.
  ///
  /// In en, this message translates to:
  /// **'All notes compiled into one paginated PDF document'**
  String get settings_export_format_pdf_compiled_desc;

  /// No description provided for @settings_export_format_pdf_zipped_label.
  ///
  /// In en, this message translates to:
  /// **'PDFs in ZIP'**
  String get settings_export_format_pdf_zipped_label;

  /// No description provided for @settings_export_format_pdf_zipped_desc.
  ///
  /// In en, this message translates to:
  /// **'Each note rendered as its own PDF, bundled in a ZIP'**
  String get settings_export_format_pdf_zipped_desc;

  /// No description provided for @settings_manage_vaults_rename_dialog_hint.
  ///
  /// In en, this message translates to:
  /// **'Vault Name'**
  String get settings_manage_vaults_rename_dialog_hint;

  /// No description provided for @settings_theme_gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Theme Gallery'**
  String get settings_theme_gallery_title;

  /// No description provided for @settings_main_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_main_title;

  /// No description provided for @settings_main_pro_tile_title.
  ///
  /// In en, this message translates to:
  /// **'Prism Pro'**
  String get settings_main_pro_tile_title;

  /// No description provided for @settings_main_pro_tile_desc.
  ///
  /// In en, this message translates to:
  /// **'Unlock cloud sync, custom templates & macros, and premium typography & themes.'**
  String get settings_main_pro_tile_desc;

  /// No description provided for @settings_main_editor_title.
  ///
  /// In en, this message translates to:
  /// **'Editor Preferences'**
  String get settings_main_editor_title;

  /// No description provided for @settings_main_editor_desc.
  ///
  /// In en, this message translates to:
  /// **'Font size, line width, line numbers, and auto-pairing'**
  String get settings_main_editor_desc;

  /// No description provided for @settings_main_journal_title.
  ///
  /// In en, this message translates to:
  /// **'Journal Preferences'**
  String get settings_main_journal_title;

  /// No description provided for @settings_main_journal_desc.
  ///
  /// In en, this message translates to:
  /// **'Start of week and auto-creation settings'**
  String get settings_main_journal_desc;

  /// No description provided for @settings_main_macros_title.
  ///
  /// In en, this message translates to:
  /// **'Custom Toolbar Macros'**
  String get settings_main_macros_title;

  /// No description provided for @settings_main_macros_desc.
  ///
  /// In en, this message translates to:
  /// **'Define 3–5 custom quick-insert macros'**
  String get settings_main_macros_desc;

  /// No description provided for @settings_main_templates_title.
  ///
  /// In en, this message translates to:
  /// **'Custom Templates'**
  String get settings_main_templates_title;

  /// No description provided for @settings_main_templates_desc.
  ///
  /// In en, this message translates to:
  /// **'Create reusable note templates'**
  String get settings_main_templates_desc;

  /// No description provided for @settings_main_attachments_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Attachments'**
  String get settings_main_attachments_title;

  /// No description provided for @settings_main_attachments_desc.
  ///
  /// In en, this message translates to:
  /// **'View and delete audio attachments'**
  String get settings_main_attachments_desc;

  /// No description provided for @settings_main_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get settings_main_sync_title;

  /// No description provided for @settings_main_sync_desc.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sync, backups, and security'**
  String get settings_main_sync_desc;

  /// No description provided for @settings_main_vaults_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Vaults'**
  String get settings_main_vaults_title;

  /// No description provided for @settings_main_vaults_desc.
  ///
  /// In en, this message translates to:
  /// **'Switch vaults, check stats, or change Hub location'**
  String get settings_main_vaults_desc;

  /// No description provided for @settings_main_pro_status_active.
  ///
  /// In en, this message translates to:
  /// **'Prism Pro Active'**
  String get settings_main_pro_status_active;

  /// No description provided for @settings_main_section_feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Support'**
  String get settings_main_section_feedback;

  /// No description provided for @settings_main_support_title.
  ///
  /// In en, this message translates to:
  /// **'Contact Support & Feedback'**
  String get settings_main_support_title;

  /// No description provided for @settings_main_support_desc.
  ///
  /// In en, this message translates to:
  /// **'Report bugs, suggest features, or get help'**
  String get settings_main_support_desc;

  /// No description provided for @settings_export_bottom_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Export Vault'**
  String get settings_export_bottom_sheet_title;

  /// No description provided for @settings_widgets_theme_system.
  ///
  /// In en, this message translates to:
  /// **'System Sync'**
  String get settings_widgets_theme_system;

  /// No description provided for @settings_widgets_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Clean Paper'**
  String get settings_widgets_theme_light;

  /// No description provided for @settings_widgets_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dusk Dark'**
  String get settings_widgets_theme_dark;

  /// No description provided for @settings_widgets_theme_explore_teaser.
  ///
  /// In en, this message translates to:
  /// **'Explore Editorial Themes'**
  String get settings_widgets_theme_explore_teaser;

  /// No description provided for @settings_widgets_theme_teaser_list.
  ///
  /// In en, this message translates to:
  /// **'Sepia, Forest, Noir, Slate, and 4 more...'**
  String get settings_widgets_theme_teaser_list;

  /// No description provided for @settings_widgets_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'{title} is coming soon!'**
  String settings_widgets_coming_soon(String title);

  /// No description provided for @settings_widgets_haptic_feedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get settings_widgets_haptic_feedback;

  /// No description provided for @settings_widgets_haptic_feedback_desc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on satisfying button presses and interactions'**
  String get settings_widgets_haptic_feedback_desc;

  /// No description provided for @settings_widgets_pin_nodes.
  ///
  /// In en, this message translates to:
  /// **'Pin Graph Nodes on Drag'**
  String get settings_widgets_pin_nodes;

  /// No description provided for @settings_widgets_pin_nodes_desc.
  ///
  /// In en, this message translates to:
  /// **'Pin year/week calendar nodes when dragging them'**
  String get settings_widgets_pin_nodes_desc;

  /// No description provided for @settings_widgets_analytics.
  ///
  /// In en, this message translates to:
  /// **'Share Anonymous Diagnostics'**
  String get settings_widgets_analytics;

  /// No description provided for @settings_widgets_analytics_desc.
  ///
  /// In en, this message translates to:
  /// **'Help us improve Prism by sending anonymous performance reports and crash logs.'**
  String get settings_widgets_analytics_desc;

  /// No description provided for @settings_support_title.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settings_support_title;

  /// No description provided for @settings_support_how_can_we_help.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get settings_support_how_can_we_help;

  /// No description provided for @settings_support_subtitle_desc.
  ///
  /// In en, this message translates to:
  /// **'Submit bug reports, request feature enhancements, or send general feedback directly to the Prism team.'**
  String get settings_support_subtitle_desc;

  /// No description provided for @settings_support_category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get settings_support_category_label;

  /// No description provided for @settings_support_category_bug.
  ///
  /// In en, this message translates to:
  /// **'🐛  Report a Bug'**
  String get settings_support_category_bug;

  /// No description provided for @settings_support_category_feature.
  ///
  /// In en, this message translates to:
  /// **'✨  Feature Request'**
  String get settings_support_category_feature;

  /// No description provided for @settings_support_category_feedback.
  ///
  /// In en, this message translates to:
  /// **'💬  General Feedback'**
  String get settings_support_category_feedback;

  /// No description provided for @settings_support_category_question.
  ///
  /// In en, this message translates to:
  /// **'❓  Question'**
  String get settings_support_category_question;

  /// No description provided for @settings_support_subject_label.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get settings_support_subject_label;

  /// No description provided for @settings_support_subject_hint.
  ///
  /// In en, this message translates to:
  /// **'Summary of the issue...'**
  String get settings_support_subject_hint;

  /// No description provided for @settings_support_subject_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject.'**
  String get settings_support_subject_required;

  /// No description provided for @settings_support_desc_label.
  ///
  /// In en, this message translates to:
  /// **'Message Details'**
  String get settings_support_desc_label;

  /// No description provided for @settings_support_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or feedback in detail...'**
  String get settings_support_desc_hint;

  /// No description provided for @settings_support_desc_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter details for your request.'**
  String get settings_support_desc_required;

  /// No description provided for @settings_support_attach_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Attach System Diagnostics'**
  String get settings_support_attach_diagnostics;

  /// No description provided for @settings_support_attach_diagnostics_desc.
  ///
  /// In en, this message translates to:
  /// **'Include anonymous device logs and vault stats.'**
  String get settings_support_attach_diagnostics_desc;

  /// No description provided for @settings_support_preview_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics Preview'**
  String get settings_support_preview_diagnostics;

  /// No description provided for @settings_support_send_button.
  ///
  /// In en, this message translates to:
  /// **'Send Support Request'**
  String get settings_support_send_button;

  /// No description provided for @settings_support_fallback_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'No Email App Found'**
  String get settings_support_fallback_dialog_title;

  /// No description provided for @settings_support_fallback_dialog_desc.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'\'t automatically launch your email application. You can send your support request manually to our address below:'**
  String get settings_support_fallback_dialog_desc;

  /// No description provided for @settings_support_fallback_dialog_copy_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap below to copy the diagnostic log and message details to your clipboard, then email them to us.'**
  String get settings_support_fallback_dialog_copy_desc;

  /// No description provided for @settings_support_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_support_cancel_button;

  /// No description provided for @settings_support_copy_success.
  ///
  /// In en, this message translates to:
  /// **'Support log copied to clipboard!'**
  String get settings_support_copy_success;

  /// No description provided for @settings_support_copy_button.
  ///
  /// In en, this message translates to:
  /// **'Copy Diagnostics & Email'**
  String get settings_support_copy_button;

  /// No description provided for @paywall_title_pro_active.
  ///
  /// In en, this message translates to:
  /// **'You are a Pro member!'**
  String get paywall_title_pro_active;

  /// No description provided for @paywall_title_pro_inactive.
  ///
  /// In en, this message translates to:
  /// **'Elevate Your Notebook'**
  String get paywall_title_pro_inactive;

  /// No description provided for @paywall_desc_pro_active.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Prism. All premium features are unlocked.'**
  String get paywall_desc_pro_active;

  /// No description provided for @paywall_desc_pro_inactive.
  ///
  /// In en, this message translates to:
  /// **'Unlock cross-device sync, custom formats, and premium styling.'**
  String get paywall_desc_pro_inactive;

  /// No description provided for @paywall_empty_packages.
  ///
  /// In en, this message translates to:
  /// **'No subscription options available currently.'**
  String get paywall_empty_packages;

  /// No description provided for @paywall_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Error loading products: {error}'**
  String paywall_error_loading(String error);

  /// No description provided for @paywall_upgrade_button.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get paywall_upgrade_button;

  /// No description provided for @paywall_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Prism Pro renews automatically ({price}/{period}) until cancelled. Payment is charged to your account at confirmation. Cancel anytime in your account settings at least 24 hours before renewal to prevent charges.'**
  String paywall_disclaimer(String price, String period);

  /// No description provided for @paywall_restore_button.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywall_restore_button;

  /// No description provided for @paywall_feature_sync.
  ///
  /// In en, this message translates to:
  /// **'E2E Google Drive Sync'**
  String get paywall_feature_sync;

  /// No description provided for @paywall_feature_templates_macros.
  ///
  /// In en, this message translates to:
  /// **'Custom Templates & Macros'**
  String get paywall_feature_templates_macros;

  /// No description provided for @paywall_feature_audio_bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Timeline Audio Bookmarks'**
  String get paywall_feature_audio_bookmarks;

  /// No description provided for @paywall_feature_themes_fonts.
  ///
  /// In en, this message translates to:
  /// **'Premium Themes & Fonts'**
  String get paywall_feature_themes_fonts;

  /// No description provided for @paywall_feature_export.
  ///
  /// In en, this message translates to:
  /// **'Vault Export (ZIP/PDF/JSON)'**
  String get paywall_feature_export;

  /// No description provided for @paywall_feature_unlimited_vaults.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Vaults (Local)'**
  String get paywall_feature_unlimited_vaults;

  /// No description provided for @paywall_feature_local_ai.
  ///
  /// In en, this message translates to:
  /// **'Local & BYOD AI'**
  String get paywall_feature_local_ai;

  /// No description provided for @paywall_header_features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get paywall_header_features;

  /// No description provided for @paywall_header_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywall_header_free;

  /// No description provided for @paywall_header_pro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get paywall_header_pro;

  /// No description provided for @paywall_not_available_semantic.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get paywall_not_available_semantic;

  /// No description provided for @paywall_save_percentage_yearly.
  ///
  /// In en, this message translates to:
  /// **'SAVE 25%'**
  String get paywall_save_percentage_yearly;

  /// No description provided for @paywall_yearly_access.
  ///
  /// In en, this message translates to:
  /// **'Yearly Access'**
  String get paywall_yearly_access;

  /// No description provided for @paywall_monthly_access.
  ///
  /// In en, this message translates to:
  /// **'Monthly Access'**
  String get paywall_monthly_access;

  /// No description provided for @paywall_yearly_suffix.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get paywall_yearly_suffix;

  /// No description provided for @paywall_monthly_suffix.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get paywall_monthly_suffix;

  /// No description provided for @paywall_purchase_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get paywall_purchase_cancelled;

  /// No description provided for @paywall_purchase_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Purchase Failed'**
  String get paywall_purchase_failed_title;

  /// No description provided for @paywall_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get paywall_ok;

  /// No description provided for @paywall_purchase_success.
  ///
  /// In en, this message translates to:
  /// **'Prism Pro unlocked successfully!'**
  String get paywall_purchase_success;

  /// No description provided for @paywall_restore_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Restore Failed'**
  String get paywall_restore_failed_title;

  /// No description provided for @paywall_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored. Prism Pro active!'**
  String get paywall_restore_success;

  /// No description provided for @paywall_restore_empty.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found to restore.'**
  String get paywall_restore_empty;

  /// No description provided for @settings_terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settings_terms_of_service;

  /// No description provided for @settings_terms_of_service_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Liability limits & arbitration agreement'**
  String get settings_terms_of_service_subtitle;

  /// No description provided for @onboarding_legal_assent_pre.
  ///
  /// In en, this message translates to:
  /// **'By tapping Confirm & Begin, you agree to Prism\'\'s '**
  String get onboarding_legal_assent_pre;

  /// No description provided for @onboarding_legal_terms_link.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboarding_legal_terms_link;

  /// No description provided for @onboarding_legal_and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get onboarding_legal_and;

  /// No description provided for @onboarding_legal_privacy_link.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboarding_legal_privacy_link;

  /// No description provided for @paywall_terms_link.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get paywall_terms_link;

  /// No description provided for @paywall_privacy_link.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywall_privacy_link;

  /// No description provided for @paywall_manage_subscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get paywall_manage_subscription;

  /// No description provided for @editor_audio_wiretap_notice_title.
  ///
  /// In en, this message translates to:
  /// **'Audio Recording & Privacy Notice'**
  String get editor_audio_wiretap_notice_title;

  /// No description provided for @editor_audio_wiretap_notice_body.
  ///
  /// In en, this message translates to:
  /// **'Prism stores voice dictations locally on your device. In many jurisdictions (including California, Florida, Massachusetts, and others), it is unlawful to record a conversation without the explicit consent of all participants. You are solely responsible for obtaining all legally required consents before recording.'**
  String get editor_audio_wiretap_notice_body;

  /// No description provided for @editor_audio_wiretap_notice_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editor_audio_wiretap_notice_cancel;

  /// No description provided for @editor_audio_wiretap_notice_agree.
  ///
  /// In en, this message translates to:
  /// **'I Understand & Agree'**
  String get editor_audio_wiretap_notice_agree;

  /// No description provided for @settings_main_section_danger.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settings_main_section_danger;

  /// No description provided for @settings_data_deletion_title.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data & Reset'**
  String get settings_data_deletion_title;

  /// No description provided for @settings_data_deletion_desc.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase local vaults, credentials, and settings'**
  String get settings_data_deletion_desc;

  /// No description provided for @settings_data_deletion_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data & Reset?'**
  String get settings_data_deletion_dialog_title;

  /// No description provided for @settings_data_deletion_dialog_body.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All local markdown notes, encrypted database indexes, audio attachments, app preferences, and cloud sync credentials will be completely erased from this device.\n\nType DELETE below to confirm.'**
  String get settings_data_deletion_dialog_body;

  /// No description provided for @settings_data_deletion_confirm_keyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get settings_data_deletion_confirm_keyword;

  /// No description provided for @settings_data_deletion_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settings_data_deletion_cancel_button;

  /// No description provided for @settings_data_deletion_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get settings_data_deletion_confirm_button;

  /// No description provided for @settings_data_deletion_progress.
  ///
  /// In en, this message translates to:
  /// **'Erasing all data and resetting...'**
  String get settings_data_deletion_progress;

  /// No description provided for @settings_data_deletion_success.
  ///
  /// In en, this message translates to:
  /// **'All data erased. App reset to initial state.'**
  String get settings_data_deletion_success;

  /// No description provided for @settings_data_deletion_failure.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete reset: {error}'**
  String settings_data_deletion_failure(String error);

  /// No description provided for @settings_section_vaults_storage.
  ///
  /// In en, this message translates to:
  /// **'Vaults & Storage'**
  String get settings_section_vaults_storage;

  /// No description provided for @settings_section_security_sync.
  ///
  /// In en, this message translates to:
  /// **'Security & Sync'**
  String get settings_section_security_sync;

  /// No description provided for @settings_section_writing_appearance.
  ///
  /// In en, this message translates to:
  /// **'Writing & Appearance'**
  String get settings_section_writing_appearance;

  /// No description provided for @settings_section_about_support.
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get settings_section_about_support;

  /// No description provided for @settings_security_title.
  ///
  /// In en, this message translates to:
  /// **'Security Trust Center'**
  String get settings_security_title;

  /// No description provided for @settings_security_desc.
  ///
  /// In en, this message translates to:
  /// **'Zero-knowledge cryptography, on-device encryption, and privacy controls'**
  String get settings_security_desc;

  /// No description provided for @settings_security_trust_center_desc.
  ///
  /// In en, this message translates to:
  /// **'Master passphrase, database lock & shredder'**
  String get settings_security_trust_center_desc;

  /// No description provided for @settings_security_local_encryption.
  ///
  /// In en, this message translates to:
  /// **'On-Device Storage Lock'**
  String get settings_security_local_encryption;

  /// No description provided for @settings_security_local_database_title.
  ///
  /// In en, this message translates to:
  /// **'On-Device Storage Lock (AES-256)'**
  String get settings_security_local_database_title;

  /// No description provided for @settings_security_local_status_active.
  ///
  /// In en, this message translates to:
  /// **'AES-256-CBC Active'**
  String get settings_security_local_status_active;

  /// No description provided for @settings_security_local_status_desc.
  ///
  /// In en, this message translates to:
  /// **'Local SQLite metadata database (.prism.db) is encrypted at rest using AES-256.'**
  String get settings_security_local_status_desc;

  /// No description provided for @settings_security_master_passphrase.
  ///
  /// In en, this message translates to:
  /// **'Master Encryption Passphrase'**
  String get settings_security_master_passphrase;

  /// No description provided for @settings_security_passphrase_configured.
  ///
  /// In en, this message translates to:
  /// **'Passphrase Configured'**
  String get settings_security_passphrase_configured;

  /// No description provided for @settings_security_passphrase_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get settings_security_passphrase_not_configured;

  /// No description provided for @settings_security_passphrase_set.
  ///
  /// In en, this message translates to:
  /// **'Set Master Passphrase'**
  String get settings_security_passphrase_set;

  /// No description provided for @settings_security_passphrase_change.
  ///
  /// In en, this message translates to:
  /// **'Change Master Passphrase'**
  String get settings_security_passphrase_change;

  /// No description provided for @settings_security_passphrase_verify.
  ///
  /// In en, this message translates to:
  /// **'Test Passphrase Integrity'**
  String get settings_security_passphrase_verify;

  /// No description provided for @settings_security_passphrase_verify_desc.
  ///
  /// In en, this message translates to:
  /// **'Verify your passphrase against stored secure keys'**
  String get settings_security_passphrase_verify_desc;

  /// No description provided for @settings_security_passphrase_verify_success.
  ///
  /// In en, this message translates to:
  /// **'Passphrase verified! Cryptographic key root is valid.'**
  String get settings_security_passphrase_verify_success;

  /// No description provided for @settings_security_passphrase_verify_failure.
  ///
  /// In en, this message translates to:
  /// **'Passphrase incorrect. Cryptographic key root does not match.'**
  String get settings_security_passphrase_verify_failure;

  /// No description provided for @settings_security_passphrase_set_success.
  ///
  /// In en, this message translates to:
  /// **'Master encryption passphrase configured successfully.'**
  String get settings_security_passphrase_set_success;

  /// No description provided for @settings_security_passphrase_change_success.
  ///
  /// In en, this message translates to:
  /// **'Master encryption passphrase updated successfully.'**
  String get settings_security_passphrase_change_success;

  /// No description provided for @settings_security_passphrase_current_label.
  ///
  /// In en, this message translates to:
  /// **'Current Passphrase'**
  String get settings_security_passphrase_current_label;

  /// No description provided for @settings_security_passphrase_new_label.
  ///
  /// In en, this message translates to:
  /// **'New Passphrase'**
  String get settings_security_passphrase_new_label;

  /// No description provided for @settings_security_passphrase_confirm_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Passphrase'**
  String get settings_security_passphrase_confirm_label;

  /// No description provided for @settings_security_passphrase_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passphrases do not match.'**
  String get settings_security_passphrase_mismatch;

  /// No description provided for @settings_security_pbkdf2_title.
  ///
  /// In en, this message translates to:
  /// **'PBKDF2 Key Derivation'**
  String get settings_security_pbkdf2_title;

  /// No description provided for @settings_security_pbkdf2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'HMAC-SHA256 • 100,000 iterations • 256-bit key'**
  String get settings_security_pbkdf2_subtitle;

  /// No description provided for @settings_security_pbkdf2_desc.
  ///
  /// In en, this message translates to:
  /// **'Prism operates strictly zero-knowledge. Your passphrase derives the AES-256 encryption key using 100,000 PBKDF2 iterations with a secure random salt, and never leaves this device unhashed.'**
  String get settings_security_pbkdf2_desc;

  /// No description provided for @settings_security_cloud_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Cloud Sync'**
  String get settings_security_cloud_sync_title;

  /// No description provided for @settings_security_cloud_sync_desc.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted backup and multi-device sync'**
  String get settings_security_cloud_sync_desc;

  /// No description provided for @settings_security_telemetry_header.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Diagnostics'**
  String get settings_security_telemetry_header;

  /// No description provided for @settings_cloud_sync_manage_security_button.
  ///
  /// In en, this message translates to:
  /// **'Manage in Security Trust Center'**
  String get settings_cloud_sync_manage_security_button;

  /// No description provided for @settings_security_change_passphrase_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Change Master Passphrase'**
  String get settings_security_change_passphrase_dialog_title;

  /// No description provided for @settings_security_set_passphrase_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Set Master Passphrase'**
  String get settings_security_set_passphrase_dialog_title;

  /// No description provided for @settings_security_verify_passphrase_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Verify Passphrase'**
  String get settings_security_verify_passphrase_dialog_title;

  /// No description provided for @settings_security_verify_button.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get settings_security_verify_button;

  /// No description provided for @settings_security_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save Passphrase'**
  String get settings_security_save_button;

  /// No description provided for @quick_capture_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Capture'**
  String get quick_capture_title;

  /// No description provided for @quick_capture_record_voice_memo.
  ///
  /// In en, this message translates to:
  /// **'Record Voice Memo'**
  String get quick_capture_record_voice_memo;

  /// No description provided for @quick_capture_blank_document.
  ///
  /// In en, this message translates to:
  /// **'Blank Document'**
  String get quick_capture_blank_document;

  /// No description provided for @quick_capture_recording_status.
  ///
  /// In en, this message translates to:
  /// **'Recording Voice Memo...'**
  String get quick_capture_recording_status;

  /// No description provided for @quick_capture_saved_toast.
  ///
  /// In en, this message translates to:
  /// **'Voice memo saved to inbox'**
  String get quick_capture_saved_toast;

  /// No description provided for @audio_evidence_docked_title.
  ///
  /// In en, this message translates to:
  /// **'Docked Audio'**
  String get audio_evidence_docked_title;

  /// No description provided for @audio_evidence_add_bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get audio_evidence_add_bookmark;

  /// No description provided for @audio_evidence_undock_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Undock audio'**
  String get audio_evidence_undock_tooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
