import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _category = 'bug';
  bool _attachDiagnostics = true;

  // Diagnostics info
  int _noteCount = 0;
  int _attachmentCount = 0;
  String _totalSizeStr = '0 KB';
  String _vaultType = 'sandbox';
  String _appUserId = 'Loading...';
  String _appVersion = '...';
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activePath = ref.read(activeVaultPathProvider).valueOrNull ?? '';
      if (activePath.isNotEmpty) {
        _loadVaultStatsForPath(activePath);
      }
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadVaultStatsForPath(String activePath) async {
    if (activePath.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final vaultType = prefs.getString('vaultType') ?? 'sandbox';

      final dir = Directory(activePath);
      int notes = 0;
      int attachments = 0;
      int bytes = 0;

      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            final ext = p.extension(entity.path).toLowerCase();
            final size = entity.lengthSync();
            bytes += size;

            if (ext == '.md') {
              notes++;
            } else if (ext == '.m4a') {
              attachments++;
            }
          }
        }
      }

      String userId = 'Anonymous';
      try {
        final customerInfo = await ref.read(revenueCatClientWrapperProvider).getCustomerInfo();
        userId = customerInfo.originalAppUserId;
      } catch (_) {
        userId = 'Unknown (Offline)';
      }

      if (mounted) {
        setState(() {
          _noteCount = notes;
          _attachmentCount = attachments;
          _totalSizeStr = _formatBytes(bytes);
          _vaultType = vaultType;
          _appUserId = userId;
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading vault stats for support diagnostics: $e');
      if (mounted) {
        setState(() => _isStatsLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'bug':
        return 'Bug Report';
      case 'feature':
        return 'Feature Request';
      case 'feedback':
        return 'General Feedback';
      case 'question':
        return 'Question';
      default:
        return 'Bug Report';
    }
  }

  String _buildDiagnosticText(bool isPro) {
    final osName = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;
    return '''
--- Diagnostic Info ---
App Version: $_appVersion
Platform: $osName ($osVersion)
Vault Type: $_vaultType
Notes Count: $_noteCount
Attachments: $_attachmentCount
Vault Size: $_totalSizeStr
Pro Active: ${isPro ? 'Yes' : 'No'}
User ID: $_appUserId
''';
  }

  Future<void> _submitSupportRequest(bool isPro) async {
    if (!_formKey.currentState!.validate()) return;

    final categoryLabel = _getCategoryLabel(_category);
    final subjectText = _subjectController.text.trim();
    final messageText = _messageController.text.trim();

    final bodyBuffer = StringBuffer();
    bodyBuffer.writeln(messageText);
    bodyBuffer.writeln();

    if (_attachDiagnostics) {
      bodyBuffer.writeln(_buildDiagnosticText(isPro));
    }

    final emailUri = Uri(
      scheme: 'mailto',
      path: 'Prismsupport@smallgiantstudio.com',
      queryParameters: {
        'subject': '[Prism $categoryLabel] $subjectText',
        'body': bodyBuffer.toString(),
      },
    );

    // Log telemetry event
    AnalyticsService.logEvent('contact_support', parameters: {
      'category': _category,
    });

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showCopyFallbackDialog(bodyBuffer.toString());
      }
    } catch (e) {
      debugPrint('Error launching support email client: $e');
      _showCopyFallbackDialog(bodyBuffer.toString());
    }
  }

  void _showCopyFallbackDialog(String fullBody) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignColors.surface(context),
          title: Text(
            'No Email App Found',
            style: DesignTypography.heading(context, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'We couldn\'t automatically launch your email application. You can send your support request manually to our address below:',
                  style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DesignColors.border(context)),
                  ),
                  child: SelectableText(
                    'Prismsupport@smallgiantstudio.com',
                    style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap below to copy the diagnostic log and message details to your clipboard, then email them to us.',
                  style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: DesignColors.textSecondary(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullBody));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support log copied to clipboard!'),
                  ),
                );
              },
              child: const Text('Copy Diagnostics & Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<String>>(activeVaultPathProvider, (previous, next) {
      final path = next.valueOrNull ?? '';
      if (path.isNotEmpty) {
        _loadVaultStatsForPath(path);
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = DesignColors.text(context);
    final textSecStyle = DesignColors.textSecondary(context);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textStyle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Support',
          style: DesignTypography.heading(context, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'How can we help you?',
                style: DesignTypography.display(context, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Submit bug reports, request feature enhancements, or send general feedback directly to the Prism team.',
                style: DesignTypography.body(context, fontSize: 14, color: textSecStyle),
              ),
              const SizedBox(height: 28),

              // Category Dropdown
              Text(
                'Category',
                style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                style: DesignTypography.body(context, fontSize: 14, color: textStyle),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DesignColors.surfaceVariant(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                ),
                dropdownColor: DesignColors.surface(context),
                items: [
                  DropdownMenuItem(value: 'bug', child: Text('🐛  Report a Bug', style: TextStyle(color: textStyle))),
                  DropdownMenuItem(value: 'feature', child: Text('✨  Feature Request', style: TextStyle(color: textStyle))),
                  DropdownMenuItem(value: 'feedback', child: Text('💬  General Feedback', style: TextStyle(color: textStyle))),
                  DropdownMenuItem(value: 'question', child: Text('❓  Question', style: TextStyle(color: textStyle))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 24),

              // Subject Input
              Text(
                'Subject',
                style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: DesignTypography.body(context, fontSize: 14, color: textStyle),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DesignColors.surfaceVariant(context),
                  hintText: 'Summary of the issue...',
                  hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a subject.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Message Input
              Text(
                'Message Details',
                style: DesignTypography.body(context, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                style: DesignTypography.body(context, fontSize: 14, color: textStyle),
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DesignColors.surfaceVariant(context),
                  hintText: 'Describe the issue or feedback in detail...',
                  hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: DesignColors.border(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter details for your request.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Diagnostics Switch Tile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: DesignColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DesignColors.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attach System Diagnostics',
                            style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Include anonymous device logs and vault stats.',
                            style: DesignTypography.details(context, color: textSecStyle),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _attachDiagnostics,
                      activeColor: colorScheme.primary,
                      onChanged: (val) => setState(() => _attachDiagnostics = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Diagnostics Preview Card
              if (_attachDiagnostics)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DesignColors.border(context)),
                  ),
                  child: _isStatsLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diagnostics Preview',
                              style: DesignTypography.body(context, fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _buildDiagnosticText(isPro),
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                height: 1.6,
                                color: textSecStyle,
                              ),
                            ),
                          ],
                        ),
                ),

              const SizedBox(height: 36),

              // Submit Button
              DesignPrimaryButton(
                label: 'Send Support Request',
                icon: Icons.send_rounded,
                onTap: () => _submitSupportRequest(isPro),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
