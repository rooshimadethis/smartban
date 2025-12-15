import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';
import '../highlight_segment.dart';

class MoveCommandStrategy extends CommandStrategy with SuggestionMixin {
  @override
  String get commandKeyword => 'move';

  @override
  bool matches(String input) {
    return input.toLowerCase().startsWith('move ') ||
        'move'.startsWith(input.toLowerCase());
  }

  @override
  List<String> getSuggestions(String input, KanbanState state) {
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('move ')) {
      return ['$commandKeyword '];
    }

    final remainder = input.substring(5); // "move " is 5 chars

    // Check if we are at the "to" stage
    int toIndex = lowerInput.lastIndexOf(' to ');

    if (toIndex != -1) {
      // We have the " to " part. Now suggesting columns.
      final prefix = input.substring(0, toIndex + 4); // include " to "
      final query = input.substring(toIndex + 4);

      final matches = findColumnMatches(query);
      return matches.map((m) => "$prefix$m").take(3).toList();
    } else {
      // We are suggesting tickets OR the "to" keyword.
      // We find ticket candidates that start with or match the remainder
      final matches = findTicketMatches(remainder, state.tickets);

      // If we have matches, create suggestions: "move <TicketName> to "
      return matches.map((m) => "move $m to ").take(3).toList();
    }
  }

  @override
  List<HighlightSegment> getHighlights(String input, KanbanState state) {
    final List<HighlightSegment> segments = [];
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('move ')) {
      return segments;
    }

    // Highlight "move" as command
    segments.add(
      const HighlightSegment(start: 0, end: 4, type: HighlightType.command),
    );

    final remainder = input.substring(5);
    int toIndex = lowerInput.lastIndexOf(' to ');

    if (toIndex != -1) {
      // We have " to " - highlight ticket, "to", and possibly column
      final ticketPart = input.substring(5, toIndex);

      // Try to match ticket name
      final ticketMatches = findTicketMatches(ticketPart.trim(), state.tickets);
      if (ticketMatches.isNotEmpty) {
        // Highlight the ticket
        segments.add(
          HighlightSegment(start: 5, end: toIndex, type: HighlightType.ticket),
        );
      }

      // Highlight " to "
      segments.add(
        HighlightSegment(
          start: toIndex + 1,
          end: toIndex + 4,
          type: HighlightType.keyword,
        ),
      );

      // Check for column after "to"
      if (toIndex + 4 < input.length) {
        final columnPart = input.substring(toIndex + 4).trim();
        final columnMatches = findColumnMatches(columnPart);
        if (columnMatches.isNotEmpty) {
          // Find actual position of column text (skip spaces)
          int columnStart = toIndex + 4;
          while (columnStart < input.length && input[columnStart] == ' ') {
            columnStart++;
          }
          segments.add(
            HighlightSegment(
              start: columnStart,
              end: input.length,
              type: HighlightType.column,
            ),
          );
        }
      }
    } else {
      // No "to" yet - try to highlight ticket name
      final ticketMatches = findTicketMatches(remainder.trim(), state.tickets);
      if (ticketMatches.isNotEmpty && remainder.trim().isNotEmpty) {
        segments.add(
          HighlightSegment(
            start: 5,
            end: input.length,
            type: HighlightType.ticket,
          ),
        );
      }
    }

    return segments;
  }
}
