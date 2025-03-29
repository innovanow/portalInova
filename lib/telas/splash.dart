import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.title});
  final String title;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _textoExibido = "";
  int _indexLetra = 0;
  late Timer _timer;
  StreamSubscription<AuthState>? _authSubscription;
  bool _redirecionado = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _iniciarAnimacaoTexto();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted || _redirecionado) return;

      final session = data.session;
      if (kDebugMode) print('📡 onAuthStateChange chamado');

      _redirecionado = true;

      if (session != null) {
        if (kDebugMode) print('✅ Sessão ativa detectada. Indo para Home...');
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (kDebugMode) print('🔒 Sem sessão. Indo para Login...');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _redirecionado) return;

      final session = Supabase.instance.client.auth.currentSession;
      _redirecionado = true;

      if (session != null) {
        if (kDebugMode) print('⚠️ Timeout: sessão ainda ativa. Indo para Home...');
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        if (kDebugMode) print('⚠️ Timeout: sem sessão. Indo para Login...');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }

  void _iniciarAnimacaoTexto() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;
      if (_indexLetra < widget.title.length) {
        setState(() {
          _textoExibido = widget.title.substring(0, _indexLetra + 1);
          _indexLetra++;
        });
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _textoExibido = "";
            _indexLetra = 0;
          });
          _iniciarAnimacaoTexto();
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image: AssetImage("assets/fundo.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _controller,
              child: SizedBox(
                height: 180,
                width: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _textoExibido,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'FuturaBold',
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Color(0xFF0A63AC),
                      ),
                    ),
                    Image.asset("assets/logo.png", fit: BoxFit.contain),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
