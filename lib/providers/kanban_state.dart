import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartban/models/project.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/mock_data.dart';

class KanbanState extends ChangeNotifier {
  List<Project> _projects = [];
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  KanbanState() {
    _loadData();
  }

  List<Project> get projects => _projects;
  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool _isDragging = false;
  bool get isDragging => _isDragging;

  String? _selectedProjectId;
  String? get selectedProjectId => _selectedProjectId;

  final Set<String> _hiddenProjectIds = {};
  Set<String> get hiddenProjectIds => _hiddenProjectIds;

  List<Project> get visibleProjects {
    if (_selectedProjectId != null) {
      return _projects.where((p) => p.id == _selectedProjectId).toList();
    }
    return _projects.where((p) => !_hiddenProjectIds.contains(p.id)).toList();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final projectsString = prefs.getString('projects');
    if (projectsString != null) {
      final List<dynamic> decoded = jsonDecode(projectsString);
      _projects = decoded.map((item) => Project.fromJson(item)).toList();
    } else {
      _projects = List.from(MockData.projects);
    }

    final ticketsString = prefs.getString('tickets');
    if (ticketsString != null) {
      final List<dynamic> decoded = jsonDecode(ticketsString);
      _tickets = decoded.map((item) => Ticket.fromJson(item)).toList();
    } else {
      _tickets = List.from(MockData.tickets);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final projectsJson = jsonEncode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString('projects', projectsJson);

    final ticketsJson = jsonEncode(_tickets.map((t) => t.toJson()).toList());
    await prefs.setString('tickets', ticketsJson);
  }

  // ... existing methods ...

  void selectProject(String? projectId) {
    if (_selectedProjectId == projectId) {
      _selectedProjectId = null;
    } else {
      _selectedProjectId = projectId;
    }
    notifyListeners();
  }

  void toggleProjectVisibility(String projectId) {
    if (_hiddenProjectIds.contains(projectId)) {
      _hiddenProjectIds.remove(projectId);
    } else {
      _hiddenProjectIds.add(projectId);
      // If we hide the currently selected project, deselect it
      if (_selectedProjectId == projectId) {
        _selectedProjectId = null;
      }
    }
    notifyListeners();
  }

  List<Ticket> getTicketsByStatusAndProject(
    TicketStatus status,
    String projectId,
  ) {
    return _tickets
        .where((t) => t.status == status && t.projectId == projectId)
        .toList();
  }

  void updateTicketStatus(String ticketId, TicketStatus newStatus) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(status: newStatus);
      _saveData();
      notifyListeners();
    }
  }

  void updateTicketDescription(String ticketId, String newDescription) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(description: newDescription);
      _saveData();
      notifyListeners();
    }
  }

  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    _saveData();
    notifyListeners();
  }

  void addComment(String ticketId, String comment) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      final currentComments = List<String>.from(_tickets[index].comments);
      currentComments.add(comment);
      _tickets[index] = _tickets[index].copyWith(comments: currentComments);
      _saveData();
      notifyListeners();
    }
  }

  void updateTicketComments(String ticketId, List<String> comments) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index != -1) {
      _tickets[index] = _tickets[index].copyWith(comments: comments);
      _saveData();
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

  void deleteTicket(String ticketId) {
    _tickets.removeWhere((t) => t.id == ticketId);
    _saveData();
    notifyListeners();
  }

  void setDragging(bool isDragging) {
    _isDragging = isDragging;
    notifyListeners();
  }

  void deleteProject(String projectId) {
    // Remove the project
    _projects.removeWhere((p) => p.id == projectId);

    // Remove all tickets associated with the project
    _tickets.removeWhere((t) => t.projectId == projectId);

    // Clean up selection and hidden state
    if (_selectedProjectId == projectId) {
      _selectedProjectId = null;
    }
    _hiddenProjectIds.remove(projectId);

    _saveData();
    notifyListeners();
  }
}
