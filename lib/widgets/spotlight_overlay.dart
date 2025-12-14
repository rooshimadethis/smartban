import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/services/nlp_service.dart';
import 'package:smartban/services/spotlight_service.dart';

import 'package:flutter/services.dart';
import 'package:smartban/services/suggestion_service.dart';

class SpotlightOverlay extends StatefulWidget {
  final Widget child;

  const SpotlightOverlay({super.key, required this.child});

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> {
  final FocusNode _focusNode = FocusNode();
  late final SpotlightTextController _controller;
  List<String> _suggestions = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = SpotlightTextController();
    SpotlightService().isVisible.addListener(_onVisibilityChanged);
  }

  @override
  void dispose() {
    SpotlightService().isVisible.removeListener(_onVisibilityChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (SpotlightService().isVisible.value) {
      // Request focus when shown
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    } else {
      // Clear focus when hidden
      _focusNode.unfocus();
      _controller.clear();
      setState(() {
        _suggestions = [];
        _selectedIndex = 0;
      });
    }
    setState(() {});
  }

  void _acceptSuggestion(String suggestion) {
    String textToInsert = suggestion;
    if (!textToInsert.endsWith(" ")) {
      textToInsert += " ";
    }
    _controller.text = textToInsert;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() {
      _suggestions = [];
      _selectedIndex = 0;
    });
    // Re-trigger suggestions for new text?
    final kanbanState = Provider.of<KanbanState>(context, listen: false);
    final service = SuggestionService(kanbanState);
    setState(() {
      _suggestions = service.getSuggestions(_controller.text);
      _selectedIndex = 0; // Reset to top
    });
  }

