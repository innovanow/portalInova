import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/jovem_service.dart';
import '../widgets/widgets.dart';
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
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Carrega email e senha salvos**
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

  void _abrirFormulario({Map<String, dynamic>? jovem}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Inscrição:",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'LeagueSpartan',
                ),
              ),
              IconButton(
                tooltip: "Fechar",
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                enableFeedback: false,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: _Formjovem(
            jovem: jovem,
            onjovemSalva: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
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
        if (error.contains("invalid_credentials")) {
          setState(() {
            _errorMessage = "Credenciais inválidas!";
          });
        } else if (error.contains("email_not_confirmed")) {
          setState(() {
            _errorMessage = "E-mail ainda não confirmado. Verifique sua caixa de entrada.";
          });
        } else if (error.contains("user_not_found")) {
          setState(() {
            _errorMessage = "Usuário não encontrado.";
          });
        } else if (error.contains("unauthorized")) {
          setState(() {
            _errorMessage = "Acesso não autorizado.";
          });
        } else if (error.contains("invalid_email")) {
          setState(() {
            _errorMessage = "E-mail inválido.";
          });
        } else if (error.contains("invalid_password")) {
          setState(() {
            _errorMessage = "Senha inválida.";
          });
        } else if (error.contains("network_error")) {
          setState(() {
            _errorMessage = "Erro de conexão. Verifique sua internet.";
          });
        } else {
          setState(() {
            _errorMessage = "Erro desconhecido: $error";
          });
        }
      }
    }
  }

  /// Metodo para abrir o pop-up de redefinição de senha
  void _showResetPasswordDialog() {
    showDialog(
      barrierDismissible: false,
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
                      keyboardType: TextInputType.emailAddress,
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
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.orange,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 15,
                      )
                  ),
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
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                    ),
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
                    child: const Text("Enviar código",
                        style: TextStyle(color: Colors.orange,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 15,
                        )),
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
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                    ),
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
                    child: const Text("Redefinir senha",
                        style: TextStyle(color: Colors.orange,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 15,
                        )
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A63AC),
              title: const Text(
                "Excluir Minha Conta",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Digite seu e-mail e senha para excluir sua conta\nEsta ação é irreversível.",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      _emailController, true,
                      "E-mail",
                      isEmail: true,
                      onChangedState: () => setState(() {}),
                    ),
                    buildTextField(
                      _passwordController, true,
                      "Senha",
                      isPassword: true,
                      onChangedState: () => setState(() {}),
                    ),
                    if (isDeleting) const CircularProgressIndicator(color: Colors.orange),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancelar",
                      style: TextStyle(color: Colors.orange,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 15,
                      )
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  onPressed: isDeleting ? null : () async {
                    setState(() {
                      isDeleting = true;
                    });

                    // Chama a função de exclusão
                    await _deleteUser(dialogContext, _emailController.text.trim(), _passwordController.text.trim()); // Não precisa de email/senha

                    if(mounted) {
                      setState(() {
                        isDeleting = false;
                      });
                    }
                  },
                  child: Text(
                    isDeleting ? "Excluindo..." : "Excluir",
                    style: TextStyle(
                      color: isDeleting ? Colors.grey : Colors.redAccent,
                      fontFamily: 'LeagueSpartan',
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(
      BuildContext context,
      String email,
      String password,
      ) async {
    final supabase = Supabase.instance.client;

    // --- Passo 1: Reautenticar para garantir que a sessão é recente ---
    try {
      // Isso atualiza a sessão interna do Supabase SDK
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Credenciais inválidas. Não foi possível reautenticar: ${e.message}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0A63AC),
          ),
        );
      }
      return;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao reautenticar: $e');
      }
      return;
    }

    // --- Passo 2: Chamar o RPC para exclusão ---
    try {
      await supabase.rpc('delete_user_rpc');

      // 1. Logout local (o RPC já encerrou a sessão no DB, mas é bom limpar localmente)
      await supabase.auth.signOut();

      // 2. Feedback e navegação
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Conta excluída com sucesso!'),
            backgroundColor: Color(0xFF0A63AC),
          ),
        );
      }

    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Erro RPC: $e');
      }
      // Trata erros retornados pelo PostgreSQL (ex: RAISE EXCEPTION)
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro RPC na exclusão: ${e.message}'),
            backgroundColor: const Color(0xFF0A63AC),
          ),
        );
      }
    } catch (e) {
      // Trata erros de rede ou outros
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro inesperado na RPC: $e'),
            backgroundColor: const Color(0xFF0A63AC),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb ? false : true, // impede voltar
      child: Scaffold(
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: 70,
                          child: SvgPicture.asset("assets/logoInova.svg")
                      ),
                      Text(
                        "Login",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Color(0xFF0A63AC),
                        ),
                      ),
                      LayoutBuilder(
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
                                              keyboardType: TextInputType.emailAddress,
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
                                              keyboardType: TextInputType.visiblePassword,
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
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isPasswordVisible = !_isPasswordVisible;
                                                    });
                                                  },
                                                ),
                                              ),
                                              onFieldSubmitted: (value) {
                                                _login();
                                              },
                                              obscureText: !_isPasswordVisible,
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
                                            TextButton(
                                              style: ButtonStyle(
                                                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                              ),
                                              onPressed: _abrirFormulario,
                                              child: const Text(
                                                "Inscreva-se aqui 🖐️",
                                                style: TextStyle(
                                                    color: Colors.orange,
                                                    fontFamily: 'LeagueSpartan',
                                                    fontSize: 18,
                                                ),
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
                                    onPressed: _showDeleteDialog,
                                    child: const Text("Excluir Minha Conta",
                                      style: TextStyle(color: Colors.red),)
                                ),
                                TextButton(
                                    style: ButtonStyle(
                                      overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                    ),
                                    onPressed: () async {
                                      await _authService.clearCredentials();
          
                                      SharedPreferences preferences =
                                      await SharedPreferences.getInstance();
                                      await preferences.clear();
          
                                      // Opcional: limpar os campos da tela
                                      setState(() {
                                        _emailController.clear();
                                        _passwordController.clear();
                                        lembrarDados = false;
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
                                Text("Versão: 0.50",
                                  style: TextStyle(color: Color(0xFF0A63AC)),),
                                SizedBox(height: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("Desenvolvido por:",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),),
                                    const SizedBox(height: 5),
                                    InkWell(
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      enableFeedback: false,
                                      onTap: () async {
                                        final Uri url = Uri.parse("https://innovanow.com.br");
                                        if (!await launchUrl(url)) {
                                          throw Exception('Could not launch $url');
                                        }
                                      },
                                      child: SizedBox(
                                        height: 20,
                                        width: 80,
                                        child:  SvgPicture.asset('assets/logo.svg', fit: BoxFit.contain),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Formjovem extends StatefulWidget {
  final Map<String, dynamic>? jovem;
  final VoidCallback onjovemSalva;

  const _Formjovem({this.jovem, required this.onjovemSalva});

  @override
  _FormjovemState createState() => _FormjovemState();
}

class _FormjovemState extends State<_Formjovem> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(
      data,
    ); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }

  String formatarDinheiro(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  final JovemService _jovemService = JovemService();

  @override
  void initState() {
    super.initState();
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;

      error = await _jovemService.precadastrarjovem(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (error == null) {
        if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cadastrado com sucesso.",
                  style: TextStyle(
                    color: Colors.white,
                  )),
              backgroundColor: Color(0xFF0A63AC),
            ),
          );
        widget.onjovemSalva();
      } else {
        setState(() => _errorMessage = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildTextField(
                _nomeController, true,
                "Nome Completo",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _emailController, true,
                "E-mail",
                isEmail: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _senhaController, true,
                "Senha",
                isPassword: true,
                onChangedState: () => setState(() {}),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Cadastrar",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Cancelar",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null)
                SelectableText(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}