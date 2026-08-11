import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scheduler/app/theme/theme_provider.dart' hide Theme;
import 'package:scheduler/core/services/analytics_data_service.dart';
import 'package:scheduler/features/about/pages/about_page.dart';
import 'package:scheduler/features/course_selection/providers/course_providers.dart';
import 'package:scheduler/features/datasets/providers/asset_datasets_provider.dart';

class AppOverflowMenu extends ConsumerWidget {
  const AppOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return PopupMenuButton<Object>(
      tooltip: 'Menü',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value is AppThemeMode) {
          await themeNotifier.setTheme(value);
        } else if (value == 'about') {
          if (context.mounted) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AboutPage()));
          }
        } else if (value == 'feedback') {
          if (context.mounted) {
            await _showFeedbackDialog(context, ref);
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Object>>[
        const PopupMenuItem<Object>(
          enabled: false,
          child: Text('Tema', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        CheckedPopupMenuItem<Object>(
          value: AppThemeMode.system,
          checked: currentTheme == AppThemeMode.system,
          child: const Row(
            children: [
              Icon(Icons.auto_mode),
              SizedBox(width: 8),
              Text('Sistem'),
            ],
          ),
        ),
        CheckedPopupMenuItem<Object>(
          value: AppThemeMode.light,
          checked: currentTheme == AppThemeMode.light,
          child: const Row(
            children: [
              Icon(Icons.light_mode),
              SizedBox(width: 8),
              Text('Aydınlık'),
            ],
          ),
        ),
        CheckedPopupMenuItem<Object>(
          value: AppThemeMode.dark,
          checked: currentTheme == AppThemeMode.dark,
          child: const Row(
            children: [Icon(Icons.dark_mode), SizedBox(width: 8), Text('Koyu')],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<Object>(
          value: 'feedback',
          child: Row(
            children: [
              Icon(Icons.feedback_outlined),
              SizedBox(width: 8),
              Text('Geri Bildirim'),
            ],
          ),
        ),
        const PopupMenuItem<Object>(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Hakkında'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    bool isSending = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final theme = Theme.of(dialogContext);
            final canSend = controller.text.trim().isNotEmpty && !isSending;
            return AlertDialog(
              title: const Text('Geri Bildirim'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText:
                            'Öneri, hata bildirimi veya isteklerinizi yazın...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Geri bildiriminiz anonim olarak kaydedilecektir. '
                      'Kişisel bilgi yazmamanızı öneririz.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton.icon(
                  onPressed: canSend
                      ? () async {
                          setState(() => isSending = true);
                          final message = controller.text.trim();
                          try {
                            await _submitFeedback(context, ref, message);
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Geri bildiriminiz alındı. Teşekkürler.',
                                ),
                              ),
                            );
                          } catch (_) {
                            setState(() => isSending = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Geri bildirim gönderilemedi.',
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedCourses = ref.read(selectedCoursesProvider);
    final dataset = ref.read(currentDatasetInfoProvider);
    final allowConflicts = ref.read(allowConflictsProvider);
    final minFreeDays = ref.read(minFreeDaysProvider);

    await AnalyticsDataService().submitFeedback(
      message: message,
      selectedCourses: selectedCourses,
      datasetPath: dataset?.path,
      datasetYear: dataset?.year,
      datasetPeriod: dataset?.period,
      allowConflicts: allowConflicts,
      minFreeDays: minFreeDays,
      locale: locale,
    );
  }
}
