import 'package:flutter/material.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282828),
      appBar: AppBar(
        title: const Text(
          'SmartBan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF282828),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blueAccent),
            onPressed: () {
              // TODO: Add ticket creation
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KanbanColumn(status: TicketStatus.todo),
            KanbanColumn(status: TicketStatus.inProgress),
            KanbanColumn(status: TicketStatus.done),
          ],
        ),
      ),
    );
  }
}
