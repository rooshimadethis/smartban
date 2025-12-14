import 'package:flutter/foundation.dart';
import 'package:smartban/models/project.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/mock_data.dart';

class KanbanState extends ChangeNotifier {
  final List<Project> _projects = List.from(MockData.projects);
  final List<Ticket> _tickets = List.from(MockData.tickets);

  List<Project> get projects => _projects;
  List<Ticket> get tickets => _tickets;

  List<Ticket> getTicketsByStatusAndProject(TicketStatus status, String projectId) {
    return _tickets.where((t) => t.status == status && t.projectId == projectId).toList();
  }
  
  void updateTicketStatus(String ticketId, TicketStatus newStatus) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if(index != -1) {
      _tickets[index] = _tickets[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
