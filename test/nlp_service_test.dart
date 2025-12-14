import 'package:smartban/services/nlp_service.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/project.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:petitparser/petitparser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Fake KanbanState
class FakeKanbanState extends KanbanState {
  @override
  List<Ticket> get tickets => [];
  @override
  List<Project> get projects => [];
  @override
  void addTicket(Ticket ticket) {}

  FakeKanbanState() : super();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  test('Parser parses create command', () {
    final service = NLPService(FakeKanbanState());
    final parser = service.buildParser();
    final result = parser.parse('Create Check Login');
    expect(result is Success, true);
    expect(result.value is CreateTicketCommand, true);
    expect((result.value as CreateTicketCommand).title, 'Check Login');
  });

  test('Parser parses implicit create', () {
    final service = NLPService(FakeKanbanState());
    final parser = service.buildParser();
    final result = parser.parse('Just a simple task');
    expect(result is Success, true);
    expect(result.value is CreateTicketCommand, true);
    expect((result.value as CreateTicketCommand).title, 'Just a simple task');
  });

  test('Parser parses move command', () {
    final service = NLPService(FakeKanbanState());
    final parser = service.buildParser();
    final result = parser.parse('Move bug 123 to done');
    expect(result is Success, true);
    expect(result.value is MoveTicketCommand, true);
    expect((result.value as MoveTicketCommand).ticketQuery, 'bug 123');
    expect((result.value as MoveTicketCommand).targetStatus, TicketStatus.done);
  });
}
