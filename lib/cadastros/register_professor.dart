import 'package:flutter/material.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:intl/intl.dart';
import '../services/professor_service.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusProfessor = "ativo";

class CadastroProfessor extends StatefulWidget {
  const CadastroProfessor({super.key});

  @override
  State<CadastroProfessor> createState() => _CadastroProfessorState();
}

class _CadastroProfessorState extends State<CadastroProfessor> {
  final ProfessorService _professorService = ProfessorService();
  List<Map<String, dynamic>> _professores = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _professoresFiltrados = [];
  bool modoPesquisa = false;
  final TextEditingController _pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarprofessores(statusProfessor);
  }

  void _carregarprofessores(statusProfessor) async {
    final professores = await _professorService.buscarprofessor(statusProfessor);
    setState(() {
      _professores = professores;
      _professoresFiltrados = List.from(_professores);
      _isFetching = false;
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
                jovem == null ? "Cadastrar Professor" : "Editar Professor",
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
          content: _Formjovem(
            jovem: jovem,
            onjovemSalva: () {
              _carregarprofessores(statusProfessor); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarProfessor(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar este professor?",
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
                await _professorService
                    .inativarProfessor(id);
                _carregarprofessores(statusProfessor);
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

  void ativarProfessor(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar este professor?",
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
                await _professorService
                    .ativarProfessor(id);
                _carregarprofessores(statusProfessor);
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
    final isAtivo = statusProfessor.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _professoresFiltrados = List.from(_professores); // 🔹 Restaura a lista original
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
                    hintText: "Pesquisar professor...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _professores,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _professoresFiltrados = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Professores',
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
                      _professores,
                          (novaLista) => setState(() {
                        _professoresFiltrados = novaLista;
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
                      modoPesquisa = true;
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
                                  "Professores: ${isAtivo ? "Ativos" : "Inativos"}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Tooltip(
                                  message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                  child: Switch(
                                    value: isAtivo,
                                    onChanged: (value) {
                                      setState(() {
                                        statusProfessor = value ? "ativo" : "inativo";
                                      });
                                      _carregarprofessores(statusProfessor);
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
                                itemCount: _professoresFiltrados.length,
                                itemBuilder: (context, index) {
                                  final jovem = _professoresFiltrados[index];
                                  return Card(
                                    color: Color(0xFF0A63AC),
                                    child: ListTile(
                                      title: Text(
                                        jovem['nome'] ?? '',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Formação: ${jovem['formacao'] ?? ''}",
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
                                                  jovem: jovem,
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
                                                onPressed: () => isAtivo == true ? inativarProfessor(jovem['id']) : ativarProfessor(jovem['id']),
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
            tooltip: "Cadastrar Professor",
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
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _formacaoController = TextEditingController();
  final _codCarteiraTrabalhoController = TextEditingController();
  final _estadoCivilController = TextEditingController();
  final _rgController = TextEditingController();
  final _cidadeNatalController = TextEditingController();
  final _paisController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _jovemId;
  String? _sexoSelecionado;
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  String formatarDinheiro(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  final ProfessorService _professorService = ProfessorService();

  @override
  void initState() {
    super.initState();
    if (widget.jovem != null) {
      _editando = true;
      _jovemId = widget.jovem!['id'] ?? "";
      _nomeController.text = widget.jovem!['nome'] ?? "";
      _dataNascimentoController.text = formatarDataParaExibicao(widget.jovem!['data_nascimento'] ?? "");
      _enderecoController.text = widget.jovem!['endereco'] ?? "";
      _numeroController.text = widget.jovem!['numero'] ?? "";
      _bairroController.text = widget.jovem!['bairro'] ?? "";
      _cidadeController.text = widget.jovem!['cidade'] ?? "";
      _estadoController.text = widget.jovem!['estado'] ?? "";
      _codCarteiraTrabalhoController.text = widget.jovem!['cod_carteira_trabalho'] ?? "";
      _rgController.text = widget.jovem!['rg'] ?? "";
      _paisController.text = widget.jovem!['pais'] ?? "";
      _cidadeNatalController.text = widget.jovem!['cidade_natal'] ?? "";
      _cepController.text = widget.jovem!['cep'] ?? "";
      _cpfController.text = widget.jovem!['cpf'] ?? "";
      _telefoneController.text = widget.jovem!['telefone'] ?? "";
      _formacaoController.text = widget.jovem!['formacao'] ?? "";
      _estadoCivilController.text = widget.jovem!['estado_civil'] ?? "";
      _sexoSelecionado= widget.jovem!['sexo'] ?? "";
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _professorService.atualizarprofessor(
          id: _jovemId!,
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          pais: _paisController.text.trim(),
          cidadeNatal: _cidadeNatalController.text.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          cep: _cepController.text.trim(),
          cpf: _cpfController.text.trim(),
          telefone: _telefoneController.text.trim(),
          formacao: _formacaoController.text.trim(),
          estadoCivil: _estadoCivilController.text.trim(),
          sexo: _sexoSelecionado,
        );
      } else {
        error = await _professorService.cadastrarprofessor(
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          pais: _paisController.text.trim(),
          cidadeNatal: _cidadeNatalController.text.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          cep: _cepController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cpf: _cpfController.text.trim(),
          telefone: _telefoneController.text.trim(),
          formacao: _formacaoController.text.trim(),
          estadoCivil: _estadoCivilController.text.trim(),
          sexo: _sexoSelecionado,
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
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
              buildTextField(_nomeController, "Nome", onChangedState: () => setState(() {})),
              if (!_editando) ...[
                buildTextField(_emailController, "E-mail", isEmail: true, onChangedState: () => setState(() {})),
                buildTextField(_senhaController, "Senha", isPassword: true, onChangedState: () => setState(() {})),
              ],
              buildTextField(_dataNascimentoController, "Data de Nascimento", isData: true, onChangedState: () => setState(() {})),
              DropdownButtonFormField<String>(
                value: _sexoSelecionado,
                decoration: InputDecoration(
                  labelText: "Sexo",
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  DropdownMenuItem(value: 'Prefiro não informar', child: Text('Prefiro não informar')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              buildTextField(_cidadeNatalController, "Cidade Natal", onChangedState: () => setState(() {})),
              buildTextField(_estadoCivilController, "Estado Civil", onChangedState: () => setState(() {})),
              buildTextField(_cpfController, "CPF", isCpf: true, onChangedState: () => setState(() {})),
              buildTextField(_rgController, "RG", isRg: true, onChangedState: () => setState(() {})),
              buildTextField(_codCarteiraTrabalhoController, "Carteira de Trabalho", onChangedState: () => setState(() {})),
              buildTextField(_enderecoController, "Endereço", onChangedState: () => setState(() {})),
              buildTextField(_numeroController, "Número", onChangedState: () => setState(() {})),
              buildTextField(_bairroController, "Bairro", onChangedState: () => setState(() {})),
              buildTextField(_cidadeController, "Cidade", onChangedState: () => setState(() {})),
              buildTextField(_estadoController, "Estado", onChangedState: () => setState(() {})),
              buildTextField(_paisController, "País", onChangedState: () => setState(() {})),
              buildTextField(_cepController, "CEP", isCep: true, onChangedState: () => setState(() {})),
              buildTextField(_telefoneController, "Telefone", onChangedState: () => setState(() {})),
              buildTextField(_formacaoController, "Formação", onChangedState: () => setState(() {})),
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