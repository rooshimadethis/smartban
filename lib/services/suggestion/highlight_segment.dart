/// Represents a segment of text to be highlighted with a specific type.
class HighlightSegment {
  final int start;
  final int end;
  final HighlightType type;

  const HighlightSegment({
    required this.start,
    required this.end,
    required this.type,
  });

  @override
  String toString() => 'HighlightSegment($start-$end: $type)';
}

/// Types of highlighting for command text.
enum HighlightType {
  command, // Blue (e.g., "create", "move", "comment")
  keyword, // Blue (e.g., "on", "in", "to")
  ticket, // Green
  project, // Purple
  column, // Orange
  content, // Orange (comment content after ":")
}
