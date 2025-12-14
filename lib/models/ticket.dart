enum TicketStatus { todo, inProgress, done }

class Ticket {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final String projectId;

  final List<String> comments;

  const Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.projectId,
    this.comments = const [],
  });

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    TicketStatus? status,
    String? projectId,
    List<String>? comments,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'projectId': projectId,
      'comments': comments,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: TicketStatus.values.byName(json['status']),
      projectId: json['projectId'],
      comments: (json['comments'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
