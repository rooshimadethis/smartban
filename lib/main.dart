import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartban/providers/kanban_state.dart';
import 'package:smartban/screens/kanban_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KanbanState()),
      ],
      child: MaterialApp(
        title: 'SmartBan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Using a modern, clean theme
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display', // System font for Mac matches well
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const KanbanScreen(),
      ),
    );
  }
}
