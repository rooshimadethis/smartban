import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/models/project.dart';
import 'package:smartban/providers/kanban_state.dart';

class ProjectList extends StatelessWidget {
  const ProjectList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Projects',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Consumer<KanbanState>(
              builder: (context, state, child) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.projects.length,
                  itemBuilder: (context, index) {
                    final project = state.projects[index];
                    return _ProjectListItem(
                      key: ValueKey(project.id),
                      project: project,
                      isSelected: state.selectedProjectId == project.id,
                      isHidden: state.hiddenProjectIds.contains(project.id),
                      onTap: () => state.selectProject(project.id),
                      onToggleVisibility: () =>
                          state.toggleProjectVisibility(project.id),
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2C2C2C),
                            title: const Text(
                              'Delete Project?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'This will delete "${project.name}" and all its tickets. This action cannot be undone.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  state.deleteProject(project.id);
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListItem extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final bool isHidden;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleVisibility;

  const _ProjectListItem({
    super.key,
    required this.project,
    required this.isSelected,
    required this.isHidden,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleVisibility,
  });

  @override
  State<_ProjectListItem> createState() => _ProjectListItemState();
}

class _ProjectListItemState extends State<_ProjectListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.project.color.withValues(alpha: 0.2)
                : (_isHovered
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: widget.project.color.withValues(alpha: 0.5))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: widget.project.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.project.name,
                          style: TextStyle(
                            color: widget.isHidden
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white,
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration: widget.isHidden
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: widget.isHidden
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: widget.onToggleVisibility,
                tooltip: widget.isHidden ? 'Show project' : 'Hide project',
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
