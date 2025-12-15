import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/services/suggestion/command_strategy.dart';
import 'package:smartban/services/suggestion/strategies/move_strategy.dart';
import 'package:smartban/services/suggestion/strategies/comment_strategy.dart';
import 'package:smartban/services/suggestion/strategies/create_ticket_strategy.dart';
import 'package:smartban/services/suggestion/suggestion_mixin.dart';
import 'package:smartban/services/suggestion/highlight_segment.dart';

class SuggestionService with SuggestionMixin {
  final KanbanState kanbanState;
  final List<CommandStrategy> _strategies = [
    MoveCommandStrategy(),
    CommentCommandStrategy(),
    CreateTicketCommandStrategy(),
  ];

  SuggestionService(this.kanbanState);

  List<String> getSuggestions(String input) {
    if (input.trim().isEmpty) return [];

    final List<String> suggestions = [];

    // 1. Ask strategies
    for (final strategy in _strategies) {
      if (strategy.matches(input)) {
        suggestions.addAll(strategy.getSuggestions(input, kanbanState));
      }
    }

    // 2. If we found strategy-specific suggestions, return them
    if (suggestions.isNotEmpty) {
      // Deduplicate and return
      return suggestions.toSet().toList();
    }

    // 3. Fallback: Generic initial commands if nothing matched specifically
    // (e.g., user is typing "mo" -> suggest "move ")
    // We can use the strategies' keywords for this.
    final keywords = _strategies.map((s) => s.commandKeyword).toList();
    // Use the mixin's findMatches directly here
    final matches = findMatches(input, keywords);

    // Append a space to generic command suggestions for better UX
    return matches.map((m) => "$m ").take(3).toList();
  }

  /// Returns highlighting information for the input text.
  List<HighlightSegment> getHighlights(String input) {
    if (input.trim().isEmpty) return [];

    // Find matching strategy and get highlights
    for (final strategy in _strategies) {
      if (strategy.matches(input)) {
        return strategy.getHighlights(input, kanbanState);
      }
    }

    return []; // No highlights if no strategy matches
  }
}
