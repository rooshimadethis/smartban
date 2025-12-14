import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartban/services/suggestion_service.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/project.dart';

// Fake KanbanState
class FakeKanbanState extends KanbanState {
  final List<Ticket> _tickets = [];

  @override
  List<Ticket> get tickets => _tickets;

  @override
  List<Project> get projects => [];

  FakeKanbanState() : super();

  void addTestTicket(Ticket t) {
    _tickets.add(t);
  }
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SuggestionService suggests commands', () {
    final state = FakeKanbanState();
    final service = SuggestionService(state);

    expect(service.getSuggestion('Cre'), 'Create');
    expect(service.getSuggestion('Mov'), 'Move');
    expect(service.getSuggestion('Com'), 'Comment');
  });

  test('SuggestionService suggests ticket for Move', () {
    final state = FakeKanbanState();
    state.addTestTicket(
      const Ticket(
        id: '1',
        title: 'Fix Login Bug',
        description: '',
        status: TicketStatus.todo,
        projectId: 'p1',
      ),
    );

    final service = SuggestionService(state);

    // "Move F" -> "Move Fix Login Bug"
    expect(service.getSuggestion('Move F'), 'Move Fix Login Bug');
  });

  test('SuggestionService suggests status for Move', () {
    final state = FakeKanbanState();
    final service = SuggestionService(state);

    // "Move something to T" -> "Move something to Todo"
    expect(
      service.getSuggestion('Move Fix Login Bug to T'),
      'Move Fix Login Bug to Todo',
    );
    expect(service.getSuggestion('Move X to I'), 'Move X to In Progress');
  });
}
