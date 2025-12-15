import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';
import '../highlight_segment.dart';

class CreateTicketCommandStrategy extends CommandStrategy with SuggestionMixin {
  @override
  String get commandKeyword => 'create ticket';

  @override
  bool matches(String input) {
    final lowerInput = input.toLowerCase();
    // Handle "create" prefix, "create ticket" prefix
    return lowerInput.startsWith('create ') || 'create'.startsWith(lowerInput);
  }

  @override
  List<String> getSuggestions(String input, KanbanState state) {
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('create ')) {
      return ['create ticket '];
    }

    // Ensure "ticket" is there
    if (!lowerInput.startsWith('create ticket ')) {
      // Check if 'create ticket' starts with what they typed
      if ('create ticket '.startsWith(lowerInput)) {
        return ['create ticket '];
      }
      return ['create ticket '];
    }

    // Input is "create ticket ..."
    final remainder = input.substring(14); // "create ticket " is 14

    // Check for " in "
    int inIndex = lowerInput.lastIndexOf(' in ');

    if (inIndex != -1) {
      // Suggesting projects
      final prefix = input.substring(0, inIndex + 4);
      final query = input.substring(inIndex + 4);

      final matches = findProjectMatches(query, state.projects);

      return matches.map((m) => "$prefix$m").take(3).toList();
    } else {
      // We are identifying the name.
      // If remainder is not empty, suggest adding " in "
      if (remainder.trim().isNotEmpty) {
        return ["$input in "];
      }
      return [];
    }
  }

  @override
  List<HighlightSegment> getHighlights(String input, KanbanState state) {
    final List<HighlightSegment> segments = [];
    final lowerInput = input.toLowerCase();

    if (!lowerInput.startsWith('create ')) {
      return segments;
    }

    // Highlight "create" as command
    segments.add(
      const HighlightSegment(start: 0, end: 6, type: HighlightType.command),
    );

    if (!lowerInput.startsWith('create ticket ')) {
      return segments;
    }

    // Highlight "ticket" as command
    segments.add(
      const HighlightSegment(start: 7, end: 13, type: HighlightType.command),
    );

    // Check for " in "
    int inIndex = lowerInput.lastIndexOf(' in ');

    if (inIndex != -1) {
      // Highlight " in " as keyword
      segments.add(
        HighlightSegment(
          start: inIndex + 1,
          end: inIndex + 3,
          type: HighlightType.keyword,
        ),
      );

      // Check for project after "in"
      if (inIndex + 4 < input.length) {
        final projectPart = input.substring(inIndex + 4).trim();
        final projectMatches = findProjectMatches(projectPart, state.projects);

        if (projectMatches.isNotEmpty) {
          // Find actual start of project (skip spaces)
          int projectStart = inIndex + 4;
          while (projectStart < input.length && input[projectStart] == ' ') {
            projectStart++;
          }

          segments.add(
            HighlightSegment(
              start: projectStart,
              end: input.length,
              type: HighlightType.project,
            ),
          );
        }
      }
    }
    // Note: We don't highlight the ticket name itself (between "ticket" and "in")
    // as it's user-provided text, not a reference to an existing entity

    return segments;
  }
}
