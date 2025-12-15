import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/services/nlp_service.dart';
import 'package:smartban/services/spotlight_service.dart';

import 'package:flutter/services.dart';
import 'package:smartban/services/suggestion_service.dart';
import 'package:smartban/services/suggestion/highlight_segment.dart';

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

  Widget _buildCommandItem(BuildContext context, String title, String syntax) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            syntax,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kanbanState = Provider.of<KanbanState>(context);
    _controller.updateData(
      kanbanState.tickets.map((t) => t.title).toList(),
      kanbanState.projects.map((p) => p.name).toList(),
    );
    _controller.setKanbanState(kanbanState);
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
                                  child: Focus(
                                    onKeyEvent: (node, event) {
                                      // Handle key down and key repeat events (for holding keys)
                                      if (event is! KeyDownEvent &&
                                          event is! KeyRepeatEvent) {
                                        return KeyEventResult.ignored;
                                      }

                                      // Handle backspace for smart word deletion
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.backspace) {
                                        final wordToDelete = _controller
                                            .findWordToDelete();
                                        if (wordToDelete != null) {
                                          final cursorPos =
                                              _controller.selection.baseOffset;
                                          int deleteLength =
                                              wordToDelete.length;

                                          // Check if there's a trailing space after the word
                                          // (cursor would be after the space from tab completion)
                                          if (cursorPos > 0 &&
                                              _controller.text[cursorPos - 1] ==
                                                  ' ') {
                                            deleteLength +=
                                                1; // Also delete the trailing space
                                          }

                                          // Delete from (cursorPos - deleteLength) to cursorPos
                                          final newText =
                                              _controller.text.substring(
                                                0,
                                                cursorPos - deleteLength,
                                              ) +
                                              _controller.text.substring(
                                                cursorPos,
                                              );
                                          _controller.text = newText;
                                          _controller.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset:
                                                      cursorPos - deleteLength,
                                                ),
                                              );

                                          // Update suggestions
                                          final kanbanState =
                                              Provider.of<KanbanState>(
                                                context,
                                                listen: false,
                                              );
                                          final service = SuggestionService(
                                            kanbanState,
                                          );
                                          setState(() {
                                            _suggestions = service
                                                .getSuggestions(
                                                  _controller.text,
                                                );
                                            _selectedIndex = 0;
                                          });
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult
                                            .ignored; // Let default backspace work
                                      }

                                      return KeyEventResult.ignored;
                                    },
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
                                          hintText:
                                              'Search or create ticket...',
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
                                            _suggestions = service
                                                .getSuggestions(value);
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
                          // Command Reference
                          const Divider(height: 1),
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Command Reference",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCommandItem(
                                    context,
                                    "Create ticket",
                                    "create ticket <name> in <project>",
                                  ),
                                  _buildCommandItem(
                                    context,
                                    "Comment on ticket",
                                    "comment on <ticket>: <content>",
                                  ),
                                  _buildCommandItem(
                                    context,
                                    "Move ticket",
                                    "move <ticket> to <column>",
                                  ),
                                  const SizedBox(height: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Coming soon: create project, delete, rename, show",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
  KanbanState? _kanbanState;
  final List<String> commands = ['Create', 'Move', 'Comment on'];
  final List<String> columns = ['Todo', 'In Progress', 'Done'];

  void updateData(List<String> currentTickets, List<String> currentProjects) {
    if (listEquals(tickets, currentTickets) &&
        listEquals(projects, currentProjects)) {
      return;
    }
    tickets = List.from(currentTickets);
    projects = List.from(currentProjects);
    // Don't notify here to avoid build loops, the data is updated for the next buildTextSpan call.
  }

  void setKanbanState(KanbanState state) {
    _kanbanState = state;
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

  /// Find if cursor is at the end of a highlighted word (command, ticket, project, column)
  /// Returns the word to delete, or null if not at end of a highlighted word
  String? findWordToDelete() {
    final cursorPos = selection.baseOffset;
    if (cursorPos <= 0) return null;

    final textBeforeCursor = text.substring(0, cursorPos);
    final lowerTextBeforeCursor = textBeforeCursor.toLowerCase();

    // Check all possible highlighted words
    final allWords = [
      ...commands,
      ...tickets,
      ...projects,
      ...columns,
      'on', // Special case for "on" in commands
    ];

    for (final word in allWords) {
      // Case 1: Cursor directly after the word (e.g., "create|")
      if (lowerTextBeforeCursor.endsWith(word.toLowerCase())) {
        // Make sure we're actually at the end of this word
        // (not in the middle of a longer word)
        final startPos = cursorPos - word.length;
        if (startPos == 0 || text[startPos - 1] == ' ') {
          return text.substring(startPos, cursorPos);
        }
      }

      // Case 2: Cursor after word + space (e.g., "create |")
      if (lowerTextBeforeCursor.endsWith('${word.toLowerCase()} ')) {
        // Make sure we're actually at the end of this word + space
        final startPos = cursorPos - word.length - 1;
        if (startPos == 0 || text[startPos - 1] == ' ') {
          return text.substring(
            startPos,
            cursorPos - 1,
          ); // Return just the word, not the space
        }
      }
    }

    return null;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_kanbanState == null) {
      // Fallback to plain text if no state available
      return TextSpan(text: text, style: style);
    }

    // Get highlights from SuggestionService
    final service = SuggestionService(_kanbanState!);
    final highlights = service.getHighlights(text);

    if (highlights.isEmpty) {
      // No highlights, return plain text
      return TextSpan(text: text, style: style);
    }

    // Define styles for each highlight type
    final commandStyle = style?.copyWith(
      color: Colors.blueAccent,
      fontWeight: FontWeight.bold,
    );
    final ticketStyle = style?.copyWith(
      color: Colors.greenAccent,
      fontWeight: FontWeight.bold,
    );
    final projectStyle = style?.copyWith(
      color: Colors.purpleAccent,
      fontWeight: FontWeight.bold,
    );
    final columnStyle = style?.copyWith(
      color: Colors.orangeAccent,
      fontWeight: FontWeight.bold,
    );
    final contentStyle = style?.copyWith(color: Colors.orangeAccent);

    // Build TextSpan children from highlights
    final List<InlineSpan> children = [];
    int currentPos = 0;

    // Sort highlights by start position
    final sortedHighlights = List<HighlightSegment>.from(highlights)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final highlight in sortedHighlights) {
      // Add unhighlighted text before this highlight
      if (currentPos < highlight.start) {
        children.add(
          TextSpan(
            text: text.substring(currentPos, highlight.start),
            style: style,
          ),
        );
      }

      // Add highlighted text
      TextStyle? highlightStyle;
      switch (highlight.type) {
        case HighlightType.command:
        case HighlightType.keyword:
          highlightStyle = commandStyle;
          break;
        case HighlightType.ticket:
          highlightStyle = ticketStyle;
          break;
        case HighlightType.project:
          highlightStyle = projectStyle;
          break;
        case HighlightType.column:
          highlightStyle = columnStyle;
          break;
        case HighlightType.content:
          highlightStyle = contentStyle;
          break;
      }

      children.add(
        TextSpan(
          text: text.substring(highlight.start, highlight.end),
          style: highlightStyle,
        ),
      );

      currentPos = highlight.end;
    }

    // Add any remaining unhighlighted text
    if (currentPos < text.length) {
      children.add(TextSpan(text: text.substring(currentPos), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
