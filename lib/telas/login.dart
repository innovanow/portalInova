import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (error == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Home()));
      } else {
        setState(() => _errorMessage = error);
      }
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Login",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FuturaBold',
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Color(0xFF0A63AC),
                ),
              ),
              SizedBox(
                  width: 250,
                  height: 80,
                  child: Image.asset("assets/logo.png", fit: BoxFit.contain)
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LayoutBuilder(
                    builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth > 800 ?  MediaQuery.of(context).size.width / 2 :  MediaQuery.of(context).size.width,
                      child: Card.filled(
                        color: const Color(0xFF0A63AC),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: "E-mail",
                                    labelStyle: const TextStyle(color: Colors.white),
                                    hoverColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white), // Borda branca quando não está focado
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white, width: 2.0), // Borda branca mais espessa ao focar
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.red), // Borda vermelha quando há erro
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.red, width: 2.0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white), // Texto branco
                                  validator: (value) => value!.isEmpty ? "Digite seu e-mail" : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: "Senha",
                                    labelStyle: const TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white), // Borda branca quando não está focado
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.white, width: 2.0), // Borda branca mais espessa ao focar
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.red), // Borda vermelha quando há erro
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.red, width: 2.0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white), // Texto branco
                                  validator: (value) => value!.isEmpty ? "Digite sua senha" : null,
                                ),
                                const SizedBox(height: 10),
                                if (_errorMessage != null)
                                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 20),
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange, // Define a cor laranja do botão
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero, // Deixa as bordas quadradas
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), // Ajusta o tamanho do botão
                                    elevation: 0, // Remove a elevação (sombra)
                                  ),
                                  child: const Text(
                                    "Entrar",
                                    style: TextStyle(color: Colors.white), // Mantém o texto branco para contraste
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
