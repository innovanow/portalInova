import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import '../services/escola_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusEscola = "ativo";

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
    _carregarescolas(statusEscola);
  }

  void _carregarescolas(statusEscola) async {
    final escolas = await _escolaService.buscarescolas(statusEscola);
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                escola == null ? "Cadastrar Colégio" : "Editar Colégio",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'FuturaBold',
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
          content: _Formescola(
            escola: escola,
            onescolaSalva: () {
              _carregarescolas(statusEscola); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarEscola(String id) {
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
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
              ),
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.orange,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )
              ),
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
              ),
              onPressed: () async {
                await _escolaService
                    .inativarEscola(id);
                _carregarescolas(statusEscola);
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

  void ativarEscola(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar este colégio?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
              ),
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.orange,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  )
              ),
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
              ),
              onPressed: () async {
                await _escolaService
                    .ativarEscola(id);
                _carregarescolas(statusEscola);
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
    final isAtivo = statusEscola.toLowerCase() == 'ativo';
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
                elevation: 0,
                surfaceTintColor: Colors.transparent,
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
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    enableFeedback: false,
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
                                  "Colégios: ${isAtivo ? "Ativos" : "Inativos"}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Tooltip(
                                  message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                  child: Switch(
                                    value: isAtivo,
                                    onChanged: (value) {
                                      setState(() {
                                        statusEscola = value ? "ativo" : "inativo";
                                      });
                                      _carregarescolas(statusEscola);
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
                                                tooltip: "Editar",
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                splashColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                enableFeedback: false,
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
                                                tooltip: isAtivo == true ? "Inativar" : "Ativar",
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                splashColor: Colors.transparent,
                                                highlightColor: Colors.transparent,
                                                enableFeedback: false,
                                                icon: Icon(isAtivo == true ? Icons.block : Icons.restore, color: Colors.white, size: 20,),
                                                onPressed: () => isAtivo == true ? inativarEscola(escola['id']) : ativarEscola(escola['id']),
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
            tooltip: "Cadastrar Colégio",
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
              buildTextField(_nomeController, "Nome"),
              if (!_editando) ...[
                buildTextField(_emailController, "E-mail", isEmail: true, onChangedState: () => setState(() {})),
                buildTextField(_senhaController, "Senha", isPassword: true, onChangedState: () => setState(() {})),
              ],
              buildTextField(_cnpjController, "CNPJ", isCnpj: true, onChangedState: () => setState(() {})),
              buildTextField(_enderecoController, "Endereço", onChangedState: () => setState(() {})),
              buildTextField(_cidadeController, "Cidade", onChangedState: () => setState(() {})),
              buildTextField(_estadoController, "Estado", onChangedState: () => setState(() {})),
              buildTextField(_numeroController, "Número", onChangedState: () => setState(() {})),
              buildTextField(_cepController, "CEP", isCep: true, onChangedState: () => setState(() {})),
              buildTextField(_telefoneController, "Telefone", onChangedState: () => setState(() {})),
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
}
