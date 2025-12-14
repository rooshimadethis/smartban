import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';

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
}
