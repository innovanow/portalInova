import 'package:flutter/material.dart';
import 'package:inova/telas/home.dart';
import 'package:inova/telas/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'cadastros/reset_senha.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Supabase.initialize(
    url: 'https://yswfyjsijwggwjfimjkw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlzd2Z5anNpandnZ3dqZmltamt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4ODU2MDcsImV4cCI6MjA1NzQ2MTYwN30.ySVw-yFF7G9Zzavp9wNwWGWqJqyV_WjTR83HOriSp2w',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
      authFlowType: AuthFlowType.pkce, // 👈 Necessário para web
    ),
  );
  final session = Supabase.instance.client.auth.currentSession;
  final bool sessionRestaurada = session != null;

  runApp(MyApp(sessionRestaurada: sessionRestaurada));
}

class MyApp extends StatelessWidget {
  final bool sessionRestaurada;

  const MyApp({super.key, required this.sessionRestaurada});

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
      debugShowCheckedModeBanner: false,
      initialRoute: sessionRestaurada ? '/home' : '/login',
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginScreen(),
        '/home': (BuildContext context) => const Home(),
        '/validar-token': (context) => const VerificarTokenScreen(),
      },
    );
  }
}