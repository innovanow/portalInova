import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/telas/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/jovem_service.dart';
import '../telas/home.dart';

class CadastroJovem extends StatefulWidget {
  const CadastroJovem({super.key});

  @override
  State<CadastroJovem> createState() => _CadastroJovemState();
}

class _CadastroJovemState extends State<CadastroJovem> {
  final JovemService _jovemService = JovemService();
  List<Map<String, dynamic>> _jovens = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _jovensFiltrados = [];
  bool modoPesquisa = false;
  final TextEditingController _pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarjovens();
  }

  void _carregarjovens() async {
    final jovens = await _jovemService.buscarjovem();
    setState(() {
      _jovens = jovens;
      _jovensFiltrados = List.from(_jovens);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? jovem}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            jovem == null ? "Cadastrar Jovem" : "Editar Jovem",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          content: _Formjovem(
            jovem: jovem,
            onjovemSalva: () {
              _carregarjovens(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void excluirJovem(String id) {
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
          content: const Text("Tem certeza de que deseja excluir este jovem?",
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
                _jovemService
                    .inativarJovem(id);
                _carregarjovens();
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
            _jovensFiltrados = List.from(_jovens); // 🔹 Restaura a lista original
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
                    hintText: "Pesquisar jovem...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _jovens,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _jovensFiltrados = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Jovens',
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
                      _jovens,
                          (novaLista) => setState(() {
                        _jovensFiltrados = novaLista;
                        modoPesquisa = false; // 🔹 Agora o modo pesquisa é atualizado corretamente
                      }),
                    ),

                  )
                      : IconButton(
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
                          itemCount: _jovensFiltrados.length,
                          itemBuilder: (context, index) {
                            final jovem = _jovensFiltrados[index];
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
                                      "Turma: ${jovem['cod_turma'] ?? ''}\nColégio: ${jovem['escola'] ?? ''}\nEmpresa: ${jovem['empresa'] ??''}",
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
                                            jovem: jovem,
                                          ),
                                        ),
                                        Container(
                                          width: 2, // Espessura da linha
                                          height: 30, // Altura da linha
                                          color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.white, size: 20,),
                                          onPressed: () => excluirJovem(jovem['id']),
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
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cpfPaiController = TextEditingController();
  final _cpfMaeController = TextEditingController();
  final _rgPaiController = TextEditingController();
  final _rgMaeController = TextEditingController();
  final _areaAprendizadoController = TextEditingController();
  final _codCarteiraTrabalhoController = TextEditingController();
  final _estadoCivilMaeController = TextEditingController();
  final _estadoCivilPaiController = TextEditingController();
  final _rgController = TextEditingController();
  final _cidadeNatalController = TextEditingController();
  final _paisController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneJovemController = TextEditingController();
  final _telefonePaiController = TextEditingController();
  final _telefoneMaeController = TextEditingController();
  final _escolaridadeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _horasTrabalhoController = TextEditingController();
  final _horasCursoController = TextEditingController();
  final _horasSemanaisController = TextEditingController();
  final _remuneracaoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _jovemId;
  String? _empresaSelecionada;
  String? _escolaSelecionada;
  String? _turmaSelecionada;
  List<Map<String, dynamic>> _escolas = [];
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _turmas = [];
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

  final JovemService _jovemService = JovemService();

  void _carregarEscolasEmpresas() async {
    final escolas = await _jovemService.buscarEscolas();
    final empresas = await _jovemService.buscarEmpresas();
    final turmas = await _jovemService.buscarTurmas();
    setState(() {
      _escolas = escolas;
      _empresas = empresas;
      _turmas = turmas;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarEscolasEmpresas();
    if (widget.jovem != null) {
      _editando = true;
      _jovemId = widget.jovem!['id'] ?? "";
      _nomeController.text = widget.jovem!['nome'] ?? "";
      _dataNascimentoController.text = formatarDataParaExibicao(widget.jovem!['data_nascimento'] ?? "");
      _nomePaiController.text = widget.jovem!['nome_pai'] ?? "";
      _estadoCivilPaiController.text = widget.jovem!['estado_civil_pai'] ?? "";
      _estadoCivilMaeController.text = widget.jovem!['estado_civil_mae'] ?? "";
      _cpfPaiController.text = widget.jovem!['cpf_pai'] ?? "";
      _cpfMaeController.text = widget.jovem!['cpf_mae'] ?? "";
      _rgPaiController.text = widget.jovem!['rg_pai'] ?? "";
      _rgMaeController.text = widget.jovem!['rg_mae'] ?? "";
      _nomeMaeController.text = widget.jovem!['nome_mae'] ?? "";
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
      _telefoneJovemController.text = widget.jovem!['telefone_jovem'] ?? "";
      _telefonePaiController.text = widget.jovem!['telefone_pai'] ?? "";
      _telefoneMaeController.text = widget.jovem!['telefone_mae'] ?? "";
      _escolaSelecionada = widget.jovem!['escola_id'] ?? "";
      _empresaSelecionada= widget.jovem!['empresa_id'] ?? "";
      _areaAprendizadoController.text = widget.jovem!['area_aprendizado'] ?? "";
      _escolaridadeController.text = widget.jovem!['escolaridade'] ?? "";
      _cpfController.text = widget.jovem!['cpf'] ?? "";
      _horasTrabalhoController.text = widget.jovem!['horas_trabalho'] ?? "";
      _horasCursoController.text = widget.jovem!['horas_curso'] ?? "";
      _horasSemanaisController.text = widget.jovem!['horas_semanais'] ?? "";
      _remuneracaoController.text = formatarDinheiro(widget.jovem!['remuneracao']);
      _turmaSelecionada= widget.jovem!['turma_id'] ?? "";
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _jovemService.atualizarjovem(
          id: _jovemId!,
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          nomePai: _nomePaiController.text.trim(),
          nomeMae: _nomeMaeController.text.trim(),
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          pais: _paisController.text.trim(),
          cidadeNatal: _cidadeNatalController.text.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          estadoCivilPai: _estadoCivilPaiController.text.trim(),
          estadoCivilMae: _estadoCivilMaeController.text.trim(),
          cpfPai: _cpfPaiController.text.trim(),
          cpfMae: _cpfMaeController.text.trim(),
          rgPai: _rgPaiController.text.trim(),
          rgMae: _rgMaeController.text.trim(),
          cep: _cepController.text.trim(),
          telefoneJovem: _telefoneJovemController.text.trim(),
          telefonePai: _telefonePaiController.text.trim(),
          telefoneMae: _telefoneMaeController.text.trim(),
          escola: _escolaSelecionada,
          empresa: _empresaSelecionada,
          areaAprendizado: _areaAprendizadoController.text.trim(),
          escolaridade: _escolaridadeController.text.trim(),
          cpf: _cpfController.text.trim(),
          horasTrabalho: _horasTrabalhoController.text.trim(),
          horasCurso: _horasCursoController.text.trim(),
          horasSemanais: _horasSemanaisController.text.trim(),
          remuneracao: _remuneracaoController.text.trim(),
          turma: _turmaSelecionada,
        );
      } else {
        error = await _jovemService.cadastrarjovem(
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          nomePai: _nomePaiController.text.trim(),
          nomeMae: _nomeMaeController.text.trim(),
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          pais: _paisController.text.trim(),
          cidadeNatal: _cidadeNatalController.text.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          estadoCivilPai: _estadoCivilPaiController.text.trim(),
          estadoCivilMae: _estadoCivilMaeController.text.trim(),
          cpfPai: _cpfPaiController.text.trim(),
          cpfMae: _cpfMaeController.text.trim(),
          rgPai: _rgPaiController.text.trim(),
          rgMae: _rgMaeController.text.trim(),
          cep: _cepController.text.trim(),
          telefoneJovem: _telefoneJovemController.text.trim(),
          telefonePai: _telefonePaiController.text.trim(),
          telefoneMae: _telefoneMaeController.text.trim(),
          escola: _escolaSelecionada,
          empresa: _empresaSelecionada,
          areaAprendizado: _areaAprendizadoController.text.trim(),
          escolaridade: _escolaridadeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cpf: _cpfController.text.trim(),
          horasTrabalho: _horasTrabalhoController.text.trim(),
          horasCurso: _horasCursoController.text.trim(),
          horasSemanais: _horasSemanaisController.text.trim(),
          remuneracao: _remuneracaoController.text.trim(),
          turma: _turmaSelecionada,
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
              _buildTextField(_nomeController, "Nome"),
              if (!_editando) ...[
                _buildTextField(_emailController, "E-mail", isEmail: true),
                _buildTextField(_senhaController, "Senha", isPassword: true),
              ],
              _buildTextField(_dataNascimentoController, "Data de Nascimento", isData: true),
              _buildTextField(_cidadeNatalController, "Cidade Natal"),
              _buildTextField(_cpfController, "CPF", isCpf: true),
              _buildTextField(_rgController, "RG", isRg: true),
              _buildTextField(_codCarteiraTrabalhoController, "Carteira de Trabalho"),
              _buildTextField(_nomePaiController, "Nome do Pai"),
              _buildTextField(_estadoCivilPaiController, "Estado Civil do Pai"),
              _buildTextField(_cpfPaiController, "CPF do Pai", isCpf: true),
              _buildTextField(_rgPaiController, "RG do Pai", isRg: true),
              _buildTextField(_nomeMaeController, "Nome da Mãe"),
              _buildTextField(_estadoCivilMaeController, "Estado Civil da Mãe"),
              _buildTextField(_cpfMaeController, "CPF da Mãe", isCpf: true),
              _buildTextField(_rgMaeController, "RG da Mãe", isRg: true),
              _buildTextField(_enderecoController, "Endereço"),
              _buildTextField(_numeroController, "Número"),
              _buildTextField(_bairroController, "Bairro"),
              _buildTextField(_cidadeController, "Cidade"),
              _buildTextField(_estadoController, "Estado"),
              _buildTextField(_paisController, "País"),
              _buildTextField(_cepController, "CEP", isCep: true),
              _buildTextField(_telefoneJovemController, "Telefone do Jovem"),
              _buildTextField(_telefonePaiController, "Telefone do Pai"),
              _buildTextField(_telefoneMaeController, "Telefone da Mãe"),
              _buildTextField(_escolaridadeController, "Escolaridade"),
              DropdownButtonFormField(
                value: (_escolaSelecionada != null &&
                    _escolas.any((e) => e['id'].toString() == _escolaSelecionada))
                    ? _escolaSelecionada
                    : null, // Evita erro caso o valor não esteja na lista

                items: _escolas.map((e) => DropdownMenuItem(
                  value: e['id'].toString(),
                  child: Text(
                    e['nome'],
                    style: const TextStyle(color: Colors.white), // Cor do texto no menu
                  ),
                )).toList(),

                onChanged: (value) => setState(() => _escolaSelecionada = value as String),

                decoration: InputDecoration(
                  labelText: "Colégio",
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
              DropdownButtonFormField(
                value: (_empresaSelecionada != null &&
                    _empresas.any((e) => e['id'].toString() == _empresaSelecionada))
                    ? _empresaSelecionada
                    : null, // Evita erro caso o valor não esteja na lista

                items: _empresas.map((e) => DropdownMenuItem(
                  value: e['id'].toString(),
                  child: Text(
                    e['nome'],
                    style: const TextStyle(color: Colors.white), // Cor do texto no menu
                  ),
                )).toList(),

                onChanged: (value) => setState(() => _empresaSelecionada = value as String),

                decoration: InputDecoration(
                  labelText: "Empresa",
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
              _buildTextField(_areaAprendizadoController, "Área de Aprendizado"),
              _buildTextField(_horasTrabalhoController, "Horas de Trabalho", isHora: true),
              _buildTextField(_horasCursoController, "Horas de Curso", isHora: true),
              _buildTextField(_horasSemanaisController, "Horas Semanais", isHora: true),
              _buildTextField(_remuneracaoController, "Remuneração", isDinheiro: true),
              DropdownButtonFormField(
                value: (_turmaSelecionada != null &&
                    _turmas.any((e) => e['id'].toString() == _turmaSelecionada))
                    ? _turmaSelecionada
                    : null, // Evita erro caso o valor não esteja na lista

                items: _turmas.map((e) => DropdownMenuItem(
                  value: e['id'].toString(),
                  child: Text(
                    e['codigo_turma'],
                    style: const TextStyle(color: Colors.white), // Cor do texto no menu
                  ),
                )).toList(),

                onChanged: (value) => setState(() => _turmaSelecionada = value as String),

                decoration: InputDecoration(
                  labelText: "Turma",
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
        bool isCpf = false,
        bool isCep = false,
        bool isData = false,
        bool isRg = false,
        bool isDinheiro = false,
        bool isHora = false,
      }) {

    var cpfFormatter = MaskTextInputFormatter(
      mask: "###.###.###-##",
      filter: {"#": RegExp(r'[0-9]')},
    );
    var cepFormatter = MaskTextInputFormatter(mask: "#####-###", filter: {"#": RegExp(r'[0-9]')});
    var dataFormatter = MaskTextInputFormatter(
      mask: "##/##/####",
      filter: {"#": RegExp(r'[0-9]')},
    );
    var rgFormatter = MaskTextInputFormatter(
      mask: "##.###.###-#",
      filter: {"#": RegExp(r'[0-9]')},
    );
    var dinheiroFormatter = CurrencyInputFormatter(
      leadingSymbol: 'R\$', // Adiciona "R$ " antes do valor
      useSymbolPadding: true, // Mantém espaço após "R$"
      thousandSeparator: ThousandSeparator.Period, // Usa "." como separador de milhar
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
            : isCnpj || isCep || isData || isCpf
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: isCpf
            ? [cpfFormatter]
            : isCep
            ? [cepFormatter]
            : isData ? [dataFormatter] : isRg ? [rgFormatter] : isDinheiro ? [dinheiroFormatter] : isHora ? [horaFormatter] : [],
        validator: (value) {
          if (value == null || value.isEmpty) return "Digite um valor válido";
          if (isEmail && !RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(value)) {
            return "Digite um e-mail válido";
          }
          if (isCnpj && value.length != 18) return "Digite um CNPJ válido";
          if (isCpf && value.length != 14) return "CPF deve ter 11 dígitos";
          if (isCep && value.length != 9) return "Digite um CEP válido";
          if (isData && value.length != 10) return "Digite uma data válida";
          if (isPassword && value.length < 6) return "A senha deve ter no mínimo 6 caracteres";
          if (isRg && value.length != 12) return "Digite um RG válido";
          if (isDinheiro && value.length < 8) return "Digite um valor válido";
          if (isHora && value.length != 8) return "Digite uma hora válida";
          return null;
        },
      ),
    );
  }
}