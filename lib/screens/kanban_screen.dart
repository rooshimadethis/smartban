import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/widgets/kanban_column.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1E1E1E,
      ), // Dark background matching column container
      appBar: AppBar(
        title: const Text(
          'SmartBan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
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
      body: Consumer<KanbanState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KanbanColumn(status: TicketStatus.todo),
                KanbanColumn(status: TicketStatus.inProgress),
                KanbanColumn(status: TicketStatus.done),
              ],
            ),
          );
        },
      ),
    );
  }
}
