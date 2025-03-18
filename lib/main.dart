import 'package:flutter/material.dart';
import 'package:inova/cadastros/register_jovem.dart';
import 'package:inova/cadastros/register_modulo.dart';
import 'package:inova/cadastros/register_professor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cadastros/register_turma.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yswfyjsijwggwjfimjkw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlzd2Z5anNpandnZ3dqZmltamt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4ODU2MDcsImV4cCI6MjA1NzQ2MTYwN30.ySVw-yFF7G9Zzavp9wNwWGWqJqyV_WjTR83HOriSp2w',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Instituto Inova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          accentColor: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: const TurmaScreen(),
      //home: const SplashScreen(title: 'Portal',),
      debugShowCheckedModeBanner: false,
    );
  }
}