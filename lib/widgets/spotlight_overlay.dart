import 'package:flutter/material.dart';
import 'package:smartban/services/spotlight_service.dart';

class SpotlightOverlay extends StatefulWidget {
  final Widget child;

  const SpotlightOverlay({super.key, required this.child});

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    style: const TextStyle(fontSize: 20),
                                    decoration: const InputDecoration(
                                      hintText: 'Search or create ticket...',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onSubmitted: (value) {
                                      // TODO: Implement search/create logic
                                      print("Submitted: $value");
                                      SpotlightService().hide();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
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
