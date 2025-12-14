import 'dart:ui';
import 'package:smartban/models/project.dart';
import 'package:smartban/models/ticket.dart';

class MockData {
  static const List<Project> projects = [
    Project(id: 'p1', name: 'Mobile App Redesign', color: Color(0xFF6C63FF)),
    Project(id: 'p2', name: 'Backend API Migration', color: Color(0xFFFF6584)),
    Project(id: 'p3', name: 'Marketing Campaign', color: Color(0xFF32C766)),
  ];

  static const List<Ticket> tickets = [
    Ticket(
      id: 't1',
      title: 'Design Home Screen',
      description: 'Create high-fidelity mockups for the new home screen.',
      status: TicketStatus.todo,
      projectId: 'p1',
      comments: ['Needs larger icons', 'Check contrast ratio'],
    ),
    Ticket(
      id: 't2',
      title: 'Setup CI/CD Pipeline',
      description: 'Configure GitHub Actions for automated testing.',
      status: TicketStatus.todo,
      projectId: 'p2',
    ),
    Ticket(
      id: 't3',
      title: 'API Authentication',
      description: 'Implement JWT based auth.',
      status: TicketStatus.inProgress,
      projectId: 'p2',
      comments: ['Use RSA 256'],
    ),
    Ticket(
      id: 't4',
      title: 'Social Media Assets',
      description: 'Create banners for Twitter and LinkedIn.',
      status: TicketStatus.done,
      projectId: 'p3',
    ),
    Ticket(
      id: 't5',
      title: 'User Profile Page',
      description: 'Design and implement the user profile view.',
      status: TicketStatus.inProgress,
      projectId: 'p1',
    ),
    Ticket(
      id: 't6',
      title: 'Database Schema',
      description: 'Define the initial schema for Postgres.',
      status: TicketStatus.done,
      projectId: 'p2',
    ),
  ];
}
