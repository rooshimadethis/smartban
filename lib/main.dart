import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/screens/kanban_screen.dart';
import 'package:smartban/services/spotlight_service.dart';
import 'package:smartban/widgets/spotlight_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Spotlight Service (handles hotkeys and window manager)
  await SpotlightService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => KanbanState())],
      child: MaterialApp(
        title: 'SmartBan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display', // System font for Mac matches well
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF282828),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blueAccent,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          cardColor: const Color(0xFF2C2C2C),
        ),
        // Wrap the home screen with SpotlightOverlay
        home: const SpotlightOverlay(child: KanbanScreen()),
      ),
    );
  }
}
