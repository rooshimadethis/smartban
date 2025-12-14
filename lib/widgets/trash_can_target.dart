import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/providers/kanban_state.dart';

class TrashCanTarget extends StatelessWidget {
  const TrashCanTarget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KanbanState>(
      builder: (context, state, child) {
        if (!state.isDragging) return const SizedBox.shrink();

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            _showDeleteConfirmation(context, details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 80,
              margin: const EdgeInsets.only(bottom: 20),
              width: isHovering ? 80 : 60,
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : const Color(
                        0xFF1E1E1E,
                      ), // Match background to hide inside
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHovering ? Colors.redAccent : Colors.grey,
                  width: 2,
                ),
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                Icons.delete_outline,
                color: isHovering ? Colors.redAccent : Colors.grey,
                size: isHovering ? 40 : 32,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String ticketId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Delete Ticket?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this ticket? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<KanbanState>().deleteTicket(ticketId);
    }
  }
}
