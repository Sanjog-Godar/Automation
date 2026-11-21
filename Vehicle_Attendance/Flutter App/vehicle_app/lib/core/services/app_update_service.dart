import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'toast_service.dart';

/// Model representing remote version metadata.
class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;
  final String releaseNotesNe;
  final String? releaseDate;

  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
    required this.releaseNotesNe,
    this.releaseDate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 1,
      apkUrl: json['apkUrl'] as String? ??
          '${AppConfig.liveProductionBaseUrl}/bolero-attendance.apk',
      releaseNotes: json['releaseNotes'] as String? ?? 'Bug fixes and performance improvements.',
      releaseNotesNe: json['releaseNotesNe'] as String? ?? 'सुधार र नयाँ सुविधाहरू।',
      releaseDate: json['releaseDate'] as String?,
    );
  }
}

/// Service providing Over-The-Air (OTA) in-app updates.
class AppUpdateService {
  final Dio _dio;
  final ToastService _toastService;

  AppUpdateService({
    Dio? dio,
    ToastService? toastService,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _toastService = toastService ?? ToastService();

  /// Checks remote version metadata against [AppConfig.currentBuildNumber].
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final endpoint = '${AppConfig.apiBaseUrl}/version.json';
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final info = AppUpdateInfo.fromJson(response.data!);
        if (info.buildNumber > AppConfig.currentBuildNumber) {
          return info;
        }
      }
    } catch (e) {
      debugPrint('AppUpdateService: Check for update failed ($e)');
    }
    return null;
  }

  /// Checks for an update and displays an update prompt if available.
  Future<void> checkForUpdateAndPrompt(
    BuildContext context, {
    bool silent = true,
  }) async {
    final info = await checkForUpdate();
    if (!context.mounted) return;

    if (info != null) {
      await showUpdateDialog(context, info);
    } else if (!silent) {
      final l10n = AppLocalizations.of(context);
      _toastService.showSuccess(
        l10n.update_up_to_date(AppConfig.currentVersion),
        nepaliMessage: l10n.update_up_to_date(AppConfig.currentVersion),
      );
    }
  }

  /// Displays the interactive update dialog with senior-friendly high contrast.
  Future<void> showUpdateDialog(
    BuildContext context,
    AppUpdateInfo info,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AppUpdateDialog(info: info),
    );
  }
}

class _AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;

  const _AppUpdateDialog({required this.info});

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  bool _isDownloading = false;
  String _progressText = '0%';
  double _progressValue = 0.0;
  String? _statusMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate(AppLocalizations l10n) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = l10n.update_downloading('0');
    });

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        _otaSubscription = OtaUpdate()
            .execute(widget.info.apkUrl, destinationFilename: 'bolero_attendance.apk')
            .listen(
          (OtaEvent event) {
            if (!mounted) return;
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                final progressInt = int.tryParse(event.value ?? '0') ?? 0;
                setState(() {
                  _progressValue = (progressInt / 100.0).clamp(0.0, 1.0);
                  _progressText = '$progressInt%';
                  _statusMessage = l10n.update_downloading(_progressText);
                });
                break;
              case OtaStatus.INSTALLING:
              case OtaStatus.INSTALLATION_DONE:
                setState(() {
                  _progressValue = 1.0;
                  _statusMessage = l10n.update_installing;
                });
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              case OtaStatus.INTERNAL_ERROR:
              case OtaStatus.DOWNLOAD_ERROR:
              case OtaStatus.CHECKSUM_ERROR:
              default:
                _fallbackToBrowser(l10n);
                break;
            }
          },
          onError: (_) {
            _fallbackToBrowser(l10n);
          },
        );
        return;
      } catch (_) {
        _fallbackToBrowser(l10n);
      }
    } else {
      _fallbackToBrowser(l10n);
    }
  }

  Future<void> _fallbackToBrowser(AppLocalizations l10n) async {
    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _statusMessage = l10n.update_failed;
    });

    try {
      final uri = Uri.parse(widget.info.apkUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isNepali = locale.languageCode == 'ne';
    final notes = isNepali ? widget.info.releaseNotesNe : widget.info.releaseNotes;

    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.update_available_title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v${widget.info.version}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.update_available_desc(widget.info.version),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progressValue > 0 ? _progressValue : null,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusMessage ?? l10n.update_downloading(_progressText),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isDownloading) ...[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.update_btn_later,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _startUpdate(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(
                l10n.update_btn_update,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Global provider for [AppUpdateService].
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    toastService: ref.watch(toastServiceProvider),
  );
});
