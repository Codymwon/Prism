import 'package:flutter/material.dart';
import 'package:prism/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_permission_helper.dart';
import '../design_system/design_system.dart';

class StoragePermissionScreen extends StatefulWidget {
  final AppThemeType themeType;
  final String fontFamily;
  final VoidCallback onPermissionGranted;

  const StoragePermissionScreen({
    super.key,
    required this.themeType,
    required this.fontFamily,
    required this.onPermissionGranted,
  });

  @override
  State<StoragePermissionScreen> createState() => _StoragePermissionScreenState();
}

class _StoragePermissionScreenState extends State<StoragePermissionScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionSilent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionSilent();
    }
  }

  Future<void> _checkPermissionSilent() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final hasAccess = await StoragePermissionHelper.hasAllFilesAccess();
    if (hasAccess) {
      widget.onPermissionGranted();
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _requestAccess() async {
    await StoragePermissionHelper.requestAllFilesAccess();
  }

  @override
  Widget build(BuildContext context) {
    final resolution = AppTheme.resolve(widget.themeType, widget.fontFamily);
    final themeData = resolution.themeData;
    final darkThemeData = resolution.darkThemeData;
    final mode = resolution.mode;

    return MaterialApp(
      title: 'Prism',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: darkThemeData,
      themeMode: mode,
      themeAnimationDuration: Duration.zero,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: DesignColors.background(context),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // ── Shield/Folder Security Icon ──
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.folder_shared_rounded,
                          color: colorScheme.primary,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Headline ──
                    Text(
                      context.l10n.shared_storage_permission_title,
                      style: DesignTypography.display(
                        context,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: DesignColors.text(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // ── Description ──
                    Text(
                      context.l10n.shared_storage_permission_desc,
                      style: DesignTypography.body(
                        context,
                        fontSize: 14,
                        height: 1.6,
                        color: DesignColors.textSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // ── Action Button ──
                    DesignPrimaryButton(
                      label: context.l10n.shared_storage_permission_grant_button,
                      icon: Icons.settings_suggest_rounded,
                      onTap: _requestAccess,
                    ),
                    const SizedBox(height: 20),

                    // ── Secondary instructions ──
                    Text(
                      context.l10n.shared_storage_permission_secondary_desc,
                      style: DesignTypography.details(
                        context,
                        fontSize: 12,
                        color: DesignColors.textTertiary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),

                    // ── Status Indicator ──
                    if (_isChecking)
                      Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: context.l10n.shared_storage_permission_loading_label,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DesignColors.textTertiary(context),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
