import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';
import '../highlight_segment.dart';

class CommentCommandStrategy extends CommandStrategy with SuggestionMixin {
  @override
  String get commandKeyword => 'comment';

  @override
  bool matches(String input) {
    return input.toLowerCase().startsWith('comment ') ||
        'comment'.startsWith(input.toLowerCase());
  }

  @override
  List<String> getSuggestions(String input, KanbanState state) {
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('comment ')) {
      return ['$commandKeyword on '];
    }

    // Ensure "on" is there
    if (!lowerInput.startsWith('comment on ')) {
      return ['comment on '];
    }

    // Input is "comment on ..."
    String remainder = input.substring(11); // "comment on " is 11

    // We are suggesting tickets.
    // If ticket is found, we append ":"
    final matches = findTicketMatches(remainder, state.tickets);

    return matches.map((m) => "comment on $m: ").take(3).toList();
  }

  @override
  List<HighlightSegment> getHighlights(String input, KanbanState state) {
    final List<HighlightSegment> segments = [];
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('comment ')) {
      return segments;
    }

    // Highlight "comment" as command
    segments.add(
      const HighlightSegment(start: 0, end: 7, type: HighlightType.command),
    );

    if (!lowerInput.startsWith('comment on ')) {
      return segments;
    }

    // Highlight " on " as keyword
    segments.add(
      const HighlightSegment(start: 8, end: 10, type: HighlightType.keyword),
    );

    // Look for colon to separate ticket from content
    int colonIndex = input.indexOf(':');

    if (colonIndex != -1) {
      // Highlight ticket name (between "on " and ":")
      final ticketPart = input.substring(11, colonIndex).trim();
      final ticketMatches = findTicketMatches(ticketPart, state.tickets);

      if (ticketMatches.isNotEmpty) {
        // Find actual start of ticket (skip spaces after "on ")
        int ticketStart = 11;
        while (ticketStart < colonIndex && input[ticketStart] == ' ') {
          ticketStart++;
        }

        segments.add(
          HighlightSegment(
            start: ticketStart,
            end: colonIndex,
            type: HighlightType.ticket,
          ),
        );
      }

      // Highlight content after colon
      if (colonIndex + 1 < input.length) {
        segments.add(
          HighlightSegment(
            start: colonIndex + 1,
            end: input.length,
            type: HighlightType.content,
          ),
        );
      }
    } else {
      // No colon yet - try to highlight ticket name
      final remainder = input.substring(11).trim();
      final ticketMatches = findTicketMatches(remainder, state.tickets);

      if (ticketMatches.isNotEmpty && remainder.isNotEmpty) {
        int ticketStart = 11;
        while (ticketStart < input.length && input[ticketStart] == ' ') {
          ticketStart++;
        }

        segments.add(
          HighlightSegment(
            start: ticketStart,
            end: input.length,
            type: HighlightType.ticket,
          ),
        );
      }
    }

    return segments;
  }
}
