import 'package:flutter/material.dart';

// Public row model for a section entry
class SectionRowData {
  final String section;
  final int totalStudents;
  final int? successfull;
  final int? conditional;
  final int? unsuccessfull;
  final String? providedAvgText;
  final String? lecturer;

  const SectionRowData({
    required this.section,
    required this.totalStudents,
    this.successfull,
    this.conditional,
    this.unsuccessfull,
    this.providedAvgText,
    this.lecturer,
  });
}

// Public group model per term/dataset
class SectionTermGroup {
  final String label; // e.g., "2024-2025 1. dönem"
  final List<SectionRowData>? sections; // null or empty -> not offered
  const SectionTermGroup({required this.label, required this.sections});
}

// Reusable table with merged term cell and section rows
class SectionHistoryTable extends StatelessWidget {
  final List<SectionTermGroup> groups;
  final String courseCode;
  final String notOfferedText;

  const SectionHistoryTable({
    super.key,
    required this.groups,
    required this.courseCode,
    this.notOfferedText = 'Bu dönemde açılmadı',
  });

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final divider = outline.withValues(alpha: 0.25);
    final groupDivider = outline.withValues(alpha: 0.6);
    const groupDividerWidth = 2.0;
    const minWidth = 800.0;

    final table = Container(
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: _HeaderCell('Dönem')),
                const Expanded(flex: 1, child: _HeaderCell('Sınıf')),
                const Expanded(flex: 1, child: _HeaderCell('Öğrenci')),
                const Expanded(flex: 1, child: _HeaderCell('Geçen')),
                const Expanded(flex: 1, child: _HeaderCell('Koşullu')),
                const Expanded(flex: 1, child: _HeaderCell('Kalan')),
                const Expanded(flex: 1, child: _HeaderCell('Ortalama')),
                const Expanded(flex: 2, child: _HeaderCell('Öğretmen')),
              ],
            ),
          ),

          // Groups
          ...groups.asMap().entries.expand((entry) {
            final index = entry.key;
            final g = entry.value;
            final isLastGroup = index == groups.length - 1;
            final sections = g.sections;

            if (sections == null || sections.isEmpty) {
              return [
                _RowContainer(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _Cell(
                        g.label,
                        rightBorder: true,
                        textAlign: TextAlign.center,
                        bottomBorder: !isLastGroup,
                        bottomBorderColor:
                            !isLastGroup ? groupDivider : divider,
                        bottomBorderWidth:
                            !isLastGroup ? groupDividerWidth : 0,
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: _RowMessageCell(
                        notOfferedText,
                        bottomBorder: !isLastGroup,
                        bottomBorderColor:
                            !isLastGroup ? groupDivider : divider,
                        bottomBorderWidth:
                            !isLastGroup ? groupDividerWidth : 0,
                      ),
                    ),
                  ],
                ),
              ];
            }

            return [
              _MergedSectionGroup(
                label: g.label,
                sections: sections,
                code: courseCode,
                isLastGroup: isLastGroup,
                dividerColor: divider,
                groupDividerColor: groupDivider,
                groupDividerWidth: groupDividerWidth,
              ),
            ];
          }),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return table;
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool emphasize;
  final bool rightBorder;
  final bool bottomBorder;
  final double bottomBorderWidth;
  final Color? bottomBorderColor;
  final Color? color;
  final TextAlign textAlign;
  const _Cell(
    this.text, {
    this.emphasize = false,
    this.rightBorder = false,
    this.bottomBorder = true,
    this.bottomBorderWidth = 1,
    this.bottomBorderColor,
    this.color,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.25);
    final resolvedBottomColor = bottomBorderColor ?? divider;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: rightBorder ? divider : Colors.transparent),
          bottom: BorderSide(
            color: bottomBorder ? resolvedBottomColor : Colors.transparent,
            width: bottomBorder ? bottomBorderWidth : 0,
          ),
        ),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _RowContainer extends StatelessWidget {
  final List<Widget> children;
  const _RowContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RowMessageCell extends StatelessWidget {
  final String text;
  final bool bottomBorder;
  final double bottomBorderWidth;
  final Color? bottomBorderColor;
  const _RowMessageCell(
    this.text, {
    this.bottomBorder = true,
    this.bottomBorderWidth = 1,
    this.bottomBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.25);
    final resolvedBottomColor = bottomBorderColor ?? divider;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: bottomBorder ? resolvedBottomColor : Colors.transparent,
            width: bottomBorder ? bottomBorderWidth : 0,
          ),
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MergedSectionGroup extends StatelessWidget {
  final String label;
  final List<SectionRowData> sections;
  final String code;
  final bool isLastGroup;
  final Color dividerColor;
  final Color groupDividerColor;
  final double groupDividerWidth;

  const _MergedSectionGroup({
    required this.label,
    required this.sections,
    required this.code,
    this.isLastGroup = false,
    required this.dividerColor,
    required this.groupDividerColor,
    required this.groupDividerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left merged term cell
          Expanded(
            flex: 2,
            child: _MergedLeftCell(
              label,
              dividerColor: dividerColor,
              bottomBorder: !isLastGroup,
              bottomBorderColor: !isLastGroup ? groupDividerColor : dividerColor,
              bottomBorderWidth: !isLastGroup ? groupDividerWidth : 0,
            ),
          ),
          // Right mini-table for sections
          Expanded(
            flex: 8,
            child: Column(
              children: [
                for (final (index, s) in sections.indexed)
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          _formatSectionShort(s.section, code),
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          s.totalStudents.toString(),
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          s.successfull?.toString() ?? '-',
                          color: Colors.green,
                          emphasize: s.successfull != null,
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          s.conditional?.toString() ?? '-',
                          color: Colors.orange,
                          emphasize: s.conditional != null,
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          s.unsuccessfull?.toString() ?? '-',
                          color: Colors.red,
                          emphasize: s.unsuccessfull != null,
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _Cell(
                          s.providedAvgText ?? '-',
                          rightBorder: true,
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Cell(
                          s.lecturer ?? '-',
                          bottomBorder:
                              !isLastGroup || index != sections.length - 1,
                          bottomBorderColor:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerColor
                                  : dividerColor,
                          bottomBorderWidth:
                              !isLastGroup && index == sections.length - 1
                                  ? groupDividerWidth
                                  : 1,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MergedLeftCell extends StatelessWidget {
  final String text;
  final Color dividerColor;
  final bool bottomBorder;
  final Color? bottomBorderColor;
  final double bottomBorderWidth;
  const _MergedLeftCell(
    this.text, {
    required this.dividerColor,
    this.bottomBorder = true,
    this.bottomBorderColor,
    this.bottomBorderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBottomColor = bottomBorderColor ?? dividerColor;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: dividerColor),
          bottom: BorderSide(
            color: bottomBorder ? resolvedBottomColor : Colors.transparent,
            width: bottomBorder ? bottomBorderWidth : 0,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

String _formatSectionShort(String section, String code) {
  if (section.isEmpty) return '-';
  final idx = section.indexOf('_');
  if (idx != -1 && idx + 1 < section.length) {
    return section.substring(idx + 1);
  }
  final s = section.replaceFirst(code, '').trim();
  if (s.isNotEmpty) return s.replaceAll(RegExp(r'^[^0-9A-Za-z]+'), '');
  return section;
}