  Future<void> _submit(String value) async {
    if (value.trim().isEmpty) return;

    final kanbanState = Provider.of<KanbanState>(context, listen: false);
    final nlpService = NLPService(kanbanState);
    final messenger = ScaffoldMessenger.of(context);

    final result = await nlpService.process(value);

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.message,
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        backgroundColor: const Color(0xFF333333),
        duration: const Duration(seconds: 10),
        action: result.undoAction != null
            ? SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: result.undoAction!,
              )
            : null,
      ),
    );

    SpotlightService().hide();
  }

  @override
  Widget build(BuildContext context) {
    final kanbanState = Provider.of<KanbanState>(context);
    _controller.updateData(
      kanbanState.tickets.map((t) => t.title).toList(),
      kanbanState.projects.map((p) => p.name).toList(),
    );
    return Stack(
      children: [
        widget.child,
        if (SpotlightService().isVisible.value)
          Positioned.fill(
            child: Material(
              color: Colors.black54, // Dim background
              child: GestureDetector(
                onTap: () {
                  SpotlightService().hide();
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: GestureDetector(
                    onTap:
                        () {}, // Prevent tap from closing when clicking on input
                    child: Container(
                      width: 600,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 28,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CallbackShortcuts(
                                    bindings: {
                                      const SingleActivator(
                                        LogicalKeyboardKey.tab,
                                      ): () {
                                        if (_suggestions.isNotEmpty) {
                                          _acceptSuggestion(
                                            _suggestions[_selectedIndex],
                                          );
                                        }
                                      },
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowDown,
                                      ): () {
                                        if (_suggestions.isNotEmpty) {
                                          setState(() {
                                            _selectedIndex =
                                                (_selectedIndex + 1).clamp(
                                                  0,
                                                  _suggestions.length - 1,
                                                );
                                          });
                                        }
                                      },
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowUp,
                                      ): () {
                                        if (_suggestions.isNotEmpty) {
                                          setState(() {
                                            _selectedIndex =
                                                (_selectedIndex - 1).clamp(
                                                  0,
                                                  _suggestions.length - 1,
                                                );
                                          });
                                        }
                                      },
                                      const SingleActivator(
                                        LogicalKeyboardKey.enter,
                                      ): () {
                                        if (_suggestions.isNotEmpty &&
                                            _selectedIndex > 0) {
                                          _acceptSuggestion(
                                            _suggestions[_selectedIndex],
                                          );
                                        } else {
                                          _submit(_controller.text);
                                        }
                                      },
                                      const SingleActivator(
                                        LogicalKeyboardKey.escape,
                                      ): () {
                                        SpotlightService().hide();
                                      },
                                    },
                                    child: TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      style: const TextStyle(fontSize: 20),
                                      decoration: const InputDecoration(
                                        hintText: 'Search or create ticket...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) {
                                        final kanbanState =
                                            Provider.of<KanbanState>(
                                              context,
                                              listen: false,
                                            );
                                        final service = SuggestionService(
                                          kanbanState,
                                        );
                                        setState(() {
                                          _suggestions = service.getSuggestions(
                                            value,
                                          );
                                          _selectedIndex = 0;
                                        });
                                      },
                                      onSubmitted: (value) {
                                        // Handled by CallbackShortcuts for Enter, but failsafe
                                        if (!(_suggestions.isNotEmpty &&
                                            _selectedIndex > 0)) {
                                          _submit(value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_suggestions.isNotEmpty) ...[
                            // List of suggestions
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final isSelected = index == _selectedIndex;
                                  final suggestion = _suggestions[index];
                                  final lowerSuggestion = suggestion
                                      .toLowerCase();

                                  // Determine color based on type
                                  Color highlightColor = Theme.of(
                                    context,
                                  ).primaryColor; // Default
                                  if (lowerSuggestion.startsWith('move')) {
                                    highlightColor = Colors.blueAccent;
                                  } else if (lowerSuggestion.startsWith(
                                    'comment',
                                  )) {
                                    highlightColor = Colors.blueAccent;
                                  } else if (lowerSuggestion.startsWith(
                                    'create',
                                  )) {
                                    highlightColor = Colors.blueAccent;
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      _acceptSuggestion(_suggestions[index]);
                                      _focusNode.requestFocus();
                                    },
                                    child: Container(
                                      color: isSelected
                                          ? highlightColor.withValues(
                                              alpha: 0.2,
                                            )
                                          : null,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 56.0,
                                        vertical: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            suggestion,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? highlightColor
                                                  : Colors.white70,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const Spacer(),
                                            Text(
                                              "Press Tab",
                                              style: TextStyle(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.5,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          // Placeholder for results
                          const Divider(height: 1),
                          Container(
                            height: 200, // Placeholder height for results
                            alignment: Alignment.center,
                            child: const Text(
                              "Recent Tickets / Results will appear here",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SpotlightTextController extends TextEditingController {
  List<String> tickets = [];
  List<String> projects = [];
  final List<String> commands = ['Create', 'Move', 'Comment on'];

  void updateData(List<String> currentTickets, List<String> currentProjects) {
    if (listEquals(tickets, currentTickets) &&
        listEquals(projects, currentProjects)) {
      return;
    }
    tickets = List.from(currentTickets);
    projects = List.from(currentProjects);
    // Don't notify here to avoid build loops, the data is updated for the next buildTextSpan call.
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final String text = this.text;
    final String lowerText = text.toLowerCase();

    // Styles
    final commandStyle = style?.copyWith(
      color: Colors.blueAccent,
      fontWeight: FontWeight.bold,
    );
    // Use slightly different greens/purples to be distinct
    final ticketStyle = style?.copyWith(
      color: Colors.greenAccent,
      fontWeight: FontWeight.bold,
    );
    final projectStyle = style?.copyWith(
      color: Colors.purpleAccent,
      fontWeight: FontWeight.bold,
    );
    final commentStyle = style?.copyWith(color: Colors.orangeAccent);

    // Special handling for "Comment on <Ticket>: <Content>"
    if (lowerText.startsWith("comment on ")) {
      // Highlight "Comment"
      children.add(TextSpan(text: text.substring(0, 7), style: commandStyle));

      String remaining = text.substring(7);
      // " on " - highlight as command style
      if (remaining.toLowerCase().startsWith(" on ")) {
        children.add(
          TextSpan(text: remaining.substring(0, 4), style: commandStyle),
        );
        remaining = remaining.substring(4);

        // Look for ticket
        String? matchedTicket;
        for (final ticket in tickets) {
          // Case insensitive match
          if (remaining.toLowerCase().startsWith(ticket.toLowerCase())) {
            matchedTicket = remaining.substring(0, ticket.length);
            break;
          }
        }

        if (matchedTicket != null) {
          children.add(TextSpan(text: matchedTicket, style: ticketStyle));
          remaining = remaining.substring(matchedTicket.length);

          // Look for colon
          int colonIndex = remaining.indexOf(':');
          if (colonIndex != -1) {
            // Text before colon (including it?)
            children.add(
              TextSpan(
                text: remaining.substring(0, colonIndex + 1),
                style: style,
              ),
            );
            // Text after colon is comment content
            String commentContent = remaining.substring(colonIndex + 1);
            if (commentContent.isNotEmpty) {
              children.add(TextSpan(text: commentContent, style: commentStyle));
            }
            return TextSpan(style: style, children: children);
          } else {
            // No colon yet
            children.add(TextSpan(text: remaining, style: style));
            return TextSpan(style: style, children: children);
          }
        } else {
          // Fall through or just return what we have?
          children.add(TextSpan(text: remaining, style: style));
          return TextSpan(style: style, children: children);
        }
      }
    }

    // Generic Algorithm
    String temp = text;

    while (temp.isNotEmpty) {
      int bestMatchIndex = -1;
      String? bestMatchText;
      TextStyle? bestMatchStyle;

      // 1. Check for Command
      for (final cmd in commands) {
        int idx = temp.toLowerCase().indexOf(cmd.toLowerCase());
        if (idx != -1) {
          if (bestMatchIndex == -1 || idx < bestMatchIndex) {
            bestMatchIndex = idx;
            bestMatchText = temp.substring(idx, idx + cmd.length);
            bestMatchStyle = commandStyle;
          }
        }
      }

      // 2. Tickets
      for (final t in tickets) {
        int idx = temp.toLowerCase().indexOf(t.toLowerCase());
        if (idx != -1) {
          if (bestMatchIndex == -1 || idx < bestMatchIndex) {
            bestMatchIndex = idx;
            bestMatchText = temp.substring(idx, idx + t.length);
            bestMatchStyle = ticketStyle;
          }
        }
      }

      // 3. Projects
      for (final p in projects) {
        int idx = temp.toLowerCase().indexOf(p.toLowerCase());
        if (idx != -1) {
          if (bestMatchIndex == -1 || idx < bestMatchIndex) {
            bestMatchIndex = idx;
            bestMatchText = temp.substring(idx, idx + p.length);
            bestMatchStyle = projectStyle;
          }
        }
      }

      if (bestMatchIndex != -1) {
        // Add text before match
        if (bestMatchIndex > 0) {
          children.add(
            TextSpan(text: temp.substring(0, bestMatchIndex), style: style),
          );
        }
        // Add match
        children.add(TextSpan(text: bestMatchText, style: bestMatchStyle));
        // Advance
        temp = temp.substring(bestMatchIndex + bestMatchText!.length);
      } else {
        // No more matches
        children.add(TextSpan(text: temp, style: style));
        break;
      }
    }

    return TextSpan(style: style, children: children);
  }
}
