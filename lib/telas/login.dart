import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/cep_service.dart';
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
                                Text("Versão: 0.48",
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
  final _dataNascimentoController = TextEditingController();
  final _nomePaiController = TextEditingController();
  final _nomeMaeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cpfPaiController = TextEditingController();
  final _cpfMaeController = TextEditingController();
  final _rgPaiController = TextEditingController();
  final _rgMaeController = TextEditingController();
  final _codCarteiraTrabalhoController = TextEditingController();
  final _rgController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneJovemController = TextEditingController();
  final _telefonePaiController = TextEditingController();
  final _telefoneMaeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _horasTrabalhoController = TextEditingController();
  final _remuneracaoController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _cpfResponsavelController = TextEditingController();
  final _rgResponsavelController = TextEditingController();
  final _emailResponsavelController = TextEditingController();
  final _telefoneResponsavelController = TextEditingController();
  final _outraEscolaController = TextEditingController();
  final _outraEmpresaController = TextEditingController();
  final _anoInicioColegioController = TextEditingController();
  final _anoFimColegioController = TextEditingController();
  final _pisController = TextEditingController();
  final _rendaController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _empresaSelecionada;
  String? _escolaSelecionada;
  String? _sexoSelecionado;
  String? _orientacaoSelecionado;
  String? _identidadeSelecionado;
  String? _corSelecionado;
  String? _pcdSelecionado;
  String? _estadoCivilSelecionado = "Solteiro";
  String? _estadoCivilPaiSelecionado = "Solteiro";
  String? _estadoCivilMaeSelecionado = "Solteiro";
  String? _estadoCivilResponsavelSelecionado = "Solteiro";
  String? _moraComSelecionado;
  String? _filhosSelecionado = "Não";
  String? _membrosSelecionado = "1";
  String? _escolaridadeSelecionado;
  String? _estaEstudandoSelecionado;
  String? _turnoColegioSelecionado;
  String? _estaTrabalhandoSelecionado;
  String? _cadastroCrasSelecionado;
  String? _atoInfracionalSelecionado;
  String? _beneficioSelecionado;
  String? _instituicaoSelecionado;
  String? _informaticaSelecionado;
  String? _habilidadeSelecionado;
  List<Map<String, dynamic>> _escolas = [];
  List<Map<String, dynamic>> _empresas = [];
  String? _cidadeSelecionada;
  String? _cidadeNatalSelecionada;
  String? _nacionalidadeSelecionada;
  String? _areaAprendizado;

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

  void _carregarEscolasEmpresas() async {
    final escolas = await _jovemService.buscarEscolas();
    final empresas = await _jovemService.buscarEmpresas();
    setState(() {
      _escolas = escolas;
      _empresas = empresas;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarEscolasEmpresas();
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;

      error = await _jovemService.precadastrarjovem(
        nome: _nomeController.text.trim(),
        dataNascimento:
        _dataNascimentoController.text.isNotEmpty
            ? formatter.format(
          DateFormat(
            'dd/MM/yyyy',
          ).parse(_dataNascimentoController.text),
        )
            : null,
        nomePai: _nomePaiController.text.trim(),
        nomeMae: _nomeMaeController.text.trim(),
        endereco: _enderecoController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidadeEstado: _cidadeSelecionada?.trim(),
        cidadeEstadoNatal: _cidadeNatalSelecionada?.trim(),
        rg: _rgController.text.trim(),
        codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
        estadoCivilPai: _estadoCivilPaiSelecionado,
        estadoCivilMae: _estadoCivilMaeSelecionado,
        estadoCivil: _estadoCivilSelecionado,
        estadoCivilResponsavel:  _estadoCivilResponsavelSelecionado,
        cpfPai: _cpfPaiController.text.trim(),
        cpfMae: _cpfMaeController.text.trim(),
        rgPai: _rgPaiController.text.trim(),
        rgMae: _rgMaeController.text.trim(),
        cep: _cepController.text.trim(),
        telefoneJovem: _telefoneJovemController.text.trim(),
        telefonePai: _telefonePaiController.text.trim(),
        telefoneMae: _telefoneMaeController.text.trim(),
        escola:  _escolaSelecionada,
        empresa:  _empresaSelecionada,
        areaAprendizado: null,
        escolaridade: _escolaridadeSelecionado,
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
        cpf: _cpfController.text.trim(),
        horasTrabalho: _horasTrabalhoController.text.trim().isEmpty ||
            _horasTrabalhoController.text.trim() == "00:00:00"
            ? null
            : _horasTrabalhoController.text.trim(),
        remuneracao: _remuneracaoController.text.trim(),
        turma: null,
        sexoBiologico: _sexoSelecionado,
        estudando: _estaEstudandoSelecionado,
        trabalhando: _estaTrabalhandoSelecionado,
        escolaAlternativa: _outraEscolaController.text.trim(),
        empresaAlternativa: _outraEmpresaController.text.trim(),
        nomeResponsavel: _nomeResponsavelController.text.trim(),
        orientacaoSexual: _orientacaoSelecionado,
        identidadeGenero: _identidadeSelecionado,
        cor: _corSelecionado,
        pcd: _pcdSelecionado,
        rendaMensal: _rendaController.text.trim(),
        turnoEscola: _turnoColegioSelecionado,
        anoIncioEscola: _anoInicioColegioController.text.trim().isNotEmpty
            ? int.parse(_anoInicioColegioController.text.trim())
            : null,
        anoConclusaoEscola: _anoFimColegioController.text.trim().isNotEmpty
            ? int.parse(_anoFimColegioController.text.trim())
            : null,
        instituicaoEscola:  _instituicaoSelecionado,
        informatica: _informaticaSelecionado,
        habilidadeDestaque: _habilidadeSelecionado,
        codPis: _pisController.text.trim(),
        instagram: _instagramController.text.trim(),
        linkedin: _linkedinController.text.trim(),
        nacionalidade: _nacionalidadeSelecionada,
        moraCom: _moraComSelecionado,
        infracao: _atoInfracionalSelecionado,
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
              buildTextField(
                _dataNascimentoController, true,
                "Data de Nascimento",
                isData: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _estadoCivilSelecionado,
                decoration: InputDecoration(
                  labelText: "Estado Civil",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Solteiro', child: Text('Solteiro')),
                  DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                  DropdownMenuItem(
                    value: 'Divorciado',
                    child: Text('Divorciado'),
                  ),
                  DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _estadoCivilSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _sexoSelecionado,
                decoration: InputDecoration(
                  labelText: "Sexo Biologico",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _orientacaoSelecionado,
                decoration: InputDecoration(
                  labelText: "Orientação de Sexual",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Heterosexual',
                    child: Text('Heterosexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Homossexual',
                    child: Text('Homossexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Bissexual',
                    child: Text('Bissexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Pansexual',
                    child: Text('Pansexual'),
                  ),
                  DropdownMenuItem(value: 'Asexual', child: Text('Asexual')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _orientacaoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _identidadeSelecionado,
                decoration: InputDecoration(
                  labelText: "Identidade de gênero",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Mulher Cis.',
                    child: Text('Mulher Cis.'),
                  ),
                  DropdownMenuItem(
                    value: 'Homem Cis.',
                    child: Text('Homem Cis.'),
                  ),
                  DropdownMenuItem(
                    value: 'Homem Trans.',
                    child: Text('Homem Trans.'),
                  ),
                  DropdownMenuItem(
                    value: 'Mulher Trans.',
                    child: Text('Mulher Trans.'),
                  ),
                  DropdownMenuItem(value: 'Não binário', child: Text('Não binário')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _identidadeSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _corSelecionado,
                decoration: InputDecoration(
                  labelText: "Cor",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Branca', child: Text('Branca')),
                  DropdownMenuItem(value: 'Parda', child: Text('Parda')),
                  DropdownMenuItem(value: 'Preta', child: Text('Preta')),
                  DropdownMenuItem(value: 'Amarela', child: Text('Amarela')),
                  DropdownMenuItem(
                    value: 'Não declarado',
                    child: Text('Não declarado'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _corSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _pcdSelecionado,
                decoration: InputDecoration(
                  labelText: "PCD",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _pcdSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownSearch<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                clickProps: ClickProps(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  enableFeedback: false,
                ),
                suffixProps: DropdownSuffixProps(
                  dropdownButtonProps: DropdownButtonProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                    color: Colors.white,
                    iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
                // Configuração da aparência do campo de entrada
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Nacionalidade",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Configuração do menu suspenso
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, color: Colors.white),),
                  ),
                  menuProps: MenuProps(
                    color: Colors.white,
                    backgroundColor: Color(0xFF0A63AC),
                  ),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Procurar Nacionalidade",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: 250),
                ),
                // Função para buscar cidades do Supabase
                items: (String? filtro, dynamic _) async {
                  final response = await Supabase.instance.client
                      .from('pais')
                      .select('nacionalidade')
                      .ilike('nacionalidade', '%${filtro ?? ''}%')
                      .order('nacionalidade', ascending: true);

                  // Concatena cidade + UF
                  return List<String>.from(
                    response.map((e) => "${e['nacionalidade']}"),
                  );
                },
                // Callback chamado quando uma cidade é selecionada
                onChanged: (value) {
                  setState(() {
                    _nacionalidadeSelecionada = value;
                  });
                },
                selectedItem: _nacionalidadeSelecionada,
                dropdownBuilder: (context, selectedItem) {
                  return Text(
                    selectedItem ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  );
                },
              ),
              if(_nacionalidadeSelecionada == "Brasileira")
                const SizedBox(height: 10),
              if(_nacionalidadeSelecionada == "Brasileira")
                DropdownSearch<String>(
                  clickProps: ClickProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                  ),
                  suffixProps: DropdownSuffixProps(
                    dropdownButtonProps: DropdownButtonProps(
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      enableFeedback: false,
                      color: Colors.white,
                      iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                    ),
                  ),
                  // Configuração da aparência do campo de entrada
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Cidade Natal",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Configuração do menu suspenso
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 15, color: Colors.white),),
                    ),
                    menuProps: MenuProps(
                      color: Colors.white,
                      backgroundColor: Color(0xFF0A63AC),
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: "Procurar Cidade Natal",
                        labelStyle: const TextStyle(color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    fit: FlexFit.loose,
                    constraints: BoxConstraints(maxHeight: 250),
                  ),
                  // Função para buscar cidades do Supabase
                  items: (String? filtro, dynamic _) async {
                    final response = await Supabase.instance.client
                        .from('cidades')
                        .select('cidade_estado')
                        .ilike('cidade_estado', '%${filtro ?? ''}%')
                        .order('cidade_estado', ascending: true);

                    // Concatena cidade + UF
                    return List<String>.from(
                      response.map((e) => "${e['cidade_estado']}"),
                    );
                  },
                  // Callback chamado quando uma cidade é selecionada
                  onChanged: (value) {
                    setState(() {
                      _cidadeNatalSelecionada = value;
                    });
                  },
                  selectedItem: _cidadeNatalSelecionada,
                  dropdownBuilder: (context, selectedItem) {
                    return Text(
                      selectedItem ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    );
                  },
                ),
              const SizedBox(height: 10),
              buildTextField(
                _cpfController, true,
                "CPF",
                isCpf: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _rgController, false,
                "RG",
                isRg: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _telefoneJovemController, false,
                "Telefone do Jovem",
                isTelefone: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _moraComSelecionado,
                decoration: InputDecoration(
                  labelText: "Mora com quem",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Mãe', child: Text('Mãe')),
                  DropdownMenuItem(value: 'Pai', child: Text('Pai')),
                  DropdownMenuItem(
                    value: 'Mãe e Pai',
                    child: Text('Mãe e Pai'),
                  ),
                  DropdownMenuItem(
                    value: 'Mãe e Padrasto',
                    child: Text('Mãe e Padrasto'),
                  ),
                  DropdownMenuItem(
                    value: 'Pai e Madrasta',
                    child: Text('Pai e Madrasta'),
                  ),
                  DropdownMenuItem(value: 'Sozinho', child: Text('Sozinho')),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                ],
                onChanged: (value) {
                  setState(() {
                    _moraComSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                buildTextField(
                  _nomePaiController, false,
                  _moraComSelecionado.toString().contains('Pai') ? "Nome do Pai" : "Nome do Padrasto",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _estadoCivilPaiSelecionado,
                  decoration: InputDecoration(
                    labelText: _moraComSelecionado.toString().contains('Pai') ? "Estado Civil Pai" : _moraComSelecionado.toString().contains('Padrasto') ? "Estado Civil Padrasto" : "",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilPaiSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                buildTextField(
                  _cpfPaiController, false,
                  _moraComSelecionado.toString().contains('Pai') ? "CPF do Pai" : _moraComSelecionado.toString().contains('Padrasto') ? "CPF do Padrasto" : "",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                buildTextField(
                  _rgPaiController, false,
                  _moraComSelecionado.toString().contains('Pai') ? "RG do Pai" : _moraComSelecionado.toString().contains('Padrasto') ? "RG do Padrasto" : "",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai') || _moraComSelecionado.toString().contains('Padrasto'))
                buildTextField(
                  _telefonePaiController, false,
                  _moraComSelecionado.toString().contains('Pai') ? "Telefone do Pai" : _moraComSelecionado.toString().contains('Padrasto') ? "Telefone do Padrasto" : "",
                  isTelefone: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                buildTextField(
                  _nomeMaeController, false,
                  _moraComSelecionado.toString().contains('Mãe') ? "Nome da Mãe" : _moraComSelecionado.toString().contains('Madrasta') ? "Nome da Madrasta" : "",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _estadoCivilMaeSelecionado,
                  decoration: InputDecoration(
                    labelText: _moraComSelecionado.toString().contains('Mãe') ? "Estado Civil Mãe" : _moraComSelecionado.toString().contains('Madrasta') ? "Estado Civil Madrasta" : "",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilMaeSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                buildTextField(
                  _cpfMaeController, false,
                  _moraComSelecionado.toString().contains('Mãe') ? "CPF da Mãe" : _moraComSelecionado.toString().contains('Madrasta') ?  "CPF da Madrasta" : "",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                buildTextField(
                  _rgMaeController, false,
                  _moraComSelecionado.toString().contains('Mãe') ? "RG da Mãe" : _moraComSelecionado.toString().contains('Madrasta') ?  "RG da Madrasta" : "",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe') || _moraComSelecionado.toString().contains('Madrasta'))
                buildTextField(
                  _telefoneMaeController, false,
                  _moraComSelecionado.toString().contains('Mãe') ? "Telefone da Mãe" : _moraComSelecionado.toString().contains('Madrasta') ?  "Telefone da Madrasta" : "",
                  isTelefone: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _nomeResponsavelController, false,
                  "Nome do Responsável",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _estadoCivilResponsavelSelecionado,
                  decoration: InputDecoration(
                    labelText: "Estado Civil Responsável",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilResponsavelSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _cpfResponsavelController, false,
                  "CPF do Responsável",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _rgResponsavelController, false,
                  "RG do Responsável",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _telefoneResponsavelController, false,
                  "Telefone do Responsável",
                  isTelefone: true,
                  onChangedState: () => setState(() {}),
                ),
              if (!_moraComSelecionado.toString().contains('Sozinho'))
              buildTextField(
                _emailResponsavelController, false,
                "E-mail do Responsável",
                isEmail: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _filhosSelecionado,
                decoration: InputDecoration(
                  labelText: "Possui filhos",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                  DropdownMenuItem(value: '1', child: Text('1')),
                  DropdownMenuItem(value: '2', child: Text('2')),
                  DropdownMenuItem(value: '3', child: Text('3')),
                  DropdownMenuItem(value: '4', child: Text('4')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filhosSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _membrosSelecionado,
                decoration: InputDecoration(
                  labelText: "Quantidade de Membros na Família",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1')),
                  DropdownMenuItem(value: '2', child: Text('2')),
                  DropdownMenuItem(value: '3', child: Text('3')),
                  DropdownMenuItem(value: '4', child: Text('4')),
                  DropdownMenuItem(value: '5 ou +', child: Text('5 ou +')),
                ],
                onChanged: (value) {
                  setState(() {
                    _membrosSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _beneficioSelecionado,
                decoration: InputDecoration(
                  labelText: "Sua família recebe algum benefício assistencial?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                ],
                onChanged: (value) {
                  setState(() {
                    _beneficioSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _cadastroCrasSelecionado,
                decoration: InputDecoration(
                  labelText: "Possui cadastro no CRAS, CREAS ou Acolhimento?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _cadastroCrasSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _atoInfracionalSelecionado,
                decoration: InputDecoration(
                  labelText: "Já cumpriu ou cumpre medidas socioeducativas por ato infracional?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _atoInfracionalSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              buildTextField(
                _rendaController, false,
                "Renda mensal familiar",
                isDinheiro: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _cepController, true,
                "CEP",
                isCep: true,
                onChangedState: () async {
                  final cep = _cepController.text;
                  if (cep.length == 9) { // máscara completa: 00000-000
                    final endereco = await buscarEnderecoPorCep(cep);
                    if (endereco != null) {
                      setState(() {
                        _enderecoController.text = endereco['logradouro'] ?? '';
                        _bairroController.text = endereco['bairro'] ?? '';
                        _cidadeSelecionada = "${endereco['cidade']}-${endereco['uf']}";
                      });
                    }
                  }
                },
              ),
              buildTextField(
                _enderecoController, true,
                "Endereço",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _numeroController, true,
                "Número",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _bairroController, true,
                "Bairro",
                onChangedState: () => setState(() {}),
              ),
              DropdownSearch<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                clickProps: ClickProps(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  enableFeedback: false,
                ),
                suffixProps: DropdownSuffixProps(
                  dropdownButtonProps: DropdownButtonProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                    color: Colors.white,
                    iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
                // Configuração da aparência do campo de entrada
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Cidade",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Configuração do menu suspenso
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, color: Colors.white),),
                  ),
                  menuProps: MenuProps(
                    color: Colors.white,
                    backgroundColor: Color(0xFF0A63AC),
                  ),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Procurar Cidade",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: 250),
                ),
                // Função para buscar cidades do Supabase
                items: (String? filtro, dynamic _) async {
                  final response = await Supabase.instance.client
                      .from('cidades')
                      .select('cidade_estado')
                      .ilike('cidade_estado', '%${filtro ?? ''}%')
                      .order('cidade_estado', ascending: true);

                  // Concatena cidade + UF
                  return List<String>.from(
                    response.map((e) => "${e['cidade_estado']}"),
                  );
                },
                // Callback chamado quando uma cidade é selecionada
                onChanged: (value) {
                  setState(() {
                    _cidadeSelecionada = value;
                  });
                },
                selectedItem: _cidadeSelecionada,
                dropdownBuilder: (context, selectedItem) {
                  return Text(
                    selectedItem ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _estaEstudandoSelecionado,
                decoration: InputDecoration(
                  labelText: "Estudando?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estaEstudandoSelecionado = value!;
                  });
                },
              ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _escolaridadeSelecionado,
                  decoration: InputDecoration(
                    labelText: "Escolaridade",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Ensino Fundamental Incompleto',
                      child: Text('Ensino Fundamental Incompleto'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensino Fundamental Completo',
                      child: Text('Ensino Fundamental Completo'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensino Médio Incompleto',
                      child: Text('Ensino Médio Incompleto'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensino Médio Completo',
                      child: Text('Ensino Médio Completo'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensino Superior Incompleto',
                      child: Text('Ensino Superior Incompleto'),
                    ),
                    DropdownMenuItem(
                      value: 'Ensino Superior Completo',
                      child: Text('Ensino Superior Completo'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _escolaridadeSelecionado = value!;
                    });
                  },
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue:
                  (_escolaSelecionada != null &&
                      _escolas.any(
                            (e) => e['id'].toString() == _escolaSelecionada,
                      ))
                      ? _escolaSelecionada
                      : null,

                  // Evita erro caso o valor não esteja na lista
                  items:
                  _escolas
                      .map(
                        (e) => DropdownMenuItem(
                      value: e['id'].toString(),
                      child: Text(
                        e['nome'],
                        style: const TextStyle(
                          color: Colors.white,
                        ), // Cor do texto no menu
                      ),
                    ),
                  )
                      .toList(),

                  onChanged:
                      (value) =>
                      setState(() => _escolaSelecionada = value as String),

                  decoration: InputDecoration(
                    labelText: "Colégio",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: const Color(0xFF0A63AC),
                  style: const TextStyle(color: Colors.white),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_escolaSelecionada.toString().contains(
                'ed489387-3684-459e-8ad4-bde80c2cfb66',
              ))
                buildTextField(
                  _outraEscolaController, false,
                  "Qual Colégio?",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _turnoColegioSelecionado,
                  decoration: InputDecoration(
                    labelText: "Turno Colégio",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Matutino', child: Text('Matutino')),
                    DropdownMenuItem(value: 'Vespertino', child: Text('Vespertino')),
                    DropdownMenuItem(value: 'Noturno', child: Text('Noturno')),
                    DropdownMenuItem(value: 'Integral', child: Text('Integral')),
                    DropdownMenuItem(value: 'EAD', child: Text('EAD')),
                    DropdownMenuItem(value: 'Semi Presencial', child: Text('Semi Presencial')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _turnoColegioSelecionado = value!;
                    });
                  },
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _anoInicioColegioController, false, isAno: true,
                  "Ano de Início",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _anoFimColegioController, false, isAno: true,
                  "Ano de Conclusão (Previsto)",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _instituicaoSelecionado,
                  decoration: InputDecoration(
                    labelText: "Instituição de Ensino",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Privada', child: Text('Privada')),
                    DropdownMenuItem(value: 'Pública', child: Text('Pública')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _instituicaoSelecionado = value!;
                    });
                  },
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _informaticaSelecionado,
                decoration: InputDecoration(
                  labelText: "Conhecimento básico em informática?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _informaticaSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _habilidadeSelecionado,
                decoration: InputDecoration(
                  labelText: "Habilidade que mais se destaca:",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Adaptabilidade', child: Text('Adaptabilidade')),
                  DropdownMenuItem(value: 'Criatividade', child: Text('Criatividade')),
                  DropdownMenuItem(value: 'Flexibilidade', child: Text('Flexibilidade')),
                  DropdownMenuItem(value: 'Proatividade', child: Text('Proatividade')),
                  DropdownMenuItem(value: 'Trabalho em equipe', child: Text('Trabalho em equipe')),
                ],
                onChanged: (value) {
                  setState(() {
                    _habilidadeSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _estaTrabalhandoSelecionado,
                decoration: InputDecoration(
                  labelText: "Trabalhando?",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estaTrabalhandoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue:
                  (_empresaSelecionada != null &&
                      _empresas.any(
                            (e) =>
                        e['id'].toString() == _empresaSelecionada,
                      ))
                      ? _empresaSelecionada
                      : null,

                  // Evita erro caso o valor não esteja na lista
                  items:
                  _empresas
                      .map(
                        (e) => DropdownMenuItem(
                      value: e['id'].toString(),
                      child: Text(
                        e['nome'],
                        style: const TextStyle(
                          color: Colors.white,
                        ), // Cor do texto no menu
                      ),
                    ),
                  )
                      .toList(),

                  onChanged:
                      (value) =>
                      setState(() => _empresaSelecionada = value as String),

                  decoration: InputDecoration(
                    labelText: "Empresa",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: const Color(0xFF0A63AC),
                  style: const TextStyle(color: Colors.white),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_empresaSelecionada.toString().contains(
                '9d4a3fa4-e0ff-44fb-92c8-1f9a67868997',
              ))
                buildTextField(
                  _outraEmpresaController, false,
                  "Qual empresa?",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _codCarteiraTrabalhoController, false,
                  "Código Carteira de Trabalho",
                  isCtps: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _pisController, false,
                  "Código PIS",
                  isPis: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _areaAprendizado,
                  decoration: InputDecoration(
                    labelText: "Área de Aprendizado",
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Administração', child: Text('Administração')),
                    DropdownMenuItem(value: 'Educação', child: Text('Educação')),
                    DropdownMenuItem(value: 'Engenharia', child: Text('Engenharia')),
                    DropdownMenuItem(value: 'Saúde', child: Text('Saúde')),
                    DropdownMenuItem(value: 'Tecnologia', child: Text('Tecnologia')),
                    DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _areaAprendizado = value!;
                    });
                  },
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _horasTrabalhoController, false,
                  "Horas de Trabalho Exemplo: 08:00:00",
                  isHora: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _remuneracaoController, false,
                  "Remuneração",
                  isDinheiro: true,
                  onChangedState: () => setState(() {}),
                ),
              buildTextField(
                _instagramController, false,
                "Pefil Instagram",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _linkedinController, false,
                "Perfil LinkedIn",
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