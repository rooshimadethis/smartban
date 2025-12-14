import 'package:smartban/providers/kanban_state.dart';

abstract class CommandStrategy {
  /// The command prefix this strategy handles (e.g., "move", "comment").
  String get commandKeyword;

  /// Returns true if this strategy matches the input (fuzzy/prefix).
  bool matches(String input);

  /// Generates suggestions based on the input.
  List<String> getSuggestions(String input, KanbanState state);
}
