import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

class SpotlightService {
  static final SpotlightService _instance = SpotlightService._internal();

  factory SpotlightService() {
    return _instance;
  }

  SpotlightService._internal();

  final ValueNotifier<bool> isVisible = ValueNotifier(false);

  Future<void> initialize() async {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();

    // Option + Space
    HotKey hotKey = HotKey(
      key: LogicalKeyboardKey.space,
      modifiers: [HotKeyModifier.alt],
      scope: HotKeyScope.system, // Make it global
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        toggleSpotlight();
      },
    );
  }

  void toggleSpotlight() async {
    // If not visible, show it and bring to front
    // Use windowManager to bring app to front

    // We can also just make sure the app is visible
    if (!isVisible.value) {
      await windowManager.show();
      await windowManager.focus();
      isVisible.value = true;
    } else {
      // Logic to hide? Or maybe just hide overlay?
      // For now, let's toggle visibility of the overlay.
      // If the app is already focused, we might want to close the spotlight.
      isVisible.value = false;
    }
  }

  void show() async {
    await windowManager.show();
    await windowManager.focus();
    isVisible.value = true;
  }

  void hide() {
    isVisible.value = false;
  }
}
