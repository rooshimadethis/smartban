import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/widgets/ticket_card.dart';

class KanbanColumn extends StatelessWidget {
  final TicketStatus status;

  const KanbanColumn({super.key, required this.status});

  String get _title {
    switch (status) {
      case TicketStatus.todo:
        return 'To Do';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.done:
        return 'Done';
    }
  }

  Color get _headerColor {
    switch (status) {
      case TicketStatus.todo:
        return Colors.blueGrey;
      case TicketStatus.inProgress:
        return Colors.orangeAccent;
      case TicketStatus.done:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Darker column background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _headerColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: _headerColor),
                  const SizedBox(width: 8),
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _headerColor.withValues(
                        alpha: 0.8,
                      ), // Darker text for contrast
                    ),
                  ),
                ],
              ),
            ),

            // Drop Zone
            Expanded(
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) {
                  final ticketId = details.data;
                  context.read<KanbanState>().updateTicketStatus(
                    ticketId,
                    status,
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  return Consumer<KanbanState>(
                    builder: (context, kanbanState, child) {
                      return ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          ...kanbanState.projects.map((project) {
                            final tickets = kanbanState
                                .getTicketsByStatusAndProject(
                                  status,
                                  project.id,
                                );

                            if (tickets.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.folder_open,
                                        size: 14,
                                        color: project.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        project.name,
                                        style: TextStyle(
                                          color: project.color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...tickets.map(
                                  (ticket) => TicketCard(
                                    ticket: ticket,
                                    project: project,
                                  ),
                                ),
                              ],
                            );
                          }),

                          // Visual cue when dragging over
                          if (candidateData.isNotEmpty)
                            Container(
                              height: 60,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _headerColor,
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: _headerColor.withValues(alpha: 0.05),
                              ),
                              child: Center(
                                child: Text(
                                  'Drop here',
                                  style: TextStyle(color: _headerColor),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
