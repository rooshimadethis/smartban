import 'package:flutter/material.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/project.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final Project? project;

  const TicketCard({super.key, required this.ticket, this.project});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: ticket.id,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context),
      ),
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project != null)
            Padding(
               padding: const EdgeInsets.only(bottom: 4),
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: project!.color.withValues(alpha: 0.2),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   project!.name,
                   style: TextStyle(fontSize: 10, color: project!.color, fontWeight: FontWeight.bold),
                 ),
               ),
            ),
            Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(ticket.description, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
