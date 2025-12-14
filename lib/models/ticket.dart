enum TicketStatus { todo, inProgress, done }

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final String projectId;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.projectId,
  });
  
  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    String? projectId,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
    );
  }
}
