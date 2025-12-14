import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/models/ticket.dart';
import 'package:smartban/models/project.dart';
import 'package:smartban/providers/kanban_state.dart';

class TicketCard extends StatefulWidget {
  final Ticket ticket;
  final Project? project;

  const TicketCard({super.key, required this.ticket, this.project});

  @override
  State<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<TicketCard> {
  bool _isEditing = false;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.ticket.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_descriptionController.text != widget.ticket.description) {
      context.read<KanbanState>().updateTicketDescription(
        widget.ticket.id,
        _descriptionController.text,
      );
    }
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync controller if ticket changes externally and we are not editing
    if (!_isEditing &&
        _descriptionController.text != widget.ticket.description) {
      _descriptionController.text = widget.ticket.description;
    }

    return LongPressDraggable<String>(
      data: widget.ticket.id,
      feedback: Material(
        elevation: 6,
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.ticket.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context),
      ),
      onDragStarted: () {
        context.read<KanbanState>().setDragging(true);
      },
      onDragEnd: (_) {
        context.read<KanbanState>().setDragging(false);
      },
      child: _buildCardContent(context),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isEditing) {
          setState(() {
            _isEditing = true;
          });
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 2,
        color: const Color(0xFF2C2C2C), // Dark card background
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white10, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.project != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.project!.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.project!.color.withValues(alpha: 0.3),
                      ), // Subtle border for project tag
                    ),
                    child: Text(
                      widget.project!.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.project!.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Text(
                widget.ticket.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      autofocus: true,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _save(),
                      onTapOutside: (_) => _save(),
                    )
                  : Text(
                      widget.ticket.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
