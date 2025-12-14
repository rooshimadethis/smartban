import 'package:petitparser/petitparser.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:uuid/uuid.dart';

abstract class Command {}

class MoveTicketCommand extends Command {
  final String ticketQuery;
  final TicketStatus targetStatus;
  MoveTicketCommand(this.ticketQuery, this.targetStatus);
}

class CommentCommand extends Command {
  final String ticketQuery;
  final String comment;
  CommentCommand(this.ticketQuery, this.comment);
}

class CreateTicketCommand extends Command {
  final String title;
  CreateTicketCommand(this.title);
}

class NLPService {
  final KanbanState kanbanState;

  NLPService(this.kanbanState);

  Parser buildParser() {
    final move = string('move', ignoreCase: true).trim().token();
    final to = string('to', ignoreCase: true).trim().token();
    final comment = string('comment', ignoreCase: true).trim().token();
    final on = string('on', ignoreCase: true).trim().token();
    final create = string('create', ignoreCase: true).trim().token();

    // Status parsers
    final statusTodo =
        (string('todo', ignoreCase: true) | string('to do', ignoreCase: true))
            .map((_) => TicketStatus.todo);
    final statusInProgress =
        (string('in progress', ignoreCase: true) |
                string('inprogress', ignoreCase: true) |
                string('doing', ignoreCase: true))
            .map((_) => TicketStatus.inProgress);
    final statusDone =
        (string('done', ignoreCase: true) |
                string('finished', ignoreCase: true) |
                string('complete', ignoreCase: true))
            .map((_) => TicketStatus.done);
    final statusParser = (statusTodo | statusInProgress | statusDone).trim();

    // Generic string parser for ticket query (everything until 'to' or end)
    // This is tricky with simple parsers. Easier to define specific structures.

    // MOVE COMMAND: "Move <anything> to <status>"
    final moveCommand =
        (move & any().plusLazy(to).flatten() & to & statusParser).map((values) {
          return MoveTicketCommand(
            values[1] as String,
            values[3] as TicketStatus,
          );
        });

    // COMMENT COMMAND: "Comment on <anything>: <text>" or "Comment <text> on <anything>"
    // Let's stick to "Comment on <ticket>: <text>" for simplicity first

    // "Comment on <ticket query> : <comment>"
    final commentOn =
        (comment &
                on &
                any().plusLazy(char(':')).flatten() &
                char(':').trim() &
                any().star().flatten())
            .map((values) {
              return CommentCommand(values[2] as String, values[4] as String);
            });

    // CREATE COMMAND: "Create <title>"
    final createCommand = (create & any().star().flatten()).map((values) {
      return CreateTicketCommand(values[1] as String);
    });

    // FALLBACK / IMPLICIT CREATE: Just text
    final implicitCreate = any().star().flatten().map((value) {
      return CreateTicketCommand(value);
    });

    return moveCommand | commentOn | createCommand | implicitCreate;
  }

  Future<String> process(String input) async {
    final parser = buildParser();
    final result = parser.parse(input);

    if (result is Success) {
      final command = result.value;
      return await _execute(command);
    } else {
      return "Could not understand command.";
    }
  }

  Future<String> _execute(Command command) async {
    if (command is MoveTicketCommand) {
      final ticket = _findTicket(command.ticketQuery);
      if (ticket == null) {
        return "Ticket not found for '${command.ticketQuery}'";
      }
      kanbanState.updateTicketStatus(ticket.id, command.targetStatus);
      return "Moved '${ticket.title}' to ${command.targetStatus.name}";
    } else if (command is CommentCommand) {
      final ticket = _findTicket(command.ticketQuery);
      if (ticket == null) {
        return "Ticket not found for '${command.ticketQuery}'";
      }
      kanbanState.addComment(ticket.id, command.comment);
      return "Added comment to '${ticket.title}'";
    } else if (command is CreateTicketCommand) {
      if (command.title.trim().isEmpty) return "Please enter a title.";

      // Default to first project for now
      final projectId = kanbanState.projects.isNotEmpty
          ? kanbanState.projects.first.id
          : 'default';

      final newTicket = Ticket(
        id: const Uuid().v4(),
        title: command.title.trim(),
        description: '',
        status: TicketStatus.todo,
        projectId: projectId,
        comments: [],
      );
      kanbanState.addTicket(newTicket);
      return "Created ticket '${newTicket.title}'";
    }
    return "Unknown command";
  }

  Ticket? _findTicket(String query) {
    if (kanbanState.tickets.isEmpty) return null;

    final queryLower = query.trim().toLowerCase();

    // 1. Exact ID match (not common for user input but good to have)
    try {
      return kanbanState.tickets.firstWhere((t) => t.id == query);
    } catch (_) {}

    // 2. Exact Title Match
    try {
      return kanbanState.tickets.firstWhere(
        (t) => t.title.toLowerCase() == queryLower,
      );
    } catch (_) {}

    // 3. Fuzzy Match using StringSimilarity
    Ticket? bestMatch;
    double bestScore = 0.0;

    for (var ticket in kanbanState.tickets) {
      final score = ticket.title.toLowerCase().similarityTo(queryLower);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = ticket;
      }
    }

    // Threshold for fuzzy match
    if (bestScore > 0.4) {
      return bestMatch;
    }

    return null;
  }
}
