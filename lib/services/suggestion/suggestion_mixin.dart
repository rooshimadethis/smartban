import 'package:string_similarity/string_similarity.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/project.dart';

mixin SuggestionMixin {
  /// Core fuzzy matching logic
  List<String> findMatches(String query, List<String> candidates) {
    if (query.isEmpty) return candidates;
    final lowerQuery = query.toLowerCase();

    var matches = candidates.map((c) {
      final lowerC = c.toLowerCase();
      double score = 0.0;

      if (lowerC.startsWith(lowerQuery)) {
        score = 100.0;
      } else if (lowerC.contains(lowerQuery)) {
        score = 50.0;
      } else {
        score = StringSimilarity.compareTwoStrings(lowerQuery, lowerC);
      }
      return MapEntry(c, score);
    }).toList();

    // Filter out low scores
    matches = matches.where((e) => e.value > 0.1).toList();

    matches.sort((a, b) => b.value.compareTo(a.value));

    return matches.map((e) => e.key).toList();
  }

  /// Helper to find ticket matches
  List<String> findTicketMatches(String query, List<Ticket> tickets) {
    final titles = tickets.map((t) => t.title).toList();
    return findMatches(query, titles);
  }

  /// Helper to find project matches
  List<String> findProjectMatches(String query, List<Project> projects) {
    final names = projects.map((p) => p.name).toList();
    return findMatches(query, names);
  }

  /// Helper to find column matches
  List<String> findColumnMatches(String query, [List<String>? customColumns]) {
    final columns = customColumns ?? ['Todo', 'In Progress', 'Done'];
    return findMatches(query, columns);
  }
}
