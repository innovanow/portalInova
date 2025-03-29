import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/telas/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/modulo_service.dart';
import '../telas/home.dart';

class ModuloScreen extends StatefulWidget {
  const ModuloScreen({super.key});

  @override
  State<ModuloScreen> createState() => _ModuloScreenState();
}

class _ModuloScreenState extends State<ModuloScreen> {
  final ModuloService _moduloService = ModuloService();
  List<Map<String, dynamic>> _modulos = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _modulosFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  void _carregarModulos() async {
    final modulos = await _moduloService.buscarModulos();
    setState(() {
      _modulos = modulos;
      _modulosFiltradas = List.from(_modulos);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? modulo}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            modulo == null ? "Cadastrar Módulo" : "Editar Módulo",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          content: _FormModulo(
            modulo: modulo,
            onModuloSalva: () {
              _carregarModulos(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void excluirModulo(String id) {
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
          content: const Text("Tem certeza de que deseja excluir esta módulo?",
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
                _moduloService
                    .inativarModulo(id);
                _carregarModulos();
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
            _modulosFiltradas = List.from(_modulos); // 🔹 Restaura a lista original
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
                    hintText: "Pesquisar módulo...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _modulos,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _modulosFiltradas = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Módulos',
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
                      _modulos,
                          (novaLista) => setState(() {
                        _modulosFiltradas = novaLista;
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
                            itemCount: _modulosFiltradas.length,
                            itemBuilder: (context, index) {
                              final modulo = _modulosFiltradas[index];
                              return Card(
                                color: Color(0xFF0A63AC),
                                child: ListTile(
                                  title: Text(
                                    "Módulo: ${modulo['nome']}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Turno: ${modulo['turno']}\n"
                                            "Período: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(modulo['data_inicio']))} até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(modulo['data_termino']))}\n"
                                            "Horário: ${modulo['horario_inicial']} até ${modulo['horario_final']}",
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
                                              modulo: modulo,
                                            ),
                                          ),
                                          Container(
                                            width: 2, // Espessura da linha
                                            height: 30, // Altura da linha
                                            color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.white, size: 20,),
                                            onPressed: () => excluirModulo(modulo['id']),
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

class _FormModulo extends StatefulWidget {
  final Map<String, dynamic>? modulo;
  final VoidCallback onModuloSalva;

  const _FormModulo({this.modulo, required this.onModuloSalva});

  @override
  _FormModuloState createState() => _FormModuloState();
}

class _FormModuloState extends State<_FormModulo> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataTerminoController = TextEditingController();
  final _horarioInicialController = TextEditingController();
  final _horarioFinalController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _moduloId;
  final ModuloService _moduloservice = ModuloService();
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  String? _turnoSelecionado;
  String? _diaSelecionado;

  @override
  void initState() {
    super.initState();
    if (widget.modulo != null) {
      _editando = true;
      _moduloId = widget.modulo!['id'].toString();
      _nomeController.text = widget.modulo!['nome'] ?? "";
      _turnoSelecionado = widget.modulo!['turno'] ?? "";
      _diaSelecionado = widget.modulo!['dia_semana'] ?? "";
      _dataInicioController.text = formatarDataParaExibicao(widget.modulo!['data_inicio'] ?? "");
      _dataTerminoController.text = formatarDataParaExibicao(widget.modulo!['data_termino'] ?? "");
      _horarioInicialController.text = widget.modulo!['horario_inicial'] ?? "";
      _horarioFinalController.text = widget.modulo!['horario_final'] ?? "";
      selectedColor = Color(int.parse(widget.modulo!['cor']));
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _moduloservice.atualizarModulos(
          id: _moduloId!,
          nome: _nomeController.text.trim(),
          turno: _turnoSelecionado,
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          horarioInicial: _horarioInicialController.text.trim(),
          horarioFinal: _horarioFinalController.text.trim(),
          diaSemana: _diaSelecionado,
          cor: '0x${selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
        );
      } else {
        error = await _moduloservice.cadastrarModulos(
          nome: _nomeController.text.trim(),
          turno: _turnoSelecionado,
          diaSemana: _diaSelecionado,
          horarioInicial: _horarioInicialController.text.trim(),
          horarioFinal: _horarioFinalController.text.trim(),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          cor: '0x${selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onModuloSalva();
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
              _buildTextField(_nomeController, "Nome"),
            DropdownButtonFormField<String>(
              value: _turnoSelecionado, // Variável que armazena o valor selecionado
              items: ['Matutino', 'Vespertino', 'Noturno']
                  .map((String turno) => DropdownMenuItem(
                value: turno,
                child: Text(
                  turno,
                  style: const TextStyle(color: Colors.white), // Cor do texto no menu
                ),
              ))
                  .toList(),

              onChanged: (value) => setState(() => _turnoSelecionado = value), // Atualiza o estado

              decoration: InputDecoration(
                labelText: "Turno",
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

              dropdownColor: const Color(0xFF0A63AC),
              style: const TextStyle(color: Colors.white),
            ),
              const SizedBox(height: 10),
              _buildTextField(_dataInicioController, "Data de Início", isData: true),
              _buildTextField(_dataTerminoController, "Data de Término", isData: true),
              _buildTextField(_horarioInicialController, "Horário de Início", isHora: true),
              _buildTextField(_horarioFinalController, "Horário de Término", isHora: true),
              DropdownButtonFormField<String>(
                value: _diaSelecionado, // Variável que armazena o valor selecionado
                items: ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado']
                    .map((String dia) => DropdownMenuItem(
                  value: dia,
                  child: Text(
                    dia,
                    style: const TextStyle(color: Colors.white), // Cor do texto no menu
                  ),
                ))
                    .toList(),

                onChanged: (value) => setState(() => _diaSelecionado = value), // Atualiza o estado

                decoration: InputDecoration(
                  labelText: "Dia da Semana",
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

                dropdownColor: const Color(0xFF0A63AC),
                style: const TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              ColorWheelPicker(
                onColorSelected: (Color color) {
                  if (kDebugMode) {
                    print("Cor selecionada: $color");
                  }
                },
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
        bool isHora = false,
      }) {

    var dataFormatter = MaskTextInputFormatter(
      mask: "##/##/####",
      filter: {"#": RegExp(r'[0-9]')},
    );

    var anoFormatter = MaskTextInputFormatter(
      mask: "####",
      filter: {"#": RegExp(r'[0-9]')},
    );

    var horaFormatter = MaskTextInputFormatter(
      mask: "##:##:##",
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
            : isAno ? [anoFormatter] : isHora ? [horaFormatter] : [],
        validator: (value) {
          if (value == null || value.isEmpty) return "Digite um valor válido";
          if (isData && value.length != 10) return "Digite uma data válida";
          if (isHora && value.length != 8) return "Digite uma hora válida";
          return null;
        },
      ),
    );
  }
}
