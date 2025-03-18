import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inova/telas/login.dart';


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

  @override
  void initState() {
    super.initState();

    // Controlador da pulsação da logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    // Iniciar animação do texto (máquina de escrever)
    _iniciarAnimacaoTexto();
    // Timer para redirecionar para a próxima tela após 4 segundos
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  void _iniciarAnimacaoTexto() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_indexLetra < widget.title.length) {
        setState(() {
          _textoExibido = widget.title.substring(0, _indexLetra + 1);
          _indexLetra++;
        });
      } else {
        // Pausa antes de resetar
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _textoExibido = "";
            _indexLetra = 0;
          });
          _iniciarAnimacaoTexto(); // Reinicia a animação
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
    return Scaffold(
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
    );
  }
}
