import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import '../services/empresa_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../widgets/drawer.dart';

String statusEmpresa = "ativo";

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final EmpresaService _empresaService = EmpresaService();
  List<Map<String, dynamic>> _empresas = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _empresasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();
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
    _carregarEmpresas();
  }

  void _carregarEmpresas() async {
    final empresas = await _empresaService.buscarEmpresas(statusEmpresa);
    setState(() {
      _empresas = empresas;
      _empresasFiltradas = List.from(_empresas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? empresa}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            empresa == null ? "Cadastrar Empresa" : "Editar Empresa",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          content: _FormEmpresa(
            empresa: empresa,
            onEmpresaSalva: () {
              _carregarEmpresas(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarEmpresa(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar esta empresa?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.orange,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )
              ),
            ),
            TextButton(
              onPressed: () async {
                await _empresaService
                    .inativarEmpresa(id);
                _carregarEmpresas();
                if (context.mounted){
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text("Inativar",
                  style: TextStyle(color: Colors.red,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )),
            ),
          ],
        );
      },
    );
  }

  void ativarEmpresa(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar esta empresa?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.orange,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )
              ),
            ),
            TextButton(
              onPressed: () async {
                await _empresaService
                    .ativarEmpresa(id);
                _carregarEmpresas();
                if (context.mounted){
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text("Ativar",
                  style: TextStyle(color: Colors.green,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusEmpresa.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _empresasFiltradas = List.from(_empresas); // 🔹 Restaura a lista original
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
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: const Color(0xFF0A63AC),
                title: modoPesquisa
                    ? TextField(
                  controller: _pesquisaController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Pesquisar empresa...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _empresas,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _empresasFiltradas = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Empresas',
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
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    enableFeedback: false,
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => fecharPesquisa(
                      setState,
                      _pesquisaController,
                      _empresas,
                          (novaLista) => setState(() {
                        _empresasFiltradas = novaLista;
                        modoPesquisa = false; // 🔹 Agora o modo pesquisa é atualizado corretamente
                      }),
                    ),

                  )
                      : IconButton(
                    tooltip: "Pesquisar",
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    enableFeedback: false,
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
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      enableFeedback: false,
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
          drawer: InovaDrawer(context: context),
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Empresas: ${isAtivo ? "Ativas" : "Inativas"}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Tooltip(
                                  message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                  child: Switch(
                                    value: isAtivo,
                                    onChanged: (value) {
                                      setState(() {
                                        statusEmpresa = value ? "ativo" : "inativo";
                                      });
                                      _carregarEmpresas();
                                    },
                                    activeColor: Color(0xFF0A63AC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
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
                                        itemCount: _empresasFiltradas.length,
                                        itemBuilder: (context, index) {
                                          final empresa = _empresasFiltradas[index];
                                          return Card(
                                            color: Color(0xFF0A63AC),
                                            child: ListTile(
                                              title: Text(
                                                empresa['nome'],
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              subtitle: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CNPJ: ${cnpjFormatter.maskText(empresa['cnpj'] ?? '')}",
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                  Divider(color: Colors.white),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      IconButton(
                                                        tooltip: "Editar",
                                                        focusColor: Colors.transparent,
                                                        hoverColor: Colors.transparent,
                                                        splashColor: Colors.transparent,
                                                        highlightColor: Colors.transparent,
                                                        enableFeedback: false,
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        ),
                                                        onPressed:
                                                            () => _abrirFormulario(
                                                          empresa: empresa,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: 2, // Espessura da linha
                                                        height: 30, // Altura da linha
                                                        color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                                      ),
                                                      IconButton(
                                                        tooltip: isAtivo == true ? "Inativar" : "Ativar",
                                                        focusColor: Colors.transparent,
                                                        hoverColor: Colors.transparent,
                                                        splashColor: Colors.transparent,
                                                        highlightColor: Colors.transparent,
                                                        enableFeedback: false,
                                                        icon: Icon(isAtivo == true ? Icons.block : Icons.restore, color: Colors.white, size: 20,),
                                                        onPressed: () => isAtivo == true ? inativarEmpresa(empresa['id']) : ativarEmpresa(empresa['id']),
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
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: "Cadastrar Empresa",
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            enableFeedback: false,
            onPressed: () => _abrirFormulario(),
            backgroundColor: Color(0xFF0A63AC),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _FormEmpresa extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  final VoidCallback onEmpresaSalva;

  const _FormEmpresa({this.empresa, required this.onEmpresaSalva});

  @override
  _FormEmpresaState createState() => _FormEmpresaState();
}

class _FormEmpresaState extends State<_FormEmpresa> {
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
  String? _empresaId;
  var cnpjFormatter = MaskTextInputFormatter(
      mask: "##.###.###/####-##",
      filter: {"#": RegExp(r'[0-9]')}
  );
  var cepFormatter = MaskTextInputFormatter(
      mask: "#####-###",
      filter: {"#": RegExp(r'[0-9]')}
  );

  final EmpresaService _empresaService = EmpresaService();

  @override
  void initState() {
    super.initState();
    if (widget.empresa != null) {
      _editando = true;
      _empresaId = widget.empresa!['id'].toString();
      _nomeController.text = widget.empresa!['nome'].toString();
      _cnpjController.text = cnpjFormatter.maskText(widget.empresa!['cnpj'].toString());
      _enderecoController.text = widget.empresa!['endereco'].toString();
      _cidadeController.text = widget.empresa!['cidade'].toString();
      _estadoController.text = widget.empresa!['estado'].toString();
      _numeroController.text = widget.empresa!['numero'].toString();
      _cepController.text = cepFormatter.maskText(widget.empresa!['cep'].toString());
      _telefoneController.text = widget.empresa!['telefone'].toString();
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _empresaService.atualizarEmpresa(
          id: _empresaId!,
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
        error = await _empresaService.cadastrarEmpresa(
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
        widget.onEmpresaSalva();
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
