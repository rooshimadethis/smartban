import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';

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
}
