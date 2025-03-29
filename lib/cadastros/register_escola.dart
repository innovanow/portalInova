import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/telas/widgets.dart';
import '../services/escola_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../telas/home.dart';

class EscolaScreen extends StatefulWidget {
  const EscolaScreen({super.key});

  @override
  State<EscolaScreen> createState() => _EscolaScreenState();
}

class _EscolaScreenState extends State<EscolaScreen> {
  final EscolaService _escolaService = EscolaService();
  List<Map<String, dynamic>> _escolas = [];
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _escolasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();
  bool _isFetching = true;
  var cnpjFormatter = MaskTextInputFormatter(
      mask: "##.###.###/####-##",
      filter: {"#": RegExp(r'[0-9]')}
  );
  var cepFormatter = MaskTextInputFormatter(
      mask: "#####-###",
      filter: {"#": RegExp(r'[0-9]')}
  );

  @override
  void initState() {
    super.initState();
    _carregarescolas();
  }

  void _carregarescolas() async {
    final escolas = await _escolaService.buscarescolas();
    setState(() {
      _escolas = escolas;
      _escolasFiltradas = List.from(_escolas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? escola}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            escola == null ? "Cadastrar Colégio" : "Editar Colégio",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          content: _Formescola(
            escola: escola,
            onescolaSalva: () {
              _carregarescolas(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void excluirEscola(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Confirmar Exclusão",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),),
          content: const Text("Tem certeza de que deseja excluir esta empresa?",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _escolaService
                    .inativarEscola(id);
                _carregarescolas();
                Navigator.of(context).pop(); // Fecha o alerta
              },
              child: const Text("Excluir", style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold
              )),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _escolasFiltradas = List.from(_escolas); // 🔹 Restaura a lista original
          });
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Color(0xFF0A63AC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AppBar(
                backgroundColor: const Color(0xFF0A63AC),
                title: modoPesquisa
                    ? TextField(
                  controller: _pesquisaController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Pesquisar colégio...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _escolas,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _escolasFiltradas = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Colégios',
                  style: TextStyle(
                    fontFamily: 'FuturaBold',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  modoPesquisa
                      ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => fecharPesquisa(
                      setState,
                      _pesquisaController,
                      _escolas,
                          (novaLista) => setState(() {
                        _escolasFiltradas = novaLista;
                        modoPesquisa = false; // 🔹 Agora o modo pesquisa é atualizado corretamente
                      }),
                    ),

                  )
                      : IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => setState(() {
                      modoPesquisa = true; //
                    }),
                  ),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
                automaticallyImplyLeading: false,
                // Evita que o Flutter gere um botão automático
                leading: Builder(
                  builder:
                      (context) => Tooltip(
                    message: "Abrir Menu", // Texto do tooltip
                    child: IconButton(
                      icon: Icon(Icons.menu,
                        color: Colors.white,) ,// Ícone do Drawer
                      onPressed: () {
                        Scaffold.of(
                          context,
                        ).openDrawer(); // Abre o Drawer manualmente
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white,),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 80,
                        width: 150,
                        child: Image.asset("assets/logo.png"),
                      ),
                      Text(
                        'Usuário: ${auth.nomeUsuario ?? "Carregando..."}',
                        style: const TextStyle(color: Color(0xFF0A63AC)),
                      ),
                      Text(
                        'Email: ${auth.emailUsuario ?? "Carregando..."}',
                        style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                buildDrawerItem(Icons.home, "Home", context),
                buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
                buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
                buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
                buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
                buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
                buildDrawerItem(Icons.man, "Cadastro de Professor", context),
                buildDrawerItem(Icons.calendar_month, "Calendário", context),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                opacity: 0.2,
                image: AssetImage("assets/fundo.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Ondas decorativas
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(height: 45, color: Colors.orange),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(heightFactor: 0.6),
                    child: Container(height: 60, color: const Color(0xFF0A63AC)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(flip: true),
                    child: Container(height: 60, color: Colors.orange),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(flip: true, heightFactor: 0.6),
                    child: Container(height: 50, color: const Color(0xFF0A63AC)),
                  ),
                ),

                // Formulário centralizado
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 500,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                          _isFetching
                              ? const Center(
                            child: CircularProgressIndicator(),
                          )
                              : ListView.builder(
                            itemCount: _escolasFiltradas.length,
                            itemBuilder: (context, index) {
                              final escola = _escolasFiltradas[index];
                              return Card(
                                color: Color(0xFF0A63AC),
                                child: ListTile(
                                  title: Text(
                                    escola['nome'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CNPJ: ${cnpjFormatter.maskText(escola['cnpj'] ?? '')}",
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      Divider(color: Colors.white),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 20
                                            ),
                                            onPressed:
                                                () => _abrirFormulario(
                                              escola: escola,
                                            ),
                                          ),
                                          Container(
                                            width: 2, // Espessura da linha
                                            height: 30, // Altura da linha
                                            color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.white, size: 20,),
                                            onPressed: () => excluirEscola(escola['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _abrirFormulario(),
            backgroundColor: Color(0xFF0A63AC),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Formescola extends StatefulWidget {
  final Map<String, dynamic>? escola;
  final VoidCallback onescolaSalva;

  const _Formescola({this.escola, required this.onescolaSalva});

  @override
  _FormescolaState createState() => _FormescolaState();
}

class _FormescolaState extends State<_Formescola> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _escolaId;
  var cnpjFormatter = MaskTextInputFormatter(
      mask: "##.###.###/####-##",
      filter: {"#": RegExp(r'[0-9]')}
  );
  var cepFormatter = MaskTextInputFormatter(
      mask: "#####-###",
      filter: {"#": RegExp(r'[0-9]')}
  );

  final EscolaService _escolaService = EscolaService();

  @override
  void initState() {
    super.initState();
    if (widget.escola != null) {
      _editando = true;
      _escolaId = widget.escola!['id'].toString();
      _nomeController.text = widget.escola!['nome'].toString();
      _cnpjController.text = cnpjFormatter.maskText(widget.escola!['cnpj'].toString());
      _enderecoController.text = widget.escola!['endereco'].toString();
      _cidadeController.text = widget.escola!['cidade'].toString();
      _estadoController.text = widget.escola!['estado'].toString();
      _numeroController.text = widget.escola!['numero'].toString();
      _cepController.text = cepFormatter.maskText(widget.escola!['cep'].toString());
      _telefoneController.text = widget.escola!['telefone'].toString();
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _escolaService.atualizarescola(
          id: _escolaId!,
          nome: _nomeController.text.trim(),
          cnpj: _cnpjController.text.trim(),
          endereco: _enderecoController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          numero: _numeroController.text.trim(),
          cep: _cepController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      } else {
        error = await _escolaService.cadastrarescola(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cnpj: _cnpjController.text.trim(),
          endereco: _enderecoController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          numero: _numeroController.text.trim(),
          cep: _cepController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onescolaSalva();
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
              _buildTextField(_nomeController, "Nome"),
              if (!_editando) ...[
                _buildTextField(_emailController, "E-mail", isEmail: true),
                _buildTextField(_senhaController, "Senha", isPassword: true),
              ],
              _buildTextField(_cnpjController, "CNPJ", isCnpj: true),
              _buildTextField(_enderecoController, "Endereço"),
              _buildTextField(_cidadeController, "Cidade"),
              _buildTextField(_estadoController, "Estado"),
              _buildTextField(_numeroController, "Número"),
              _buildTextField(_cepController, "CEP", isCep: true),
              _buildTextField(_telefoneController, "Telefone"),
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
                      _editando ? "Atualizar" : "Cadastrar",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
                SelectableText(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool isPassword = false,
        bool isEmail = false,
        bool isCnpj = false,
        bool isCep = false,
      }) {

    var cnpjFormatter = MaskTextInputFormatter(mask: "##.###.###/####-##", filter: {"#": RegExp(r'[0-9]')});
    var cepFormatter = MaskTextInputFormatter(mask: "#####-###", filter: {"#": RegExp(r'[0-9]')});

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
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
        obscureText: isPassword,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isCnpj || isCep
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: isCnpj
            ? [cnpjFormatter]
            : isCep
            ? [cepFormatter]
            : [],
        validator: (value) {
          if (value == null || value.isEmpty) return "Digite um valor válido";
          if (isEmail && !RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(value)) {
            return "Digite um e-mail válido";
          }
          if (isCnpj && value.length != 18) return "Digite um CNPJ válido";
          if (isCep && value.length != 9) return "Digite um CEP válido";
          if (isPassword && value.length < 6) return "A senha deve ter no mínimo 6 caracteres";
          return null;
        },
      ),
    );
  }
}
