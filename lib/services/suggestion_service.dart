import 'package:smartban/providers/kanban_state.dart';
import 'package:string_similarity/string_similarity.dart';

class SuggestionService {
  final KanbanState kanbanState;

  SuggestionService(this.kanbanState);

  List<String> getSuggestions(String input) {
    if (input.trim().isEmpty) return [];

    final lowerInput = input.toLowerCase();

    // 2. Context-aware suggestions
    // MOVE
    if (lowerInput.startsWith('move ')) {
      final remainder = input.substring(5); // "Move " is 5 chars

      // If we have "Move <ticket> to ", suggest status
      if (lowerInput.contains(' to ')) {
        final parts = lowerInput.split(' to ');
        if (parts.length > 1) {
          final statusPart = parts.last;
          final statusCandidates = ['Todo', 'In Progress', 'Done'];

          if (statusPart.trim().isEmpty) {
            return statusCandidates.map((s) => "$input$s").take(3).toList();
          }

          final bestStatuses = _findCandidates(statusPart, statusCandidates);

          if (bestStatuses.isNotEmpty) {
            final prefix = input.substring(
              0,
              input.toLowerCase().lastIndexOf(statusPart.toLowerCase()),
            );
            return bestStatuses.map((s) => "$prefix$s").take(3).toList();
          }
        }
      } else {
        // Suggesting tickets
        if (kanbanState.tickets.isNotEmpty) {
          final ticketTitles = kanbanState.tickets.map((t) => t.title).toList();
          final bestTickets = _findCandidates(remainder, ticketTitles);
          return bestTickets.map((t) => "Move $t").take(3).toList();
        }
      }
    }

    // COMMENT
    if (lowerInput.startsWith('comment on ')) {
      final remainder = input.substring(11); // "Comment on "
      if (kanbanState.tickets.isNotEmpty) {
        final ticketTitles = kanbanState.tickets.map((t) => t.title).toList();
        final bestTickets = _findCandidates(remainder, ticketTitles);
        return bestTickets.map((t) => "Comment on $t: ").take(3).toList();
      }
    } else if (lowerInput.startsWith('comment ')) {
      return ["Comment on "];
    }

    // 3. Generic Command Fallback
    const commands = ['Create', 'Move', 'Comment on'];
    final bestCommands = _findCandidates(lowerInput, commands);
    return bestCommands.take(3).toList();
  }

  List<String> _findCandidates(String input, List<String> candidates) {
    if (input.isEmpty) return [];
    final lowerInput = input.toLowerCase();

    // 1. Filter and Score
    var matches = candidates
        .map((c) {
          double score = 0.0;
          final lowerC = c.toLowerCase();

          if (lowerC.startsWith(lowerInput)) {
            score += 1.0; // High priority for prefix match
            // Penalty for length difference to prefer shorter precise matches?
            // Actually, maybe generic string similarity is better for the rest
          } else {
            score = StringSimilarity.compareTwoStrings(lowerInput, lowerC);
          }
          return MapEntry(c, score);
        })
        .where((entry) => entry.value > 0.0)
        .toList(); // Basic filtering

    // 2. Sort
    matches.sort((a, b) => b.value.compareTo(a.value));

    // 3. Return candidates (thresholding could apply)
    // Filter out very low quality matches if not prefix
    return matches
        .where((entry) => entry.value > 0.2) // slightly loose threshold
        .map((e) => e.key)
        .toList();
  }
}
