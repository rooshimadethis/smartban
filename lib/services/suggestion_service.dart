import 'package:smartban/providers/kanban_state.dart';
import 'package:string_similarity/string_similarity.dart';

class SuggestionService {
  final KanbanState kanbanState;

  SuggestionService(this.kanbanState);

  String? getSuggestion(String input) {
    if (input.trim().isEmpty) return null;

    final lowerInput = input.toLowerCase();

    // 1. Check for Commands
    const commands = ['Create', 'Move', 'Comment'];
    String? bestCommand = _findBestCandidate(lowerInput, commands);
    if (bestCommand != null && input.length < 4) {
      // Only suggest early for commands since they are short
      return bestCommand;
    }

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

          if (statusPart.trim().isEmpty) return "$input${statusCandidates[0]}";

          String? bestStatus = _findBestCandidate(statusPart, statusCandidates);

          if (bestStatus != null) {
            final prefix = input.substring(
              0,
              input.toLowerCase().lastIndexOf(statusPart.toLowerCase()),
            );
            return "$prefix$bestStatus";
          }
        }
      } else {
        // Suggesting tickets
        // Check if user is typing " to"
        if ("to".startsWith(remainder.toLowerCase()) &&
            remainder.isNotEmpty &&
            remainder.length < 3) {
          // Wait, if they are typing "to", they probably finished the ticket name?
          // Actually, if they type "Move Fi to", "Fi" matches ticket.
        }

        if (kanbanState.tickets.isNotEmpty) {
          final ticketTitles = kanbanState.tickets.map((t) => t.title).toList();
          String? bestTicket = _findBestCandidate(remainder, ticketTitles);

          if (bestTicket != null) {
            return "Move $bestTicket";
          }
        }
      }
    }

    // COMMENT
    if (lowerInput.startsWith('comment ')) {
      if (lowerInput.startsWith('comment on ')) {
        final remainder = input.substring(11); // "Comment on "
        if (kanbanState.tickets.isNotEmpty) {
          final ticketTitles = kanbanState.tickets.map((t) => t.title).toList();
          String? bestTicket = _findBestCandidate(remainder, ticketTitles);
          if (bestTicket != null) {
            return "Comment on $bestTicket: ";
          }
        }
      } else {
        return "Comment on ";
      }
    }

    return null;
  }

  String? _findBestCandidate(String input, List<String> candidates) {
    if (input.isEmpty) return null;
    final lowerInput = input.toLowerCase();

    // 1. Starts With (Case Insensitive)
    for (var candidate in candidates) {
      if (candidate.toLowerCase().startsWith(lowerInput)) {
        return candidate;
      }
    }

    // 2. Fuzzy Match
    final match = StringSimilarity.findBestMatch(input, candidates);
    if (match.bestMatch.rating != null && match.bestMatch.rating! > 0.4) {
      return match.bestMatch.target;
    }

    return null;
  }
}
