import 'package:flutter/material.dart';
import 'package:inova/cadastros/register_ocorrencia.dart';
import 'package:inova/telas/jovem.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/jovem_service.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusJovem = "ativo";

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
  String? fotoUrlAssinada;

  @override
  void initState() {
    super.initState();
    _carregarjovens(statusJovem);
  }

  void _carregarjovens(String status) async {
    List<Map<String, dynamic>> jovens;

    if (auth.tipoUsuario == "professor") {
      jovens = await _jovemService.buscarJovensDoProfessor(auth.idUsuario.toString(), status);
    } else {
      jovens = await _jovemService.buscarjovem(status);
    }

    setState(() {
      _jovens = jovens;
      _jovensFiltrados = List.from(jovens);
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
                jovem == null ? "Cadastrar Jovem" : "Editar Jovem",
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
              _carregarjovens(statusJovem); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarJovem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar este jovem?",
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
                await _jovemService
                    .inativarJovem(id);
                _carregarjovens(statusJovem);
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

  void ativarJovem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar este jovem?",
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
                await _jovemService
                    .ativarJovem(id);
                _carregarjovens(statusJovem);
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

  Future<String?> _getSignedUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;

    try {
      final url = await Supabase.instance.client.storage
          .from('fotosjovens')
          .createSignedUrl(path, 3600);
      return url;
    } catch (e) {
      debugPrint("Erro ao gerar signed URL: $e");
      return null;
    }
  }


  String _getIniciais(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.trim().isEmpty) return "JA";

    final partes = nomeCompleto.trim().split(" ");
    if (partes.length == 1) return partes[0][0].toUpperCase();

    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusJovem.toLowerCase() == 'ativo';
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
                elevation: 0,
                surfaceTintColor: Colors.transparent,
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
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  enableFeedback: false,
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
                        if (auth.tipoUsuario == "administrador")
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Jovens: ${isAtivo ? "Ativos" : "Inativos"}",
                                textAlign: TextAlign.end,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Tooltip(
                                message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                child: Switch(
                                  value: isAtivo,
                                  onChanged: (value) {
                                    setState(() {
                                      statusJovem = value ? "ativo" : "inativo";
                                    });
                                    _carregarjovens(statusJovem);
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
                              itemCount: _jovensFiltrados.length,
                              itemBuilder: (context, index) {
                                final jovem = _jovensFiltrados[index];
                                return Card(
                                  color: Color(0xFF0A63AC),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          spacing: 10,
                                          children: [
                                            FutureBuilder<String?>(
                                              future: _getSignedUrl(jovem['foto_url']),
                                              builder: (context, snapshot) {
                                                final temFoto = snapshot.hasData && snapshot.data!.isNotEmpty;

                                                return CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: const Color(0xFFFF9800),
                                                  backgroundImage: temFoto ? NetworkImage(snapshot.data!) : null,
                                                  child: !temFoto
                                                      ? Text(
                                                    _getIniciais(jovem['nome']),
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  )
                                                      : null,
                                                );
                                              },
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  jovem['nome'] ?? '',
                                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  "Colégio: ${jovem['escola'] ?? ''}\nEmpresa: ${jovem['empresa'] ?? ''}",
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                if (auth.tipoUsuario == "professor")
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  auth.tipoUsuario == "professor"
                                                      ? "Turma: ${jovem['cod_turma'] ?? ''}\nMódulo: ${jovem['turmas']?['modulos_turmas']?[0]?['modulos']?['nome'] ?? 'Não informado'}"
                                                      : "",
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Divider(color: Colors.white),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              enableFeedback: false,
                                              tooltip: "Visualizar",
                                              icon: const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                                              onPressed: () => Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(builder: (_) => JovemAprendizDetalhes(jovem: jovem))),
                                            ),
                                            IconButton(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              enableFeedback: false,
                                              tooltip: "Ocorrências",
                                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                              onPressed: () => Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(builder: (_) =>
                                                      OcorrenciasScreen(jovemId: jovem['id'], nomeJovem: jovem['nome']))),
                                            ),
                                            if (auth.tipoUsuario == "administrador")
                                            IconButton(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              enableFeedback: false,
                                              tooltip: "Editar",
                                              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                              onPressed: () => _abrirFormulario(jovem: jovem),
                                            ),
                                            if (auth.tipoUsuario == "administrador")
                                            IconButton(
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              highlightColor: Colors.transparent,
                                              enableFeedback: false,
                                              tooltip: isAtivo == true ? "Inativar" : "Ativar",
                                              icon: Icon(isAtivo == true ? Icons.block : Icons.restore, color: Colors.white, size: 20),
                                              onPressed: () => isAtivo == true ? inativarJovem(jovem['id']) : ativarJovem(jovem['id']),
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
          floatingActionButton: auth.tipoUsuario == "administrador" ? FloatingActionButton(
            tooltip: "Cadastrar Jovem",
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            enableFeedback: false,
            onPressed: () => _abrirFormulario(),
            backgroundColor: Color(0xFF0A63AC),
            child: const Icon(Icons.add, color: Colors.white),
          ) : null
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
  String? _sexoSelecionado;
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
      _sexoSelecionado= widget.jovem!['sexo'] ?? "";
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
          sexo: _sexoSelecionado,
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
              buildTextField(_cpfController, "CPF", isCpf: true, onChangedState: () => setState(() {})),
              buildTextField(_rgController, "RG", isRg: true, onChangedState: () => setState(() {})),
              buildTextField(_codCarteiraTrabalhoController, "Carteira de Trabalho", onChangedState: () => setState(() {})),
              buildTextField(_nomePaiController, "Nome do Pai", onChangedState: () => setState(() {})),
              buildTextField(_estadoCivilPaiController, "Estado Civil do Pai", onChangedState: () => setState(() {})),
              buildTextField(_cpfPaiController, "CPF do Pai", isCpf: true, onChangedState: () => setState(() {})),
              buildTextField(_rgPaiController, "RG do Pai", isRg: true, onChangedState: () => setState(() {})),
              buildTextField(_nomeMaeController, "Nome da Mãe", onChangedState: () => setState(() {})),
              buildTextField(_estadoCivilMaeController, "Estado Civil da Mãe", onChangedState: () => setState(() {})),
              buildTextField(_cpfMaeController, "CPF da Mãe", isCpf: true, onChangedState: () => setState(() {})),
              buildTextField(_rgMaeController, "RG da Mãe", isRg: true, onChangedState: () => setState(() {})),
              buildTextField(_enderecoController, "Endereço", onChangedState: () => setState(() {})),
              buildTextField(_numeroController, "Número", onChangedState: () => setState(() {})),
              buildTextField(_bairroController, "Bairro", onChangedState: () => setState(() {})),
              buildTextField(_cidadeController, "Cidade", onChangedState: () => setState(() {})),
              buildTextField(_estadoController, "Estado", onChangedState: () => setState(() {})),
              buildTextField(_paisController, "País", onChangedState: () => setState(() {})),
              buildTextField(_cepController, "CEP", isCep: true, onChangedState: () => setState(() {})),
              buildTextField(_telefoneJovemController, "Telefone do Jovem", onChangedState: () => setState(() {})),
              buildTextField(_telefonePaiController, "Telefone do Pai", onChangedState: () => setState(() {})),
              buildTextField(_telefoneMaeController, "Telefone da Mãe", onChangedState: () => setState(() {})),
              buildTextField(_escolaridadeController, "Escolaridade", onChangedState: () => setState(() {})),
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: const Color(0xFF0A63AC),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              buildTextField(_areaAprendizadoController, "Área de Aprendizado", onChangedState: () => setState(() {})),
              buildTextField(_horasTrabalhoController, "Horas de Trabalho", isHora: true, onChangedState: () => setState(() {})),
              buildTextField(_horasCursoController, "Horas de Curso", isHora: true, onChangedState: () => setState(() {})),
              buildTextField(_horasSemanaisController, "Horas Semanais", isHora: true, onChangedState: () => setState(() {})),
              buildTextField(_remuneracaoController, "Remuneração", isDinheiro: true, onChangedState: () => setState(() {})),
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
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
}