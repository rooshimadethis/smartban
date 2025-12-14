import 'package:smartban/providers/kanban_state.dart';
import '../command_strategy.dart';
import '../suggestion_mixin.dart';

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
}
