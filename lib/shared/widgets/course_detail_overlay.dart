import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scheduler/core/models/course.dart';
import 'package:scheduler/shared/widgets/course_history_section.dart';

class CourseDetailOverlay {
  static Future<void> show(
    BuildContext context, {
    required Course course,
    required Color accentColor,
    required String heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondary, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(opacity: fade, child: child);
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          final colorTween = ColorTween(
            begin: Colors.transparent,
            end: Colors.black54,
          );
          return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).maybePop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: [
                // Scrim with tap-to-dismiss
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) =>
                          Container(color: colorTween.evaluate(animation)),
                    ),
                  ),
                ),
                // Growing card from tapped course using Hero.
                Center(
                  child: Hero(
                    tag: heroTag,
                    createRectTween: (begin, end) =>
                        MaterialRectCenterArcTween(begin: begin!, end: end!),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth:
                              ((MediaQuery.of(context).size.width - 32).clamp(
                                280.0,
                                960.0,
                              )).toDouble(),
                          maxHeight:
                              ((MediaQuery.of(context).size.height -
                                          32 -
                                          MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom)
                                      .clamp(320.0, 900.0))
                                  .toDouble(),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _CourseDetailContent(
                            course: course,
                            accentColor: accentColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CourseDetailContent extends StatelessWidget {
  final Course course;
  final Color accentColor;

  const _CourseDetailContent({required this.course, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (course.section.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Section ${course.section}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Kapat',
              ),
            ],
          ),
        ),

        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course name
                Text(
                  course.name.isNotEmpty
                      ? course.name
                      : 'Ders Adı Belirtilmemiş',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Course details - 2 column layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          CourseDetailItem(
                            icon: Icons.person,
                            label: 'Öğretim Üyesi',
                            value: course.lecturer.isNotEmpty
                                ? course.lecturer
                                : 'Belirtilmemiş',
                            accentColor: accentColor,
                          ),
                          CourseDetailItem(
                            icon: Icons.schedule,
                            label: 'Zaman',
                            value: course.schedule.isNotEmpty
                                ? course.schedule
                                : 'Belirtilmemiş',
                            accentColor: accentColor,
                          ),
                          CourseDetailItem(
                            icon: Icons.room,
                            label: 'Derslik',
                            value: course.room.isNotEmpty
                                ? course.room
                                : 'Belirtilmemiş',
                            accentColor: accentColor,
                          ),
                          if (course.faculty.isNotEmpty)
                            CourseDetailItem(
                              icon: Icons.account_balance,
                              label: 'Fakülte',
                              value: course.faculty,
                              accentColor: accentColor,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          CourseDetailItem(
                            icon: Icons.credit_card,
                            label: 'Kredi',
                            value: course.credits > 0
                                ? '${course.credits} kredi'
                                : 'Belirtilmemiş',
                            accentColor: accentColor,
                          ),
                          if (course.department.isNotEmpty)
                            CourseDetailItem(
                              icon: Icons.school,
                              label: 'Bölüm',
                              value: course.department,
                              accentColor: accentColor,
                            ),
                          if (course.type.isNotEmpty)
                            CourseDetailItem(
                              icon: Icons.category,
                              label: 'Ders Türü',
                              value: course.type,
                              accentColor: accentColor,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (course.prerequisites.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ön Koşullar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: course.prerequisites
                        .map(
                          (prereq) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Text(
                              prereq,
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                if (course.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Ders Açıklaması',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      course.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                // Previous terms section
                CourseHistorySection(code: course.code),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CourseDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const CourseDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
