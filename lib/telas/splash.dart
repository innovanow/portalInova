import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'home.dart';
import 'login.dart'; // 🔁 Certifique-se que está importando corretamente

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

    _iniciarSplashComTempoMinimo();
  }

  Future<void> _iniciarSplashComTempoMinimo() async {
    final authService = AuthService();
    final prefs = await SharedPreferences.getInstance();
    final lembrarDados = prefs.getBool('lembrar_dados') ?? false;

    // Garante tempo mínimo de 3 segundos para splash + tempo da verificação da sessão
    final resultados = await Future.wait([
      authService.restoreSessionAndLogin(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted || _redirecionado) return;

    final restaurou = resultados[0] as bool;
    _redirecionado = true;

    if (restaurou && lembrarDados == true) {
      if (kDebugMode) print('✅ Sessão restaurada com sucesso. Indo para Home...');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const Home()));
    } else {
      if (kDebugMode) print('🔒 Nenhuma sessão ativa. Indo para Login...');
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                        "assets/logoInova.svg",
                        fit: BoxFit.contain,
                        width: 200,
                    ),
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
