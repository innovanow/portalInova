import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _newPasswordController = TextEditingController();
  final _tokenController = TextEditingController();
  final _confirmPasswordResetController = TextEditingController();
  bool tokenEnviado = false;
  String? _errorMessage;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  bool lembrarDados = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // 🔹 Carrega email e senha salvos ao iniciar
  }

  /// 🔹 **Carrega email e senha salvos**
  Future<void> _loadSavedCredentials() async {
    final credentials = await _authService.getSavedCredentials();
    if (kDebugMode) {
      print('🔍 Carregando credenciais: ${credentials['email']} / ${credentials['password']}');
    }
    if (!mounted) return;
    setState(() {
      _emailController.text = credentials['email'] ?? '';
      _passwordController.text = credentials['password'] ?? '';
      lembrarDados = credentials['lembrarDados'] == 'true';
    });
  }


  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        lembrarDados,
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

  /// Metodo para abrir o pop-up de redefinição de senha
  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool localTokenEnviado = false;
        bool localCarregando = false;
        String? localErro;
        String? localSucesso;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A63AC),
              title: const Text(
                "Redefinir Senha",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Digite seu e-mail para receber o código de redefinição:",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white, width: 2.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (localTokenEnviado) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _tokenController,
                        decoration: InputDecoration(
                          labelText: "Token",
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white, width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Nova senha",
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white, width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordResetController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirmar senha",
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white, width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (localErro != null)
                      SelectableText(localErro!, style: const TextStyle(color: Colors.red)),
                    if (localSucesso != null)
                      Text(localSucesso!, style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.orange)),
                ),
                if (!localTokenEnviado)
                  localCarregando
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                        height: 20,
                        width: 20,child: CircularProgressIndicator(color: Colors.orange)),
                  )
                      : TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) return;

                      setState(() {
                        localCarregando = true;
                        localErro = null;
                      });

                      final erro = await _authService.enviarCodigoDeRecuperacao(email);

                      setState(() {
                        localCarregando = false;
                      });

                      if (erro == null) {
                        setState(() {
                          localTokenEnviado = true;
                          localSucesso = "Token enviado por e-mail!";
                        });
                      } else {
                        setState(() {
                          localErro = "Erro: $erro";
                        });
                      }
                    },
                    child: const Text("Enviar código", style: TextStyle(color: Colors.orange)),
                  ),
                if (localTokenEnviado)
                  localCarregando
                      ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.orange)),
                  )
                      : TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final token = _tokenController.text.trim();
                      final senha = _newPasswordController.text;
                      final confirmar = _confirmPasswordResetController.text;

                      if (senha != confirmar) {
                        setState(() {
                          localErro = "As senhas não coincidem.";
                        });
                        return;
                      }

                      setState(() {
                        localCarregando = true;
                        localErro = null;
                        localSucesso = null;
                      });

                      try {
                        final response = await Supabase.instance.client.auth.verifyOTP(
                          type: OtpType.recovery,
                          email: email,
                          token: token,
                        );

                        if (response.session == null) {
                          setState(() {
                            localErro = 'Código inválido ou expirado.';
                            localCarregando = false;
                          });
                          return;
                        }

                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: senha),
                        );

                        setState(() {
                          localSucesso = 'Senha atualizada com sucesso!';
                          localTokenEnviado = false;
                          _emailController.clear();
                          _tokenController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordResetController.clear();
                        });
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        setState(() {
                          localErro = 'Erro: ${e.toString()}';
                        });
                      }

                      setState(() {
                        localCarregando = false;
                      });
                    },
                    child: const Text("Redefinir senha", style: TextStyle(color: Colors.orange)),
                  ),
              ],
            );
          },
        );
      },
    );
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
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  child: SizedBox(
                      height: 80,
                      child: SvgPicture.asset("assets/logoInova.svg")
                  ),
                ),
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            SizedBox(
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
                                          SelectableText(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                spacing: 5,
                                                children: [
                                                  SizedBox(
                                                    height: 24.0,
                                                    width: 24.0,
                                                    child: Transform.scale(
                                                      scale: 0.9,
                                                      child: Checkbox(
                                                        value: lembrarDados, // Variável booleana para controlar o estado do checkbox
                                                        onChanged: (bool? value) {
                                                          setState(() {
                                                            lembrarDados = value ?? false; // Atualiza o estado ao clicar no checkbox
                                                          });
                                                        },
                                                        splashRadius: 0, // Remove o efeito de splash ao clicar
                                                        overlayColor: WidgetStateProperty.all(Colors.transparent),
                                                        checkColor: Colors.white,
                                                        activeColor: Colors.orange,
                                                        side: BorderSide(color: Colors.white, width: 2.0), // Define a cor e a espessura do contorno
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Lembrar dados',
                                                    style: TextStyle(fontSize: 14,
                                                        color: Colors.white), // Estiliza o texto, se necessário
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton(
                                          style: ButtonStyle(
                                            overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                          ),
                                          onPressed: _showResetPasswordDialog,
                                          child: const Text(
                                            "Esqueceu a senha?",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            TextButton(
                                style: ButtonStyle(
                                  overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                ),
                                onPressed: () async {
                                  await _authService.clearCredentials();

                                  // Opcional: limpar os campos da tela
                                  setState(() {
                                    _emailController.clear();
                                    _passwordController.clear();
                                  });
                                  if(context.mounted){
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Credenciais apagadas com sucesso.",
                                            style: TextStyle(
                                              color: Colors.white,
                                            )),
                                        backgroundColor: Color(0xFF0A63AC),
                                      ),
                                    );
                                  }
                                },
                                child: const Text("Limpar Dados",
                                  style: TextStyle(color: Color(0xFF0A63AC)),)
                            ),
                            Text("Versão: 0.22",
                              style: TextStyle(color: Color(0xFF0A63AC)),)
                          ],
                        );
                      }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}