// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Prism';

  @override
  String get shared_app_shell_tab_notes => 'Notes';

  @override
  String get shared_app_shell_tab_journal => 'Journal';

  @override
  String get shared_app_shell_tab_graph => 'Graph';

  @override
  String get shared_app_shell_tab_settings => 'Settings';

  @override
  String get shared_app_shell_tutorial_journal_nav_title =>
      'Calendar Navigation';

  @override
  String get shared_app_shell_tutorial_journal_nav_desc =>
      'Tap the calendar icon to expand the monthly calendar view and navigate across all dates in your vault history.';

  @override
  String get shared_app_shell_tutorial_journal_strip_title =>
      'Weekly Quick Strip';

  @override
  String get shared_app_shell_tutorial_journal_strip_desc =>
      'Quickly slide or tap between the last 7 days to keep your reflection streak alive without opening the full calendar view.';

  @override
  String get shared_app_shell_tutorial_journal_streak_title =>
      'Daily Streak & Grid';

  @override
  String get shared_app_shell_tutorial_journal_streak_desc =>
      'Track your active daily writing streak and visualize your consistency over the last 28 days with the contribution grid.';

  @override
  String get shared_app_shell_tutorial_journal_template_title =>
      'Reflection Templates';

  @override
  String get shared_app_shell_tutorial_journal_template_desc =>
      'Select an expert journal template (Gratitude, Daily Plan, Reflection, Goals) to quickly structure your writing, or start typing in a blank daily page.';

  @override
  String get shared_app_shell_tutorial_notes_nav_title =>
      'Virtual Folders & Tags';

  @override
  String get shared_app_shell_tutorial_notes_nav_desc =>
      'Open the sidebar navigation drawer to organize your notes into virtual folders or browse tag indexes across your vault.';

  @override
  String get shared_app_shell_tutorial_notes_folders_title => 'Virtual Folders';

  @override
  String get shared_app_shell_tutorial_notes_folders_desc =>
      'Tap any virtual folder card in the horizontal row to filter the notes list below. Tap the \"All Notes\" card to reset the filter.';

  @override
  String get shared_app_shell_tutorial_notes_daily_title =>
      'Daily Reflection Logs';

  @override
  String get shared_app_shell_tutorial_notes_daily_desc =>
      'Access today\'s dedicated calendar note immediately. Jot down reflections with templates (Gratitude, Reflection, Goals), hit word count targets, and grow your daily writing streak.';

  @override
  String get shared_app_shell_tutorial_notes_graph_title =>
      'Mindmap Thought Graph';

  @override
  String get shared_app_shell_tutorial_notes_graph_desc =>
      'Explore your connected mind network. Watch notes become nodes and wikilinks become edges in a dynamic 2D graph layout.';

  @override
  String get shared_app_shell_tutorial_notes_create_title =>
      'Create & Link Notes';

  @override
  String get shared_app_shell_tutorial_notes_create_desc =>
      'Tap the floating \"+\" button to create a new note. Within any note, simply type double brackets [[like this]] to link ideas together and expand your brain.';

  @override
  String get shared_storage_permission_title => 'Storage Access Required';

  @override
  String get shared_storage_permission_desc =>
      'Prism is private and offline-first. Your notes are stored directly inside your custom folder on this device.\n\nTo read and write note files in your documents vault, Android requires the \"All Files Access\" permission.';

  @override
  String get shared_storage_permission_grant_button => 'Grant Storage Access';

  @override
  String get shared_storage_permission_secondary_desc =>
      'Tap above, then enable the toggle for Prism in the Android settings screen. Once enabled, press back to return here.';

  @override
  String get shared_storage_permission_loading_label => 'Loading';

  @override
  String get shared_tutorial_overlay_label => 'Tutorial overlay';

  @override
  String shared_tutorial_overlay_step_counter(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get shared_tutorial_overlay_skip_tour => 'Skip Tour';

  @override
  String get shared_tutorial_overlay_back_button => 'Back';

  @override
  String get shared_tutorial_overlay_got_it_button => 'Got it!';

  @override
  String get shared_tutorial_overlay_next_button => 'Next';

  @override
  String get editor_screen_editor_mode => 'EDITOR MODE';

  @override
  String get editor_screen_live_preview => 'Live Preview';

  @override
  String get editor_screen_source_mode => 'Source Mode';

  @override
  String get editor_screen_reading_view => 'Reading View';

  @override
  String get editor_screen_backlinks => 'Backlinks';

  @override
  String get editor_screen_show_backlinks_semantics => 'Show backlinks';

  @override
  String get editor_screen_organize_folders_tooltip => 'Organize into folders';

  @override
  String get editor_screen_settings_tooltip => 'Editor Settings';

  @override
  String editor_screen_failed_image_attach(String error) {
    return 'Failed to attach image: $error';
  }

  @override
  String get editor_merge_comparison_note_not_found =>
      'Conflict note not found.';

  @override
  String get editor_merge_comparison_not_conflicted =>
      'This note is not marked as conflicted.';

  @override
  String get editor_merge_comparison_original_deleted =>
      'Original note was deleted or not found.';

  @override
  String editor_merge_comparison_failed_load(Object error) {
    return 'Failed to load note contents: $error';
  }

  @override
  String get editor_merge_comparison_discarded_success =>
      'Conflicted copy discarded. Keeping original note.';

  @override
  String editor_merge_comparison_discard_error(Object error) {
    return 'Error discarding conflicted copy: $error';
  }

  @override
  String get editor_merge_comparison_replaced_success =>
      'Original note replaced with conflicted copy contents.';

  @override
  String editor_merge_comparison_replace_error(Object error) {
    return 'Error resolving conflict: $error';
  }

  @override
  String get editor_merge_comparison_merged_markers =>
      'Notes merged with Git conflict markers. Please resolve manually.';

  @override
  String editor_merge_comparison_merge_error(Object error) {
    return 'Error merging notes: $error';
  }

  @override
  String get editor_merge_comparison_compare_resolve => 'Compare & Resolve';

  @override
  String get editor_merge_comparison_tab_original => 'Original Note';

  @override
  String get editor_merge_comparison_tab_conflict => 'Conflicted Copy';

  @override
  String get editor_merge_comparison_empty_note => 'Note is empty.';

  @override
  String get editor_merge_comparison_how_to_resolve =>
      'How would you like to resolve this conflict?';

  @override
  String get editor_merge_comparison_keep_original => 'Keep Original';

  @override
  String get editor_merge_comparison_keep_conflicted => 'Keep Conflicted';

  @override
  String get editor_merge_comparison_merge_both => 'Merge Both Copies';

  @override
  String get editor_merge_comparison_resolution_error => 'Resolution Error';

  @override
  String get editor_merge_comparison_back_to_notes => 'Back to Notes';

  @override
  String get editor_audio_player_sheet_voice_recording => 'Voice Recording';

  @override
  String editor_backlinks_panel_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count backlinks',
      one: '1 backlink',
    );
    return '$_temp0';
  }

  @override
  String get editor_conflict_banner_message =>
      'Conflicted Copy: Review and resolve changes.';

  @override
  String get editor_write_mode_title_hint => 'Note Title';

  @override
  String get editor_write_mode_content_hint =>
      'Start writing… use [[note]] for links, #tag for tags';

  @override
  String get editor_formatting_toolbar_tooltip_bullet_list => 'Bullet List';

  @override
  String get editor_formatting_toolbar_tooltip_heading => 'Heading (H1–H4)';

  @override
  String get editor_formatting_toolbar_tooltip_attach_image => 'Attach Image';

  @override
  String get editor_formatting_toolbar_tooltip_dictate =>
      'Dictate (Voice-to-Text)';

  @override
  String editor_formatting_toolbar_recording_status(Object time) {
    return 'Recording $time...';
  }

  @override
  String get editor_formatting_toolbar_cancel_discard_semantics =>
      'Cancel & Discard recording';

  @override
  String get editor_formatting_toolbar_cancel_discard_tooltip =>
      'Cancel & Discard';

  @override
  String get editor_formatting_toolbar_save_insert_semantics =>
      'Save & Insert recording';

  @override
  String editor_inline_audio_file_not_found(Object fileName) {
    return 'Audio file not found: $fileName';
  }

  @override
  String get editor_inline_audio_add_bookmark_title => 'Add Bookmark';

  @override
  String editor_inline_audio_bookmark_at_time(Object time) {
    return 'At $time';
  }

  @override
  String get editor_inline_audio_annotation_hint => 'Annotation (optional)';

  @override
  String get editor_inline_audio_add_bookmark_tooltip =>
      'Add bookmark at current position';

  @override
  String editor_inline_audio_database_error(Object error) {
    return 'Database Error: $error';
  }

  @override
  String get editor_wikilink_autocomplete_link_to_note => 'Link to note';

  @override
  String get editor_wikilink_autocomplete_ghost_note => 'Ghost note';

  @override
  String editor_wikilink_autocomplete_words(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get editor_wikilink_autocomplete_create_note => 'Create new note';

  @override
  String get folders_add_folder_add_icon => 'Add icon';

  @override
  String get folders_add_folder_change_icon => 'Change icon';

  @override
  String get folders_add_folder_remove_icon => '✕ Remove';

  @override
  String get folders_add_folder_hint => 'Folder name';

  @override
  String get folders_edit_folder_title => 'Edit Folder';

  @override
  String folders_edit_folder_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get folders_edit_folder_not_found => 'Folder not found';

  @override
  String get folders_edit_folder_save => 'Save Changes';

  @override
  String get folders_assign_dialog_title => 'Organize Note';

  @override
  String folders_assign_dialog_error_folders(Object error) {
    return 'Error loading folders: $error';
  }

  @override
  String folders_assign_dialog_error_assignments(Object error) {
    return 'Error loading assignments: $error';
  }

  @override
  String get folders_assign_dialog_empty =>
      'No virtual folders created yet. Add them from the sidebar drawer first!';

  @override
  String get folders_drawer_no_notes => 'No notes found in this vault';

  @override
  String folders_drawer_random_note_error(Object error) {
    return 'Error finding random note: $error';
  }

  @override
  String get folders_drawer_manage_templates => 'Manage Templates';

  @override
  String get folders_drawer_manage_macros => 'Manage Macros';

  @override
  String folders_drawer_folder_menu_title(Object folderName) {
    return 'Folder: $folderName';
  }

  @override
  String get folders_drawer_edit_details => 'Edit details';

  @override
  String folders_drawer_delete_warning(Object folderName) {
    return 'This will delete the \"$folderName\" category organization. None of the physical markdown files will be deleted.';
  }

  @override
  String get folders_icon_picker_title => 'Choose Icon';

  @override
  String get folders_color_picker_hex_code => 'HEX CODE';

  @override
  String folders_color_picker_hue(Object value) {
    return 'HUE ($value°)';
  }

  @override
  String folders_color_picker_saturation(Object value) {
    return 'SATURATION ($value%)';
  }

  @override
  String folders_color_picker_brightness(Object value) {
    return 'BRIGHTNESS ($value%)';
  }

  @override
  String get folders_tag_cloud_title => 'TAG INDEX';

  @override
  String folders_tag_cloud_error(Object error) {
    return 'Error index: $error';
  }

  @override
  String get folders_tag_cloud_empty =>
      'No tags parsed yet. Add #tags to your notes to auto-index them.';

  @override
  String get folders_stats_board_title => 'VAULT STATISTICS';

  @override
  String folders_stats_board_error(Object error) {
    return 'Error loading stats: $error';
  }

  @override
  String get folders_stats_board_notes_created => 'Notes Created';

  @override
  String get folders_stats_board_words_written => 'Words Written';

  @override
  String get folders_stats_board_backlinks_formed => 'Backlinks Formed';

  @override
  String get folders_status_panel_loading_path => 'Loading path...';

  @override
  String get folders_status_panel_ready => 'Local Safe / Private Sync Ready';

  @override
  String graph_screen_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get graph_empty_state_title => 'No connections yet';

  @override
  String get graph_empty_state_description =>
      'Start linking notes with [[wikilinks]] and your graph will grow here';

  @override
  String get graph_header_title => 'Graph View';

  @override
  String get graph_header_subtitle => 'Your connected ideas';

  @override
  String get graph_header_reset_tooltip => 'Reset view';

  @override
  String get graph_header_replay_tooltip => 'Replay animation';

  @override
  String get graph_header_settings_tooltip => 'Graph settings';

  @override
  String get graph_settings_panel_title => 'Graph Settings';

  @override
  String get graph_settings_panel_repulsion_force => 'Repulsion Force';

  @override
  String get graph_settings_panel_link_spring_distance =>
      'Link Spring Distance';

  @override
  String get graph_settings_panel_spring_stiffness => 'Spring Stiffness';

  @override
  String get graph_settings_panel_simulation_damping => 'Simulation Damping';

  @override
  String get graph_settings_panel_drag_to_pin => 'Drag to Pin';

  @override
  String get graph_settings_panel_color_by => 'Color by';

  @override
  String get graph_settings_panel_tag_colors => 'Tag Colors';

  @override
  String get graph_settings_panel_no_tags => 'No tags found';

  @override
  String get graph_settings_panel_reset_defaults => 'Reset Defaults';

  @override
  String get graph_settings_panel_reset_hsl => 'Reset (HSL Hash)';

  @override
  String journal_screen_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get journal_screen_start_with_template => 'START WITH A TEMPLATE';

  @override
  String get journal_screen_default_template_title => 'Daily Reflection';

  @override
  String get journal_empty_state_future_day_title => 'A future day';

  @override
  String get journal_empty_state_no_entry_title => 'No entry yet';

  @override
  String get journal_empty_state_future_day_desc =>
      'Come back on this day to start writing';

  @override
  String get journal_empty_state_no_entry_desc =>
      'Tap below to start your entry for today';

  @override
  String get journal_empty_state_start_writing_button => 'Start Writing';

  @override
  String get journal_entry_card_default_title => 'Daily Reflection';

  @override
  String journal_entry_card_subtitle(num count, Object subtitle) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$subtitle • $_temp0';
  }

  @override
  String get journal_entry_card_empty_content =>
      'No text written yet. Tap to start writing…';

  @override
  String get journal_entry_card_continue_writing_button => 'Continue writing';

  @override
  String get journal_entry_card_checklist_header => 'DAILY MINDFUL CHECKLIST';

  @override
  String get journal_header_title_today => 'Today';

  @override
  String journal_header_entries_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get journal_streak_grid_title => 'Day Active Streak';

  @override
  String get journal_streak_grid_consistency_grid => 'Consistency Grid';

  @override
  String get journal_templates_row_gratitude => 'Gratitude';

  @override
  String get journal_templates_row_daily_plan => 'Daily Plan';

  @override
  String get journal_templates_row_reflection => 'Reflection';

  @override
  String get journal_templates_row_goals => 'Goals';

  @override
  String notes_list_screen_error(Object error) {
    return 'Error: $error';
  }

  @override
  String get notes_list_screen_new_folder_tooltip => 'New Folder';

  @override
  String get notes_list_screen_search_results_title => 'SEARCH RESULTS';

  @override
  String get notes_list_screen_recent_notes_title => 'RECENT NOTES';

  @override
  String get notes_list_screen_all_notes_tooltip => 'All Notes';

  @override
  String get notes_list_screen_all_notes_title => 'All Notes';

  @override
  String get notes_list_screen_journal_logs_title => 'Journal Logs';

  @override
  String get notes_list_screen_no_notes_found_search => 'No notes found';

  @override
  String get notes_list_screen_workspace_awaits_title =>
      'Your workspace awaits';

  @override
  String get notes_list_screen_search_help_desc =>
      'Try a different search term';

  @override
  String get notes_list_screen_create_help_desc =>
      'Tap + to create your first note';

  @override
  String get notes_list_screen_delete_warning =>
      'This will permanently delete the note and its file.';

  @override
  String notes_list_screen_folders_count(num total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total folders',
      one: '1 folder',
    );
    return 'Folders • $_temp0';
  }

  @override
  String notes_list_screen_all_notes_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'All Notes • $_temp0';
  }

  @override
  String notes_list_screen_journal_logs_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Journal Logs • $_temp0';
  }

  @override
  String notes_list_screen_uncategorized_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Uncategorized • $_temp0';
  }

  @override
  String notes_list_screen_custom_folder_count(num count, Object name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$name • $_temp0';
  }

  @override
  String get notes_grouped_empty_state_title => 'Organize your thoughts';

  @override
  String get notes_search_bar_open_drawer_tooltip => 'Open drawer';

  @override
  String get notes_search_bar_hint => 'Search notes...';

  @override
  String get notes_sort_bottom_sheet_title => 'Sort Order';

  @override
  String get notes_sort_bottom_sheet_last_updated_title =>
      'Last Updated (Recent)';

  @override
  String get notes_sort_bottom_sheet_last_updated_desc =>
      'Recently edited notes and folders float to the top';

  @override
  String get notes_sort_bottom_sheet_date_created_title => 'Date Created';

  @override
  String get notes_sort_bottom_sheet_date_created_desc =>
      'Newest folders and notes listed first';

  @override
  String get notes_sort_bottom_sheet_alphabetical_title => 'Alphabetical (A–Z)';

  @override
  String get notes_sort_bottom_sheet_alphabetical_desc =>
      'Sort notes and folders by name alphabetically';

  @override
  String notes_tag_filter_banner_filtered_by(Object tag) {
    return 'Filtered by tag: #$tag';
  }

  @override
  String notes_vault_selector_switch_error(Object error) {
    return 'Error switching vault: $error';
  }

  @override
  String notes_vault_selector_create_error(Object error) {
    return 'Error creating vault: $error';
  }

  @override
  String get notes_vault_selector_title => 'Switch Vault';

  @override
  String get notes_vault_selector_empty => 'No vaults found';

  @override
  String notes_vault_selector_error_loading(Object error) {
    return 'Error loading vaults: $error';
  }

  @override
  String get notes_vault_selector_hint => 'Vault Name';

  @override
  String get notes_vault_selector_validation_error =>
      'Vault name can only contain letters, numbers, spaces, underscores, and hyphens.';

  @override
  String get notes_vault_selector_title_default => 'My Vault';

  @override
  String get onboarding_screen_slide1_title => 'Absolute Privacy';

  @override
  String get onboarding_screen_slide1_subtitle => 'Privacy-First Notebook';

  @override
  String get onboarding_screen_slide1_desc =>
      'Your notes live completely private on your device in standard Markdown. No accounts, no tracking, pure offline speed and security.';

  @override
  String get onboarding_screen_slide2_title => 'Wikilink Connections';

  @override
  String get onboarding_screen_slide2_subtitle => 'Visual Relational Thinking';

  @override
  String get onboarding_screen_slide2_desc =>
      'Connect thoughts effortlessly by typing [[wikilinks]]. Explore relationships dynamically with automatic backlink indexes.';

  @override
  String get onboarding_screen_slide3_title => 'Thought Graph Map';

  @override
  String get onboarding_screen_slide3_subtitle => 'Interactive Mindmap';

  @override
  String get onboarding_screen_slide3_desc =>
      'Watch your connected notes blossom into an interactive force-directed graph. Visually navigate and spot patterns in your thinking.';

  @override
  String get onboarding_screen_slide4_title => 'Daily Journaling';

  @override
  String get onboarding_screen_slide4_subtitle => 'Reflective Habit Building';

  @override
  String get onboarding_screen_slide4_desc =>
      'Build healthy writing rituals with structured daily templates (Gratitude, Reflection, Goals), set word count targets, and track your active writing streak.';

  @override
  String get onboarding_screen_slide5_title => 'Editorial Aesthetics';

  @override
  String get onboarding_screen_slide5_subtitle => 'Friction-Free Design';

  @override
  String get onboarding_screen_slide5_desc =>
      'Crafted with premium typography and beautiful palettes—Clean Paper, Midnight OLED, and the warm Sepia theme.';

  @override
  String get onboarding_screen_slide6_title => 'Smart Productivity';

  @override
  String get onboarding_screen_slide6_subtitle => 'Speech & Custom Macros';

  @override
  String get onboarding_screen_slide6_desc =>
      'Dictate notes offline with real-time text formatting and high-fidelity audio attachments. Insert template checklists and custom macros in one tap.';

  @override
  String get onboarding_screen_start_writing_semantic => 'Start Writing';

  @override
  String get onboarding_screen_start_writing_label => 'Start Writing';

  @override
  String get onboarding_screen_next_slide_semantic => 'Next slide';

  @override
  String get onboarding_loading_title => 'Setting up Prism…';

  @override
  String get onboarding_loading_description =>
      'Preparing onboarding guides and setting up workspace.';

  @override
  String onboarding_vault_setup_folder_picker_error(Object error) {
    return 'Could not open folder picker: $error';
  }

  @override
  String get onboarding_vault_setup_name_required_error =>
      'Please enter a name for the main folder.';

  @override
  String get onboarding_vault_setup_invalid_chars_error =>
      'Vault name can only contain letters, numbers, spaces, underscores, and hyphens.';

  @override
  String get onboarding_vault_setup_folder_required_error =>
      'Please select a storage folder.';

  @override
  String get onboarding_vault_setup_permission_title =>
      'Storage Access Required';

  @override
  String get onboarding_vault_setup_permission_desc =>
      'To write and sync note files inside your chosen documents folder, Android requires the \"All Files Access\" permission.';

  @override
  String get onboarding_vault_setup_permission_retry_desc =>
      'Please enable All Files Access for Prism and tap Next again.';

  @override
  String onboarding_vault_setup_import_success(
    Object activeVault,
    Object hubName,
  ) {
    return 'Found existing vaults in \"$hubName\". Imported and opened \"$activeVault\".';
  }

  @override
  String onboarding_vault_setup_import_error(Object error) {
    return 'Import failed: $error. Please try again.';
  }

  @override
  String onboarding_vault_setup_setup_error(Object error) {
    return 'Setup failed: $error. Please try again.';
  }

  @override
  String get onboarding_vault_setup_config_location_title =>
      'Configure Vault Location';

  @override
  String get onboarding_vault_setup_name_vault_title => 'Name your first vault';

  @override
  String get onboarding_vault_setup_choose_location_desc =>
      'Prism stores all your notes directly on your device. Choose where your main storage folder (Prism Hub) lives. You can switch between multiple vaults later.';

  @override
  String get onboarding_vault_setup_first_vault_desc =>
      'This will be your first workspace folder created inside the main directory.';

  @override
  String get onboarding_vault_setup_vault_location_label => 'Vault Location';

  @override
  String get onboarding_vault_setup_device_storage_label => 'Device storage';

  @override
  String get onboarding_vault_setup_device_storage_desc =>
      'Allows Prism data to be accessed by other apps.';

  @override
  String get onboarding_vault_setup_app_storage_label => 'App storage';

  @override
  String get onboarding_vault_setup_app_storage_desc_android =>
      'Your data will not be accessible to other apps.';

  @override
  String get onboarding_vault_setup_app_storage_desc_warning =>
      'Android will delete your data if you uninstall Prism.';

  @override
  String get onboarding_vault_setup_hub_name_label => 'Prism Hub Name';

  @override
  String get onboarding_vault_setup_hub_name_hint =>
      'e.g. Prism Hub, My Notes, Second Brain';

  @override
  String get onboarding_vault_setup_location_selected => 'Location selected';

  @override
  String get onboarding_vault_setup_choose_folder_prompt =>
      'Tap to choose a folder';

  @override
  String get onboarding_vault_setup_location_creation_desc =>
      'Prism will create your main directory inside this folder.';

  @override
  String get onboarding_vault_setup_choose_folder_warning =>
      'Choose a storage folder above to continue';

  @override
  String get onboarding_vault_setup_vault_name_label => 'Vault Name';

  @override
  String get onboarding_vault_setup_vault_name_hint =>
      'e.g. My Vault, Personal, Research';

  @override
  String get onboarding_vault_setup_telemetry_title =>
      'Share anonymous telemetry';

  @override
  String get onboarding_vault_setup_telemetry_desc =>
      'Help us improve Prism by sharing anonymous feature usage data and crash logs. No personal data, notes, or search queries are ever collected.';

  @override
  String get onboarding_vault_setup_confirm_button => 'Confirm & Begin';

  @override
  String get onboarding_vault_setup_back_button => 'Back to step 1';

  @override
  String get onboarding_vault_setup_default_hub_name => 'Prism Hub';

  @override
  String get onboarding_vault_setup_default_vault_name => 'My Vault';

  @override
  String get onboarding_visual_journal_todays_entry => 'Today\'s Entry';

  @override
  String get onboarding_visual_journal_gratitude_heading => '## 🙏 Gratitude';

  @override
  String get onboarding_visual_journal_word_count => '185 / 250 words';

  @override
  String get onboarding_visual_productivity_date => '📅 Date';

  @override
  String get onboarding_visual_productivity_todo => '☑️ Todo';

  @override
  String get onboarding_visual_themes_clean_paper => 'Clean Paper';

  @override
  String get onboarding_visual_themes_midnight_oled => 'Midnight OLED';

  @override
  String get onboarding_visual_themes_warm_sepia => 'Warm Sepia';

  @override
  String get onboarding_visual_wikilinks_brain_map => 'Brain Map';

  @override
  String get onboarding_visual_wikilinks_wikilink_label => '[[ wikilink ]]';

  @override
  String get settings_attachments_title => 'Manage Attachments';

  @override
  String get settings_attachments_section_header => 'ATTACHED FILES';

  @override
  String settings_attachments_error(Object error) {
    return 'Error loading attachments: $error';
  }

  @override
  String get settings_attachments_storage_consumed => 'Storage Consumed';

  @override
  String settings_attachments_count_saved(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments saved',
      one: '1 attachment saved',
    );
    return '$_temp0';
  }

  @override
  String get settings_attachments_clean_orphaned => 'Clean Orphaned';

  @override
  String settings_attachments_orphaned_warning(num count, Object size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unlinked recordings are taking up $size space.',
      one: '1 unlinked recording is taking up $size space.',
    );
    return '$_temp0';
  }

  @override
  String get settings_attachments_play_recording_tooltip => 'Play Recording';

  @override
  String get settings_attachments_empty_title => 'No Attachments Found';

  @override
  String get settings_attachments_empty_desc =>
      'Voice recordings kept when editing notes will appear here.';

  @override
  String get settings_attachments_delete_confirm_desc =>
      'Are you sure you want to permanently delete this audio recording from your device? This action cannot be undone.';

  @override
  String get settings_attachments_delete_success => 'Attachment deleted.';

  @override
  String settings_attachments_delete_error(Object error) {
    return 'Failed to delete file: $error';
  }

  @override
  String get settings_attachments_purge_orphaned_title =>
      'Purge Orphaned Files';

  @override
  String settings_attachments_purge_orphaned_desc(Object count, Object size) {
    return 'Are you sure you want to permanently delete all $count unlinked recordings ($size) from your device storage? Notes will not be affected.';
  }

  @override
  String settings_attachments_purge_success(Object count) {
    return 'Successfully cleaned up $count orphaned files.';
  }

  @override
  String settings_attachments_purge_error(Object error) {
    return 'Error purging files: $error';
  }

  @override
  String get settings_attachments_purge_all_button => 'Purge All';

  @override
  String settings_cloud_sync_init_error(Object error) {
    return 'Error initializing sync service: $error';
  }

  @override
  String get settings_cloud_sync_signout_success => 'Signed out successfully.';

  @override
  String settings_cloud_sync_signout_error(Object error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get settings_cloud_sync_passphrase_empty =>
      'Passphrase cannot be empty';

  @override
  String get settings_cloud_sync_configured_success =>
      'Sync configured successfully!';

  @override
  String settings_cloud_sync_disable_title(Object vaultName) {
    return 'Disable Sync for $vaultName?';
  }

  @override
  String get settings_cloud_sync_disable_desc =>
      'Would you like to keep your encrypted backup on Google Drive, or delete it from the cloud?';

  @override
  String get settings_cloud_sync_keep_cloud_button => 'Keep in Cloud';

  @override
  String settings_cloud_sync_delete_cloud_error(Object error) {
    return 'Failed to delete cloud data: $error';
  }

  @override
  String settings_cloud_sync_delete_cloud_success(Object vaultName) {
    return 'Cloud backup for $vaultName deleted successfully.';
  }

  @override
  String settings_cloud_sync_sync_success(Object downloaded, Object uploaded) {
    return 'Sync successful! Uploaded: $uploaded, Downloaded: $downloaded';
  }

  @override
  String get settings_cloud_sync_purge_title => 'Purge All Cloud Backups?';

  @override
  String get settings_cloud_sync_purge_desc =>
      'This will permanently delete all synced vaults and files from your Google Drive AppData folder and sign you out.';

  @override
  String get settings_cloud_sync_purge_passphrase_prompt =>
      'Enter your global sync passphrase to confirm:';

  @override
  String get settings_cloud_sync_passphrase_label => 'Sync Passphrase';

  @override
  String get settings_cloud_sync_passphrase_incorrect =>
      'Incorrect passphrase!';

  @override
  String get settings_cloud_sync_purge_everything_button => 'Purge Everything';

  @override
  String get settings_cloud_sync_purge_success_msg =>
      'All cloud data purged and signed out successfully!';

  @override
  String get settings_cloud_sync_title => 'Cloud Sync';

  @override
  String get settings_cloud_sync_section_header => 'Global Selective Sync';

  @override
  String get settings_cloud_sync_section_desc =>
      'Secure your notes with end-to-end encryption. Toggle sync for each vault individually and keep your data backed up on Google Drive.';

  @override
  String get settings_cloud_sync_gdrive_header => 'Google Drive Connection';

  @override
  String get settings_cloud_sync_gdrive_desc =>
      'Connect your Google Drive account to enable cloud backups.';

  @override
  String get settings_cloud_sync_connect_button => 'Connect Google Drive';

  @override
  String get settings_cloud_sync_disconnect_tooltip => 'Disconnect Account';

  @override
  String get settings_cloud_sync_security_header => 'Security & Encryption';

  @override
  String get settings_cloud_sync_e2e_title => 'End-to-End Encryption Active';

  @override
  String get settings_cloud_sync_e2e_desc =>
      'All notes are encrypted on-device before syncing.';

  @override
  String get settings_custom_macros_title => 'Toolbar Macros';

  @override
  String get settings_custom_macros_desc =>
      'Define 3 to 5 custom text injection macros for your accessory formatting toolbar.';

  @override
  String get settings_custom_macros_add_button => 'Add Custom Macro';

  @override
  String get settings_custom_macros_reset_button => 'Reset Default Macros';

  @override
  String get settings_custom_macros_reset_confirm_title => 'Reset Macros';

  @override
  String get settings_custom_macros_reset_confirm_desc =>
      'Are you sure you want to reset all macros to their defaults? This will erase your custom edits.';

  @override
  String get settings_custom_macros_reset_success =>
      'Macros reset to defaults.';

  @override
  String settings_custom_macros_reset_error(Object error) {
    return 'Error resetting macros: $error';
  }

  @override
  String get settings_custom_macros_card_tooltip => 'Hold card to reorder';

  @override
  String get settings_custom_macros_editor_title_add => 'Create Custom Macro';

  @override
  String get settings_custom_macros_editor_title_edit => 'Edit Custom Macro';

  @override
  String get settings_custom_macros_label_field => 'BUTTON LABEL';

  @override
  String get settings_custom_macros_text_field => 'MACRO INJECTION TEXT';

  @override
  String get settings_custom_macros_label_required => 'Label is required';

  @override
  String get settings_custom_macros_text_required =>
      'Injection text is required';

  @override
  String get settings_custom_macros_placeholder_title =>
      'TAP DYNAMIC PLACEHOLDERS TO INSERT:';

  @override
  String get settings_custom_macros_placeholder_desc =>
      'You can use dynamic placeholders like {\'{datetime}\'} to insert the current date and time automatically.';

  @override
  String get settings_custom_templates_title => 'Custom Templates';

  @override
  String get settings_custom_templates_create_button =>
      'Create Custom Template';

  @override
  String settings_custom_templates_error_loading(String error) {
    return 'Error loading templates: $error';
  }

  @override
  String get settings_custom_templates_empty_title => 'No Custom Templates';

  @override
  String get settings_custom_templates_empty_desc =>
      'Create templates to quickly structure new notes. Templates support the {\'{datetime}\'} placeholder.';

  @override
  String get settings_custom_templates_delete_confirm_title =>
      'Delete Template';

  @override
  String settings_custom_templates_delete_confirm_desc(String name) {
    return 'Are you sure you want to permanently delete the template \"$name\"? This action cannot be undone.';
  }

  @override
  String get settings_custom_templates_delete_success => 'Template deleted.';

  @override
  String settings_custom_templates_delete_error(String error) {
    return 'Failed to delete template: $error';
  }

  @override
  String settings_custom_templates_template_card_words(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get settings_custom_templates_template_card_open_editor =>
      'Open in Editor';

  @override
  String get settings_custom_templates_create_dialog_title => 'Create Template';

  @override
  String get settings_custom_templates_create_dialog_hint =>
      'e.g. Weekly Review';

  @override
  String get settings_custom_templates_create_dialog_validation =>
      'Please enter a template name';

  @override
  String get settings_custom_templates_create_success =>
      'Template created. Open it from the list to write content.';

  @override
  String get settings_editor_pref_title => 'Editor Preferences';

  @override
  String get settings_editor_pref_section_general => 'Text & Layout';

  @override
  String get settings_editor_pref_show_line_numbers => 'Display Line Numbers';

  @override
  String get settings_editor_pref_show_line_numbers_desc =>
      'Show logical line numbers in the editor margin';

  @override
  String get settings_editor_pref_bracket_pairing =>
      'Auto-pair Brackets & Quotes';

  @override
  String get settings_editor_pref_bracket_pairing_desc =>
      'Automatically insert closing brackets and quotes';

  @override
  String get settings_editor_pref_font_family => 'Font Family';

  @override
  String get settings_editor_pref_font_size => 'Font size';

  @override
  String get settings_editor_pref_line_width => 'Line width';

  @override
  String get settings_editor_pref_gated_premium =>
      'Get Prism Pro to unlock this preference';

  @override
  String get settings_journal_pref_title => 'Journal Preferences';

  @override
  String get settings_journal_pref_section_behavior => 'Reflections Startup';

  @override
  String get settings_journal_pref_auto_create =>
      'Auto-create Daily Note on Launch';

  @override
  String get settings_journal_pref_auto_create_desc =>
      'Open or create today\'s journal note when launching the app';

  @override
  String get settings_journal_pref_week_start => 'Start of Week';

  @override
  String get settings_journal_pref_week_start_desc =>
      'Choose which day starts the calendar strip and habit streak calculation.';

  @override
  String get settings_journal_pref_week_start_sunday => 'Sunday';

  @override
  String get settings_journal_pref_week_start_monday => 'Monday';

  @override
  String get settings_custom_macros_reset_tooltip => 'Reset to Defaults';

  @override
  String get settings_custom_macros_header => 'Quick Macros';

  @override
  String get settings_custom_macros_delete_tooltip => 'Delete Macro';

  @override
  String get settings_custom_macros_cancel_button => 'Cancel';

  @override
  String get settings_custom_macros_reset_confirm_button => 'Reset';

  @override
  String get settings_custom_macros_label_hint => 'e.g. Date, Todo, Tag';

  @override
  String get settings_custom_macros_label_length_error =>
      'Label must be 12 chars or less';

  @override
  String get settings_custom_macros_text_hint =>
      'Enter text, templates, tags, or placeholders…';

  @override
  String get settings_custom_macros_placeholder_date_desc => 'Current Date';

  @override
  String get settings_custom_macros_placeholder_time_desc => 'Current Time';

  @override
  String get settings_custom_macros_placeholder_datetime_desc => 'Date & Time';

  @override
  String get settings_custom_macros_save_button => 'Save Changes';

  @override
  String get settings_custom_macros_cannot_delete_desc =>
      'Cannot delete (Min 3 required)';

  @override
  String get settings_custom_macros_create_button_label => 'Create Macro';

  @override
  String get settings_custom_templates_create_button_tooltip =>
      'Create Template';

  @override
  String get settings_custom_templates_manager_header => 'Template Manager';

  @override
  String get settings_custom_templates_manager_desc =>
      'Manage reusable page templates for note creation.';

  @override
  String get settings_custom_templates_list_header => 'TEMPLATES';

  @override
  String get settings_custom_templates_edit_tooltip => 'Edit Template Content';

  @override
  String get settings_custom_templates_delete_tooltip => 'Delete Template';

  @override
  String get settings_custom_templates_create_dialog_prompt =>
      'Enter a name for the new template:';

  @override
  String get settings_custom_templates_cancel_button => 'Cancel';

  @override
  String settings_custom_templates_create_error(String error) {
    return 'Failed to create template: $error';
  }

  @override
  String get settings_custom_templates_create_dialog_confirm_button => 'Create';

  @override
  String get settings_custom_templates_delete_confirm_button => 'Delete';

  @override
  String settings_editor_pref_font_size_default(String fontSize) {
    return '$fontSize (Default)';
  }

  @override
  String get settings_editor_pref_select_font_size => 'Select Font Size';

  @override
  String settings_editor_pref_line_width_default(String lineWidth) {
    return '$lineWidth (Default)';
  }

  @override
  String get settings_editor_pref_select_line_width => 'Select Line Width';

  @override
  String get settings_editor_pref_section_behaviors => 'Editor Behaviors';

  @override
  String get settings_editor_pref_show_backlinks => 'Show Backlinks by Default';

  @override
  String get settings_editor_pref_show_backlinks_desc =>
      'Display the backlinks panel at the bottom of notes';

  @override
  String get settings_journal_pref_section_calendar => 'Calendar & Streaks';

  @override
  String get settings_journal_pref_select_week_start => 'Select Start of Week';

  @override
  String get settings_manage_vaults_relocate_migrate_success =>
      'Storage location relocated and vaults migrated.';

  @override
  String get settings_manage_vaults_relocate_change_success =>
      'Storage location changed.';

  @override
  String settings_manage_vaults_relocate_error(String error) {
    return 'Error relocating storage: $error';
  }

  @override
  String get settings_manage_vaults_create_dialog_title => 'Create New Vault';

  @override
  String get settings_manage_vaults_create_dialog_hint => 'e.g. Work, Personal';

  @override
  String get settings_manage_vaults_cancel_button => 'Cancel';

  @override
  String get settings_manage_vaults_create_dialog_confirm_button => 'Create';

  @override
  String settings_manage_vaults_create_error(String error) {
    return 'Failed to create vault: $error';
  }

  @override
  String get settings_manage_vaults_rename_dialog_title => 'Rename Vault';

  @override
  String get settings_manage_vaults_rename_dialog_label => 'New Name';

  @override
  String get settings_manage_vaults_rename_dialog_confirm_button => 'Rename';

  @override
  String settings_manage_vaults_rename_error(String error) {
    return 'Failed to rename vault: $error';
  }

  @override
  String settings_manage_vaults_delete_dialog_title(String vaultName) {
    return 'Delete Vault \"$vaultName\"?';
  }

  @override
  String get settings_manage_vaults_delete_dialog_desc_warning =>
      'This will permanently delete this vault directory and all notes inside it from this device. This cannot be undone.';

  @override
  String get settings_manage_vaults_delete_confirm_button =>
      'Delete Permanently';

  @override
  String get settings_theme_gallery_applied_success =>
      'Theme applied successfully!';

  @override
  String get settings_theme_gallery_apply_button => 'Use Theme';

  @override
  String get settings_theme_gallery_subtitle =>
      'Curated editorial layouts & typography';

  @override
  String get settings_theme_gallery_live_preview_header =>
      'LIVE SCREEN PREVIEW';

  @override
  String get settings_theme_gallery_try_premium_label =>
      'Try premium colors in the mockup';

  @override
  String get settings_theme_gallery_live_preview_toggle => 'Live Preview Mode';

  @override
  String get settings_theme_gallery_light_editorial_header =>
      'LIGHT EDITORIAL PALETTES';

  @override
  String get settings_theme_gallery_tab_list => 'List';

  @override
  String get settings_theme_gallery_tab_editor => 'Editor';

  @override
  String get settings_theme_gallery_tab_graph => 'Graph';

  @override
  String get settings_main_pro_tile_upgrade_button => 'Upgrade to Pro';

  @override
  String get settings_main_section_appearance => 'Appearance';

  @override
  String get settings_main_appearance_font_family => 'Font family';

  @override
  String settings_main_appearance_font_family_default(String font) {
    return '$font (Default)';
  }

  @override
  String get settings_main_appearance_select_font_family =>
      'Select Font Family';

  @override
  String get settings_main_section_preferences => 'Preferences';

  @override
  String get settings_main_section_sync => 'Sync & Data';

  @override
  String get settings_main_export_title => 'Vault Export';

  @override
  String get settings_main_export_desc =>
      'Download all notes as ZIP, PDF or JSON';

  @override
  String get settings_main_section_gestures => 'Gestures & Feedback';

  @override
  String get settings_main_section_subscription => 'Subscription';

  @override
  String get settings_main_pro_status_desc => 'Manage subscription & billing';

  @override
  String settings_main_pro_customer_center_error(String error) {
    return 'Failed to open Customer Center: $error';
  }

  @override
  String get settings_export_bottom_sheet_choose_format =>
      'Choose a format to export your notes';

  @override
  String get settings_export_bottom_sheet_exporting => 'Exporting…';

  @override
  String get settings_export_bottom_sheet_complete => 'Export Complete';

  @override
  String settings_export_bottom_sheet_notes_count(int count, String sizeStr) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0 · $sizeStr';
  }

  @override
  String get settings_export_bottom_sheet_done_button => 'Done';

  @override
  String get settings_export_format_json_label => 'JSON export';

  @override
  String get settings_export_format_json_desc =>
      'All notes, tags, backlinks and folder names in a structured JSON file';

  @override
  String get settings_export_format_zip_label => 'ZIP archive';

  @override
  String get settings_export_format_zip_desc =>
      'All markdown notes and attachments in a single ZIP file';

  @override
  String get settings_export_format_pdf_compiled_label => 'Single PDF';

  @override
  String get settings_export_format_pdf_compiled_desc =>
      'All notes compiled into one paginated PDF document';

  @override
  String get settings_export_format_pdf_zipped_label => 'PDFs in ZIP';

  @override
  String get settings_export_format_pdf_zipped_desc =>
      'Each note rendered as its own PDF, bundled in a ZIP';

  @override
  String get settings_manage_vaults_rename_dialog_hint => 'Vault Name';

  @override
  String get settings_theme_gallery_title => 'Theme Gallery';

  @override
  String get settings_main_title => 'Settings';

  @override
  String get settings_main_pro_tile_title => 'Prism Pro';

  @override
  String get settings_main_pro_tile_desc =>
      'Unlock cloud sync, custom templates & macros, and premium typography & themes.';

  @override
  String get settings_main_editor_title => 'Editor Preferences';

  @override
  String get settings_main_editor_desc =>
      'Font size, line width, line numbers, and auto-pairing';

  @override
  String get settings_main_journal_title => 'Journal Preferences';

  @override
  String get settings_main_journal_desc =>
      'Start of week and auto-creation settings';

  @override
  String get settings_main_macros_title => 'Custom Toolbar Macros';

  @override
  String get settings_main_macros_desc =>
      'Define 3–5 custom quick-insert macros';

  @override
  String get settings_main_templates_title => 'Custom Templates';

  @override
  String get settings_main_templates_desc => 'Create reusable note templates';

  @override
  String get settings_main_attachments_title => 'Manage Attachments';

  @override
  String get settings_main_attachments_desc =>
      'View and delete audio attachments';

  @override
  String get settings_main_sync_title => 'Cloud Sync';

  @override
  String get settings_main_sync_desc =>
      'Google Drive sync, backups, and security';

  @override
  String get settings_main_vaults_title => 'Manage Vaults';

  @override
  String get settings_main_vaults_desc =>
      'Switch vaults, check stats, or change Hub location';

  @override
  String get settings_main_pro_status_active => 'Prism Pro Active';

  @override
  String get settings_main_section_feedback => 'Feedback & Support';

  @override
  String get settings_main_support_title => 'Contact Support & Feedback';

  @override
  String get settings_main_support_desc =>
      'Report bugs, suggest features, or get help';

  @override
  String get settings_export_bottom_sheet_title => 'Export Vault';

  @override
  String get settings_widgets_theme_system => 'System Sync';

  @override
  String get settings_widgets_theme_light => 'Clean Paper';

  @override
  String get settings_widgets_theme_dark => 'Dusk Dark';

  @override
  String get settings_widgets_theme_explore_teaser =>
      'Explore Editorial Themes';

  @override
  String get settings_widgets_theme_teaser_list =>
      'Sepia, Forest, Noir, Slate, and 4 more...';

  @override
  String settings_widgets_coming_soon(String title) {
    return '$title is coming soon!';
  }

  @override
  String get settings_widgets_haptic_feedback => 'Haptic Feedback';

  @override
  String get settings_widgets_haptic_feedback_desc =>
      'Vibrate on satisfying button presses and interactions';

  @override
  String get settings_widgets_pin_nodes => 'Pin Graph Nodes on Drag';

  @override
  String get settings_widgets_pin_nodes_desc =>
      'Pin year/week calendar nodes when dragging them';

  @override
  String get settings_widgets_analytics => 'Share Usage Analytics';

  @override
  String get settings_widgets_analytics_desc =>
      'Help us improve Prism by sharing anonymous app usage stats and crash reports';

  @override
  String get settings_support_title => 'Contact Support';

  @override
  String get settings_support_how_can_we_help => 'How can we help you?';

  @override
  String get settings_support_subtitle_desc =>
      'Submit bug reports, request feature enhancements, or send general feedback directly to the Prism team.';

  @override
  String get settings_support_category_label => 'Category';

  @override
  String get settings_support_category_bug => '🐛  Report a Bug';

  @override
  String get settings_support_category_feature => '✨  Feature Request';

  @override
  String get settings_support_category_feedback => '💬  General Feedback';

  @override
  String get settings_support_category_question => '❓  Question';

  @override
  String get settings_support_subject_label => 'Subject';

  @override
  String get settings_support_subject_hint => 'Summary of the issue...';

  @override
  String get settings_support_subject_required => 'Please enter a subject.';

  @override
  String get settings_support_desc_label => 'Message Details';

  @override
  String get settings_support_desc_hint =>
      'Describe the issue or feedback in detail...';

  @override
  String get settings_support_desc_required =>
      'Please enter details for your request.';

  @override
  String get settings_support_attach_diagnostics => 'Attach System Diagnostics';

  @override
  String get settings_support_attach_diagnostics_desc =>
      'Include anonymous device logs and vault stats.';

  @override
  String get settings_support_preview_diagnostics => 'Diagnostics Preview';

  @override
  String get settings_support_send_button => 'Send Support Request';

  @override
  String get settings_support_fallback_dialog_title => 'No Email App Found';

  @override
  String get settings_support_fallback_dialog_desc =>
      'We couldn\'t automatically launch your email application. You can send your support request manually to our address below:';

  @override
  String get settings_support_fallback_dialog_copy_desc =>
      'Tap below to copy the diagnostic log and message details to your clipboard, then email them to us.';

  @override
  String get settings_support_cancel_button => 'Cancel';

  @override
  String get settings_support_copy_success =>
      'Support log copied to clipboard!';

  @override
  String get settings_support_copy_button => 'Copy Diagnostics & Email';

  @override
  String get paywall_title_pro_active => 'You are a Pro member!';

  @override
  String get paywall_title_pro_inactive => 'Elevate Your Notebook';

  @override
  String get paywall_desc_pro_active =>
      'Thank you for supporting Prism. All premium features are unlocked.';

  @override
  String get paywall_desc_pro_inactive =>
      'Unlock cross-device sync, custom formats, and premium styling.';

  @override
  String get paywall_empty_packages =>
      'No subscription options available currently.';

  @override
  String paywall_error_loading(String error) {
    return 'Error loading products: $error';
  }

  @override
  String get paywall_upgrade_button => 'Upgrade Now';

  @override
  String get paywall_disclaimer =>
      'Subscription auto-renews until cancelled. Manage or cancel anytime in your Google Play account settings.';

  @override
  String get paywall_restore_button => 'Restore Purchases';

  @override
  String get paywall_feature_sync => 'E2E Google Drive Sync';

  @override
  String get paywall_feature_templates_macros => 'Custom Templates & Macros';

  @override
  String get paywall_feature_audio_bookmarks => 'Timeline Audio Bookmarks';

  @override
  String get paywall_feature_themes_fonts => 'Premium Themes & Fonts';

  @override
  String get paywall_feature_export => 'Vault Export (ZIP/PDF/JSON)';

  @override
  String get paywall_feature_unlimited_vaults => 'Unlimited Vaults (Local)';

  @override
  String get paywall_feature_local_ai => 'Local & BYOD AI';

  @override
  String get paywall_header_features => 'Features';

  @override
  String get paywall_header_free => 'Free';

  @override
  String get paywall_header_pro => 'Pro';

  @override
  String get paywall_not_available_semantic => 'Not available';

  @override
  String get paywall_save_percentage_yearly => 'SAVE 25%';

  @override
  String get paywall_yearly_access => 'Yearly Access';

  @override
  String get paywall_monthly_access => 'Monthly Access';

  @override
  String get paywall_yearly_suffix => '/year';

  @override
  String get paywall_monthly_suffix => '/month';

  @override
  String get paywall_purchase_cancelled => 'Purchase cancelled.';

  @override
  String get paywall_purchase_failed_title => 'Purchase Failed';

  @override
  String get paywall_ok => 'OK';

  @override
  String get paywall_purchase_success => 'Prism Pro unlocked successfully!';

  @override
  String get paywall_restore_failed_title => 'Restore Failed';

  @override
  String get paywall_restore_success => 'Purchases restored. Prism Pro active!';

  @override
  String get paywall_restore_empty => 'No active purchases found to restore.';
}
