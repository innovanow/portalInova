import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inova/services/ocorrencia_service.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/widgets/widgets.dart';
import '../services/jovem_service.dart';
import '../services/modulo_service.dart';
import '../services/presenca_service.dart';
import '../widgets/drawer.dart';
import '../widgets/indicadores/indicador_pizza.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool modoDemo = false;
  final PresencaService _presencaService = PresencaService();
  final OcorrenciaService _ocorrenciaService = OcorrenciaService();
  final JovemService _jovemService = JovemService();
  final ModuloService _moduloService = ModuloService();
  late Future<Map<String, int>> _dadosPresenca = Future.value({});
  late Future<Map<String, int>> _dadosOcorrencias = Future.value({});
  late Future<Map<String, int>> _dadosPcd = Future.value({});
  late Future<Map<String, int>> _dadosJovenStatus = Future.value({});
  late Future<Map<String, int>> _dadosEstudando = Future.value({});
  late Future<Map<String, int>> _dadosTrabalhando = Future.value({});
  late Future<Map<String, int>> _dadosAssistencial = Future.value({});
  late Future<Map<String, int>> _dadosTurnoEscolar = Future.value({});
  late Future<Map<String, int>> _dadosNacionalidade = Future.value({});
  late Future<Map<String, int>> _dadosMoraCom = Future.value({});
  late Future<Map<String, int>> _dadosFilhos = Future.value({});
  late Future<Map<String, int>> _dadosCor = Future.value({});
  late Future<Map<String, int>> _dadosIdentidadeGenero = Future.value({});
  late Future<Map<String, int>> _dadosOrientacaoSexual = Future.value({});
  late Future<Map<String, int>> _dadosJovemPorEscola = Future.value({});
  late Future<Map<String, int>> _dadosJovemPorEmpresa = Future.value({});
  late Future<Map<String, int>> _dadosModulosPorProfessor = Future.value({});
  late Future<Map<String, int>> _dadosOcorrenciasResolvidas = Future.value({});
  late Future<Map<String, int>> _dadosJovensPorTurma = Future.value({});
  late Future<List<Map<String, dynamic>>> _dadosHistoricoPresencaJovem = Future.value([]);
  late Future<Map<String, int>> _dadosHistoricoOcorrenciaJovem = Future.value({});
  late Future<Map<String, int>> _dadosModulosParticipados = Future.value({});
  late Future<Map<String, int>> _dadosJovensPorModulo = Future.value({});
  late Future<Map<String, int>> _dadosOcorrenciasPorProfessor = Future.value({});
  late Future<Map<String, int>> _dadosIndiceFaltas = Future.value({});
  late Future<Map<String, int>> _dadosJovensPorTurmaEmpresa = Future.value({});
  late Future<Map<String, int>> _dadosPresensaMediaEmpresa = Future.value({});
  late Future<Map<String, int>> _dadosOcorrenciaEmpresa = Future.value({});
  late Future<Map<String, int>> _dadosFaltasJovensEmpresa = Future.value({});
  late Future<Map<String, int>> _dadosJovensPorTurmaEscola = Future.value({});
  late Future<Map<String, int>> _dadosPresencaMediaEscola = Future.value({});
  late Future<Map<String, int>> _dadosOcorrenciasEscola = Future.value({});
  late Future<Map<String, int>> _dadosHabilidadesInstituo = Future.value({});
  late Future<Map<String, int>> _dadosHabilidadesEmpresa = Future.value({});
  String? statusJovem;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {}); // força reconstrução após o login
    });
    if (auth.tipoUsuario == "administrador"){
      _dadosPresenca = _presencaService.buscarResumoPresenca();
      _dadosOcorrencias = _ocorrenciaService.buscarResumoOcorrencias();
      _dadosPcd = _jovemService.buscarResumoPCD();
      _dadosJovenStatus = _jovemService.buscarResumoStatus();
      _dadosEstudando = _jovemService.buscarResumoEstudando();
      _dadosAssistencial = _jovemService.buscarResumoBeneficioAssistencial();
      _dadosTurnoEscolar = _jovemService.buscarResumoTurnoEscola();
      _dadosNacionalidade = _jovemService.buscarResumoNacionalidade();
      _dadosMoraCom = _jovemService.buscarResumoMoraCom();
      _dadosFilhos = _jovemService.buscarResumoQuantidadeFilhos();
      _dadosCor = _jovemService.buscarResumoCorRaca();
      _dadosIdentidadeGenero = _jovemService.buscarResumoIdentidadeGenero();
      _dadosOrientacaoSexual = _jovemService.buscarResumoOrientacaoSexual();
      _dadosJovemPorEscola = _jovemService.buscarResumoPorEscola();
      _dadosJovemPorEmpresa = _jovemService.buscarResumoPorEmpresa();
      _dadosJovemPorEmpresa = _jovemService.buscarResumoPorEmpresa();
      _dadosModulosPorProfessor =
          _moduloService.buscarResumoModulosPorProfessor();
      _dadosOcorrenciasResolvidas = _ocorrenciaService.buscarResumoResolucao();
      _dadosJovensPorTurma = _jovemService.buscarResumoPorTurma();
      _dadosTrabalhando = _jovemService.buscarResumoTrabalhando();
      _dadosHabilidadesInstituo = _jovemService.buscarResumoHabilidadesDestaque();
    }
    if (auth.tipoUsuario == "jovem_aprendiz"){
      _carregarStatus();
      _dadosHistoricoPresencaJovem = _presencaService.buscarHistoricoPresencaPessoal();
      _dadosHistoricoOcorrenciaJovem = _ocorrenciaService.buscarResumoOcorrenciasPessoais();
      _dadosModulosParticipados = _moduloService.buscarModulosParticipadosPorNome();
    }
    if (auth.tipoUsuario == "professor"){
      _dadosJovensPorModulo = _moduloService.buscarTotalJovensPorModuloDoProfessor();
      _dadosOcorrenciasPorProfessor = _ocorrenciaService.buscarResumoOcorrenciasPorProfessor();
      _dadosIndiceFaltas = _presencaService.buscarTopAlunosComMaisFaltas();
    }
    if (auth.tipoUsuario == "empresa"){
      _dadosJovensPorTurmaEmpresa = _jovemService.buscarResumoJovensPorTurmaEmpresa();
      _dadosPresensaMediaEmpresa = _presencaService.buscarPresencaMediaPorEmpresa();
      _dadosOcorrenciaEmpresa = _ocorrenciaService.buscarOcorrenciasPorStatusEmpresa();
      _dadosFaltasJovensEmpresa = _presencaService.buscarTopFaltasPorJovensEmpresa();
      _dadosHabilidadesEmpresa = _jovemService.buscarResumoHabilidadesDestaqueEmpresa();
    }
    if (auth.tipoUsuario == "escola" || auth.tipoUsuario == "professor_externo") {
      _dadosJovensPorTurmaEscola = _jovemService.buscarResumoJovensPorTurmaEscola();
      _dadosPresencaMediaEscola = _presencaService.buscarPresencaMediaPorEscola();
      _dadosOcorrenciasEscola = _ocorrenciaService.buscarOcorrenciasPorStatusEscola();
    }
  }

  void _carregarStatus() async {
    final status = await _jovemService.buscarStatusDoJovemLogado();
    setState(() {
      statusJovem = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb ? false : true, // impede voltar
      child: Scaffold(
        extendBody: true,
        backgroundColor: Color(0xFF0A63AC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: const Color(0xFF0A63AC),
            title: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 Parte que rola horizontalmente
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text(
                                'Portal Instituto Inova',
                                style: TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                  color: Colors.white,
                                ),
                              ),
                              /*const SizedBox(width: 20),
                              buildAppBarItem(
                                Icons.person,
                                'Lista de Aprendiz',
                              ),
                              buildAppBarItem(
                                Icons.chat_bubble_outline,
                                'Ocorrências',
                              ),
                              buildAppBarItem(Icons.history, 'Histórico'),*/
                            ],
                          ),
                        ),
                      ),

                      // 🔹 Parte fixa que empurra os ícones para o final da tela
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /*buildIcon(Icons.message_outlined, context: context, "Mensagens"),
                          buildNotificationIcon(Icons.mark_chat_unread, 1),
                          buildIcon(Icons.campaign, "Campanhas", context: context),
                          buildIcon(Icons.notifications, "Notificações", context: context),
                          buildIcon(Icons.search, "Pesquisar", context: context),*/
                          buildIcon(Icons.logout, "Sair", context: context),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inova',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      buildIcon(Icons.logout, "Sair", context: context),
                    ],
                  );
                }
              },
            ),
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
                      icon: Icon(Icons.menu, color: Colors.white),
                      // Ícone do Drawer
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
        drawer: InovaDrawer(context: context),
        body: SafeArea(
          child: Container(
            transform: Matrix4.translationValues(0, -1, 0), //remove a linha branca
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
              alignment: Alignment.center,
              children: [
                // Onda Superior Laranja
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(height: 45, color: Colors.orange),
                  ),
                ),
                // Onda Superior Azul sobreposta
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(heightFactor: 0.6),
                    child: Container(height: 60, color: const Color(0xFF0A63AC)),
                  ),
                ),
                // Onda Inferior Laranja
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(flip: true),
                    child: Container(height: 60, color: Colors.orange),
                  ),
                ),
                // Onda Inferior Azul sobreposta
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(flip: true, heightFactor: 0.6),
                    child: Container(height: 60, color: const Color(0xFF0A63AC)),
                  ),
                ),
                // Conteúdo Centralizado
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 40, 10, 60),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (auth.tipoUsuario == "administrador")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosPresenca,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'Presentes': 120, 'Faltas': 30}
                                            : snapshot.data ??
                                                {'Presentes': 0, 'Faltas': 0};
          
                                    final nenhumDado = dados.values.every(
                                      (valor) => valor == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return Card(
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              'Presença Geral\nNenhum dado encontrado!',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Presença Geral',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosOcorrencias,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Colégio': 10,
                                              'Instituto': 5,
                                              'Empresa': 8,
                                            }
                                            : snapshot.data ??
                                                {
                                                  'Colégio': 0,
                                                  'Instituto': 0,
                                                  'Empresa': 0,
                                                };
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Ocorrências\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Porcentagem de Ocorrências',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosOcorrenciasResolvidas,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'Resolvidas': 18, 'Pendentes': 7}
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Ocorrências\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo:
                                          'Ocorrências Resolvidas vs Pendentes',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosJovenStatus,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'Ativos': 75, 'Inativos': 25}
                                            : snapshot.data ??
                                                {'Ativos': 0, 'Inativos': 0};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Status dos Jovens\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens Ativos e Inativos',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosEstudando,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Estudando': 60,
                                              'Não Estudando': 40,
                                            }
                                            : snapshot.data ??
                                                {
                                                  'Estudando': 0,
                                                  'Não Estudando': 0,
                                                };
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Estudando\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Estudando Atualmente',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "administrador")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosTrabalhando,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Trabalhando': 28,
                                              'Não trabalhando': 72,
                                            }
                                            : snapshot.data ??
                                                {
                                                  'Trabalhando': 0,
                                                  'Não trabalhando': 0,
                                                };
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Trabalho Atual\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Trabalhando Atualmente',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosJovemPorEscola,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Escola A': 40,
                                              'Escola B': 25,
                                              'Escola C': 10,
                                              'Não informado': 5,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Jovens por Escola\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens por Escola',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosJovemPorEmpresa,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Empresa X': 38,
                                              'Empresa Y': 22,
                                              'Empresa Z': 15,
                                              'Não informado': 7,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Jovens por Empresa\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens por Empresa',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosJovensPorTurma,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'TURMA A': 15,
                                              'TURMA B': 20,
                                              'TURMA C': 12,
                                              'Não informado': 3,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Jovens por Turma\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens por Turma',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosModulosPorProfessor,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Prof. Ana': 5,
                                              'Prof. Bruno': 3,
                                              'Prof. Carla': 4,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Módulos por Professor\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Módulos por Professor',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "administrador")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosTurnoEscolar,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Manhã': 35,
                                              'Tarde': 40,
                                              'Noite': 20,
                                              'Outro': 5,
                                            }
                                            : snapshot.data ??
                                                {
                                                  'Manhã': 0,
                                                  'Tarde': 0,
                                                  'Noite': 0,
                                                  'Outro': 0,
                                                };
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Turno Escolar\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Turno Escolar',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosNacionalidade,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'Brasileira': 90, 'Outra': 10}
                                            : snapshot.data ??
                                                {'Brasileira': 0, 'Outra': 0};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Nacionalidade\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Nacionalidade dos Jovens',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosCor,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Branca': 50,
                                              'Parda': 30,
                                              'Preta': 15,
                                              'Indígena': 3,
                                              'Amarela': 2,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Cor/Raça\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Cor/Raça dos Jovens',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosIdentidadeGenero,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Cisgênero': 70,
                                              'Transgênero': 5,
                                              'Não binário': 3,
                                              'Prefere não informar': 10,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Identidade de Gênero\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Identidade de Gênero dos Jovens',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosOrientacaoSexual,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Heterossexual': 60,
                                              'Homossexual': 8,
                                              'Bissexual': 5,
                                              'Prefere não informar': 12,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Orientação Sexual\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Orientação Sexual dos Jovens',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "administrador")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosPcd,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'PCD': 15, 'Não PCD': 85}
                                            : snapshot.data ??
                                                {'PCD': 0, 'Não PCD': 0};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'PCD\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens PCD',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosFilhos,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Sem filhos': 75,
                                              '1 filho': 10,
                                              '2 filhos': 8,
                                              '3 filhos': 4,
                                              '4+ filhos': 3,
                                            }
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Quantidade de Filhos\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Quantidade de Filhos',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosMoraCom,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {'Pai': 70, 'Mãe': 10, 'Outro': 8}
                                            : snapshot.data ?? {};
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Mora com quem\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Mora com quem?',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosAssistencial,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
          
                                    final dados =
                                        modoDemo
                                            ? {
                                              'Com benefício': 45,
                                              'Sem benefício': 55,
                                            }
                                            : snapshot.data ??
                                                {
                                                  'Com benefício': 0,
                                                  'Sem benefício': 0,
                                                };
          
                                    final nenhumDado = dados.values.every(
                                      (v) => v == 0,
                                    );
          
                                    if (nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Benefício Assistencial\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Recebe Benefício Assistencial',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosHabilidadesInstituo,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Adaptabilidade': 10,
                                    'Criatividade': 7,
                                    'Flexibilidade': 5,
                                    'Proatividade': 12,
                                    'Trabalho em equipe': 8,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (dados.isEmpty || nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Habilidades em Destaque\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Habilidades em Destaque',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "jovem_aprendiz")
                          if (statusJovem != null)
                            buildStatusCard(statusJovem),
                        if (auth.tipoUsuario == "jovem_aprendiz")
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _dadosHistoricoPresencaJovem,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
          
                              final dados =
                              modoDemo
                                  ? List.generate(
                                10,
                                    (i) => {
                                  'data': DateTime.now().subtract(
                                    Duration(days: 9 - i),
                                  ),
                                  'presente': i % 2 == 0,
                                },
                              )
                                  : snapshot.data ?? [];
          
                              if (dados.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Minha Frequência\nNenhum dado encontrado!',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
          
                              final spots =
                              dados
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => FlSpot(
                                  entry.key.toDouble(),
                                  entry.value['presente'] ? 1.0 : 0.0,
                                ),
                              )
                                  .toList();
          
                              return Card(
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Minha Frequência',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 200,
                                        child: LineChart(
                                          LineChartData(
                                            minY: 0,
                                            maxY: 1,
                                            lineTouchData: LineTouchData(enabled: false),
                                            titlesData: FlTitlesData(
                                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    switch (value.toInt()) {
                                                      case 0:
                                                        return const Text('Falta', style: TextStyle(fontSize: 12));
                                                      case 1:
                                                        return const Text('Presente', style: TextStyle(fontSize: 12));
                                                      default:
                                                        return const SizedBox.shrink();
                                                    }
                                                  },
                                                  reservedSize: 60,
                                                  interval: 1,
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  interval: 1,
                                                  getTitlesWidget: (value, meta) {
                                                    final idx = value.toInt();
                                                    if (idx >= 0 &&
                                                        idx < dados.length) {
                                                      final data =
                                                      dados[idx]['data']
                                                      as DateTime;
                                                      return Text(
                                                        '${data.day}/${data.month}',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox.shrink();
                                                  },
                                                ),
                                              ),
                                            ),
                                            gridData: FlGridData(show: true),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: spots,
                                                isCurved: true,
                                                color: Colors.blue,
                                                dotData: FlDotData(show: true),
                                                barWidth: 3,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        if (auth.tipoUsuario == "jovem_aprendiz")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                future: _dadosModulosParticipados,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Comunicação': 1,
                                    'Trabalho em equipe': 1,
                                    'Ética profissional': 1,
                                  }
                                      : snapshot.data ?? {};
          
                                  if (dados.isEmpty) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Módulos Participados\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Módulos Participados',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosHistoricoOcorrenciaJovem,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final dados = modoDemo
                                        ? {
                                      'Instituto': 2,
                                      'Escola': 1,
                                      'Empresa': 3,
                                    }
                                        : snapshot.data ?? {};

                                    final nenhumDado = dados.values.every((v) => v == 0);

                                    if (dados.isEmpty || nenhumDado) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Ocorrências Pessoais\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }

                                    return IndicadorPizza(
                                      titulo: 'Minhas Ocorrências',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "professor")
                          SizedBox(
                            width: 600,
                            height: 150,
                            child: Card(
                              margin: const EdgeInsets.all(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_camera_rounded, color: Color(0xFF0A63AC), size: 30),
                                    Text(
                                      "Lembre-se de enviar as fotos das turmas\nno menu Meus Módulos",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (auth.tipoUsuario == "professor")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosJovensPorModulo,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
          
                                    final dados = modoDemo
                                        ? {
                                      'Comunicação': 12,
                                      'Cidadania': 10,
                                      'Projeto de vida': 8,
                                    }
                                        : snapshot.data ?? {};
          
                                    if (dados.isEmpty) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Jovens por Módulo\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Jovens por Módulo',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                                FutureBuilder<Map<String, int>>(
                                  future: _dadosIndiceFaltas,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
          
                                    final dados = modoDemo
                                        ? {
                                      'João Silva': 6,
                                      'Ana Costa': 5,
                                      'Carlos M.': 4,
                                      'L. Rodrigues': 4,
                                      'F. Souza': 3,
                                    }
                                        : snapshot.data ?? {};
          
                                    if (dados.isEmpty) {
                                      return const Card(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            'Alunos com mais faltas\nNenhum dado encontrado!',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }
          
                                    return IndicadorPizza(
                                      titulo: 'Alunos com Mais Faltas',
                                      dados: dados,
                                      cores: gerarCoresRGB(dados.keys),
                                    );
                                  },
                                ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosOcorrenciasPorProfessor,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Resolvidas': 5,
                                    'Pendentes': 3,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (dados.isEmpty || nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Ocorrências Lançadas\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Ocorrências Lançadas por Você',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "empresa")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              FutureBuilder<Map<String, int>>(
                            future: _dadosJovensPorTurmaEmpresa,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
          
                              final dados = modoDemo
                                  ? {
                                'Turma A': 8,
                                'Turma B': 5,
                                'Turma C': 3,
                              }
                                  : snapshot.data ?? {};
          
                              if (dados.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Jovens por Turma\nNenhum dado encontrado!',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
          
                              return IndicadorPizza(
                                titulo: 'Jovens por Turma',
                                dados: dados,
                                cores: gerarCoresRGB(dados.keys),
                              );
                            },
                            ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosPresensaMediaEmpresa,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Presentes': 84,
                                    'Faltas': 16,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Presença Geral\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Presença Geral dos Jovens',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosOcorrenciaEmpresa,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Resolvidas': 4,
                                    'Pendentes': 2,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Ocorrências\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Ocorrências da Empresa',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosFaltasJovensEmpresa,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Lucas Pereira': 7,
                                    'Joana Silva': 6,
                                    'M. Oliveira': 5,
                                    'Ana Costa': 4,
                                    'C. Souza': 3,
                                  }
                                      : snapshot.data ?? {};
          
                                  if (dados.isEmpty) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Jovens com mais faltas\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Jovens com Mais Faltas',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosHabilidadesEmpresa,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Adaptabilidade': 5,
                                    'Criatividade': 2,
                                    'Flexibilidade': 3,
                                    'Proatividade': 4,
                                    'Trabalho em equipe': 6,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (dados.isEmpty || nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Habilidades em Destaque\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Habilidades em Destaque dos Jovens da Empresa',
                                    dados: dados,
                                    cores: gerarCoresRGB(dados.keys),
                                  );
                                },
                              ),
                              ],
                            ),
                          ),
                        if (auth.tipoUsuario == "escola" || auth.tipoUsuario == "professor_externo")
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              FutureBuilder<Map<String, int>>(
                            future: _dadosJovensPorTurmaEscola,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
          
                              final dados = modoDemo
                                  ? {
                                'Turma 101': 10,
                                'Turma 102': 7,
                                'Turma 103': 5,
                              }
                                  : snapshot.data ?? {};
          
                              if (dados.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Jovens por Turma\nNenhum dado encontrado!',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }
          
                              return IndicadorPizza(
                                titulo: 'Jovens por Turma',
                                dados: dados,
                                cores: gerarCoresRGB(dados.keys),
                              );
                            },
                            ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosPresencaMediaEscola,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Presentes': 65,
                                    'Faltas': 15,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Presença Geral\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Presença Geral dos Jovens',
                                    dados: dados,
                                    cores: {
                                      'Presentes': Colors.green,
                                      'Faltas': Colors.red,
                                    },
                                  );
                                },
                              ),
                              FutureBuilder<Map<String, int>>(
                                future: _dadosOcorrenciasEscola,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
          
                                  final dados = modoDemo
                                      ? {
                                    'Resolvidas': 3,
                                    'Pendentes': 2,
                                  }
                                      : snapshot.data ?? {};
          
                                  final nenhumDado = dados.values.every((v) => v == 0);
          
                                  if (nenhumDado) {
                                    return const Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Ocorrências da Escola\nNenhum dado encontrado!',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
          
                                  return IndicadorPizza(
                                    titulo: 'Ocorrências da Escola',
                                    dados: dados,
                                    cores: {
                                      'Resolvidas': Colors.green,
                                      'Pendentes': Colors.red,
                                    },
                                  );
                                },
                              ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
