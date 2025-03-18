import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/telas/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../services/turma_service.dart';

class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  final TurmaService _turmaService = TurmaService();
  List<Map<String, dynamic>> _turmas = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _turmasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarTurmas();
  }

  void _carregarTurmas() async {
    final turmas = await _turmaService.buscarTurmas();
    setState(() {
      _turmas = turmas;
      _turmasFiltradas = List.from(_turmas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? turma}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            turma == null ? "Cadastrar Turma" : "Editar Turma",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          content: _FormTurma(
            turma: turma,
            onTurmaSalva: () {
              _carregarTurmas(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void excluirTurma(String id) {
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
          content: const Text("Tem certeza de que deseja excluir esta turma?",
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
                setState(() {
                  _turmas.removeWhere((turma) => turma['id'] == id);
                  _turmasFiltradas = List.from(_turmas); // Atualiza a lista filtrada
                });
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
            _turmasFiltradas = List.from(_turmas); // 🔹 Restaura a lista original
          });
        }
      },
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
                  hintText: "Pesquisar turma...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  filtrarLista(
                    query: value,
                    listaOriginal: _turmas,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _turmasFiltradas = novaLista);
                    },
                  );
                },
              )
                  : const Text(
                'Turmas',
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
                    _turmas,
                        (novaLista) => setState(() {
                      _turmasFiltradas = novaLista;
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
                      height: 100,
                      width: 150,
                      child: Image.asset("assets/logo.png"),
                    ),
                    const Text(
                      'Usuário: João Victor',
                      style: TextStyle(
                        color: Color(0xFF0A63AC),
                        fontFamily: 'FuturaBold',
                      ),
                    ),
                  ],
                ),
              ),
              buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
              buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
              buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
              buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
              buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
              buildDrawerItem(Icons.man, "Cadastro de Professor", context),
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
                          itemCount: _turmasFiltradas.length,
                          itemBuilder: (context, index) {
                            final turma = _turmasFiltradas[index];
                            return Card(
                              color: Color(0xFF0A63AC),
                              child: ListTile(
                                title: Text(
                                  "Turma: ${turma['codigo_turma']}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ano: ${turma['ano']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_inicio']))} até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_termino']))}",
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
                                          ),
                                          onPressed:
                                              () => _abrirFormulario(
                                            turma: turma,
                                          ),
                                        ),
                                        Container(
                                          width: 2, // Espessura da linha
                                          height: 30, // Altura da linha
                                          color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.white, size: 20,),
                                          onPressed: () => excluirTurma(turma['id']),
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
    );
  }
}

class _FormTurma extends StatefulWidget {
  final Map<String, dynamic>? turma;
  final VoidCallback onTurmaSalva;

  const _FormTurma({this.turma, required this.onTurmaSalva});

  @override
  _FormTurmaState createState() => _FormTurmaState();
}

class _FormTurmaState extends State<_FormTurma> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _anoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataTerminoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _turmaId;
  final TurmaService _turmaservice = TurmaService();
  final TurmaService _moduloService = TurmaService();
  List<Map<String, dynamic>> _modulos = [];
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  List<String> modulosSelecionados = []; // Lista para armazenar os módulos selecionados

  @override
  void initState() {
    super.initState();
    _carregarModulos();
    if (widget.turma != null) {
      _editando = true;
      _turmaId = widget.turma!['id'].toString();
      _codigoController.text = widget.turma!['codigo_turma'];
      _anoController.text = widget.turma!['ano'].toString();
      _dataInicioController.text = formatarDataParaExibicao(widget.turma!['data_inicio'] ?? "");
      _dataTerminoController.text = formatarDataParaExibicao(widget.turma!['data_termino'] ?? "");
      modulosSelecionados = List<String>.from(widget.turma!['modulos_ids']);
    }
  }

  void _carregarModulos() async {
    final modulos = await _moduloService.buscarModulos();
    setState(() {
      _modulos = modulos;
    });
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _turmaservice.atualizarTurmas(
          id: _turmaId!,
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          modulosSelecionados: modulosSelecionados,
        );
      } else {
        error = await _turmaservice.cadastrarTurmas(
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          modulosSelecionados: modulosSelecionados,
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onTurmaSalva();
      } else {
        setState(() => _errorMessage = error);
      }
    }
  }

  var dataFormatter = MaskTextInputFormatter(
    mask: "##/##/####",
    filter: {"#": RegExp(r'[0-9]')},
  );

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
              _buildTextField(_codigoController, "Código da Turma"),
              _buildTextField(_anoController, "Ano", isAno: true),
              _buildTextField(_dataInicioController, "Data de Início", isData: true),
              _buildTextField(_dataTerminoController, "Data de Término", isData: true),
              MultiSelectChips(
                modulos: _modulos, // Lista de módulos carregada do Supabase
                onSelecionado: (selecionados) {
                  setState(() {
                    modulosSelecionados = selecionados;
                  });
                },
                modulosSelecionados: modulosSelecionados, // Garante que os valores iniciais sejam preenchidos
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
        bool isData = false,
        bool isAno = false,
      }) {

    var dataFormatter = MaskTextInputFormatter(
      mask: "##/##/####",
      filter: {"#": RegExp(r'[0-9]')},
    );

    var anoFormatter = MaskTextInputFormatter(
      mask: "####",
      filter: {"#": RegExp(r'[0-9]')},
    );

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
        inputFormatters: isData
            ? [dataFormatter]
            : isAno ? [anoFormatter] : [],
        validator: (value) {
          if (value == null || value.isEmpty) return "Digite um valor válido";
          if (isData && value.length != 10) return "Digite uma data válida";
          return null;
        },
      ),
    );
  }
}
