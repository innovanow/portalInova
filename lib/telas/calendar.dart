import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';

class ModulosCalendarScreen extends StatefulWidget {
  const ModulosCalendarScreen({super.key});

  @override
  State<ModulosCalendarScreen> createState() => _ModulosCalendarScreenState();
}

class _ModulosCalendarScreenState extends State<ModulosCalendarScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<DateTime, List<Map<String, dynamic>>> diasModulos = {};
  Map<String, Color> coresModulos = {};
  int anoAtual = DateTime.now().year;
  final DateTime hoje = DateTime.now();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarModulos() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final userType = (await supabase
        .from('users')
        .select('tipo')
        .eq('id', userId)
        .maybeSingle())?['tipo'];

    List<Map<String, dynamic>> modulos = [];

    if (userType == 'professor') {
      modulos = await supabase
          .from('modulos')
          .select('id, nome, datas, cor')
          .eq('status', 'ativo')
          .eq('professor_id', userId);
    } else if (userType == 'jovem_aprendiz') {
      final jovem = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('id', userId)
          .single();
      final turmaId = jovem['turma_id'];
      if (turmaId != null) {
        modulos = await supabase
            .from('modulos')
            .select('id, nome, datas, cor')
            .eq('turma_id', turmaId)
            .eq('status', 'ativo');
      }
    } else if (userType == 'empresa') {
      final jovensResponse = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('empresa_id', userId);
      final turmaIds = jovensResponse
          .map((jovem) => jovem['turma_id'])
          .where((id) => id != null)
          .toSet()
          .toList();
      if (turmaIds.isNotEmpty) {
        modulos = await supabase
            .from('modulos')
            .select('id, nome, datas, cor')
            .inFilter('turma_id', turmaIds)
            .eq('status', 'ativo');
      }
    } else if (userType == 'escola') {
      final jovensResponse = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('escola_id', userId);
      final turmaIds = jovensResponse
          .map((jovem) => jovem['turma_id'])
          .where((id) => id != null)
          .toSet()
          .toList();
      if (turmaIds.isNotEmpty) {
        modulos = await supabase
            .from('modulos')
            .select('id, nome, datas, cor')
            .inFilter('turma_id', turmaIds)
            .eq('status', 'ativo');
      }
    } else {
      modulos = await supabase
          .from('modulos')
          .select('id, nome, datas, cor')
          .eq('status', 'ativo');
    }

    Map<DateTime, List<Map<String, dynamic>>> novosDiasModulos = {};
    for (var moduloData in modulos) {
      // AJUSTE: Garante que o item da lista é um Map antes de usá-lo.
      final Map<String, dynamic> modulo = moduloData;
      final idModulo = modulo['id'];
      final nomeModulo = modulo['nome'];
      final List<dynamic>? datas = modulo['datas'];
      final String? corHex = modulo['cor'];

      if (datas != null) {
        for (final dataStr in datas) {
          if (dataStr != null) {
            final dia = DateTime.parse(dataStr.toString());
            final diaSemHora = DateTime(dia.year, dia.month, dia.day);
            final moduloInfo = {'id': idModulo, 'nome': nomeModulo, 'horario': dia};

            if (novosDiasModulos.containsKey(diaSemHora)) {
              if (!novosDiasModulos[diaSemHora]!.any((m) => m['id'] == idModulo)) {
                novosDiasModulos[diaSemHora]!.add(moduloInfo);
              }
            } else {
              novosDiasModulos[diaSemHora] = [moduloInfo];
            }
          }
        }
      }

      if (corHex != null && !coresModulos.containsKey(nomeModulo)) {
        coresModulos[nomeModulo] = _hexToColor(corHex);
      }
    }

    if (mounted) {
      setState(() {
        diasModulos = novosDiasModulos;
      });
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex));
  }

  void _mudarAno(int incremento) {
    setState(() {
      anoAtual += incremento;
    });
  }

  Future<int> _getContagemJovens(String moduloId) async {
    try {
      final moduloResponse = await supabase
          .from('modulos')
          .select('turma_id')
          .eq('id', moduloId)
          .single();
      final turmaId = moduloResponse['turma_id'];
      if (turmaId == null) return 0;

      final count = await supabase
          .from('jovens_aprendizes')
          .count(CountOption.exact)
          .eq('turma_id', turmaId);

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar contagem de jovens: $e');
      }
      return 0;
    }
  }

  void _mostrarDialogoModulos(
      BuildContext context, DateTime dia, List<Map<String, dynamic>> modulos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Módulos em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dia)}",
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 800 ? 20 : 15,
                    color: Colors.white,
                    fontFamily: 'LeagueSpartan',
                  ),
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 800 ? 400 : 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: modulos.length,
              itemBuilder: (BuildContext context, int index) {
                final moduloInfo = modulos[index];
                final nomeModulo = moduloInfo['nome'] as String;
                final idModulo = moduloInfo['id'] as String;

                final DateTime horario = moduloInfo['horario'] as DateTime;
                final String horarioFormatado = DateFormat('HH:mm', 'pt_BR').format(horario);

                return FutureBuilder<int>(
                  future: _getContagemJovens(idModulo),
                  builder: (context, snapshot) {
                    String subtitleText = 'Carregando...';
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        subtitleText = 'Erro ao carregar';
                      } else {
                        final count = snapshot.data ?? 0;
                        subtitleText = 'Início: $horarioFormatado h(s) - $count ${count == 1 ? 'jovem' : 'jovens'}';
                      }
                    }
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          color: coresModulos[nomeModulo] ?? Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      title: Text(nomeModulo,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 800 ? 18 : 14,
                            color: Colors.white,
                          )),
                      subtitle: Text(subtitleText,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 800 ? 14 : 12,
                            color: Colors.white70,
                          )),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;

    int colunas = larguraTela > 1200 ? 4 : larguraTela > 800 ? 3 : 2;
    double alturaCardBase = (alturaTela * 0.20).clamp(180, 320);

    return PopScope(
      canPop: kIsWeb ? false : true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A63AC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            backgroundColor: const Color(0xFF0A63AC),
            title: LayoutBuilder(builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    constraints.maxWidth > 800
                        ? 'Calendário Inova $anoAtual'
                        : '$anoAtual',
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          onPressed: () => _mudarAno(-1),
                          icon: const Icon(Icons.arrow_back)),
                      IconButton(
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          onPressed: () => _mudarAno(1),
                          icon: const Icon(Icons.arrow_forward)),
                    ],
                  ),
                ],
              );
            }),
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (context) => Tooltip(
                message: "Abrir Menu",
                child: IconButton(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  enableFeedback: false,
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Scaffold.of(
                      context,
                    ).openDrawer();
                  },
                ),
              ),
            ),
          ),
        ),
        drawer: InovaDrawer(context: context),
        body: SafeArea(
          child: Container(
            transform: Matrix4.translationValues(0, -1, 0),
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
                    child: Container(height: 60, color: const Color(0xFF0A63AC)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 60),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colunas,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              DateTime primeiroDiaMes =
                              DateTime(anoAtual, index + 1, 1);
                              return _buildCalendarioMes(
                                  primeiroDiaMes, alturaCardBase);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: _buildLegenda(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegenda() {
    final List<MapEntry<String, Color>> moduleEntries =
    coresModulos.entries.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.offset - 150,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...moduleEntries
                    .map((entry) => _buildLegendaItem(entry.value, entry.key)),
                _buildLegendaItem(Colors.orange,
                    "Hoje - ${DateFormat('d MMMM', 'pt_BR').format(DateTime.now())}"),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.offset + 150,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLegendaItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            softWrap: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarioMes(DateTime primeiroDiaMes, double alturaBase) {
    int ultimoDiaMes =
        DateTime(primeiroDiaMes.year, primeiroDiaMes.month + 1, 0).day;
    List<DateTime> diasDoMes = List.generate(
      ultimoDiaMes,
          (index) => DateTime(primeiroDiaMes.year, primeiroDiaMes.month, index + 1),
    );

    int primeiroDiaSemana = primeiroDiaMes.weekday;
    List<DateTime?> diasComEspacos =
    List.generate(primeiroDiaSemana % 7, (index) => null);
    diasComEspacos.addAll(diasDoMes);

    int totalLinhas = ((diasComEspacos.length / 7).ceil());
    double alturaCard = alturaBase + (totalLinhas > 5 ? 40 : 0);

    return SizedBox(
      height: alturaCard,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0A63AC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Text(
                DateFormat.yMMMM('pt_BR').format(primeiroDiaMes).toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("D",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("T",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("Q",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("Q",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S",
                      style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: diasComEspacos.length,
                // INÍCIO DA MODIFICAÇÃO: Lógica de construção do dia do calendário
                itemBuilder: (context, index) {
                  final DateTime? dia = diasComEspacos[index];
                  if (dia == null) {
                    return const SizedBox.shrink();
                  }

                  final bool isHoje = dia.year == hoje.year &&
                      dia.month == hoje.month &&
                      dia.day == hoje.day;

                  final List<Map<String, dynamic>>? modulosDoDia = diasModulos[dia];

                  Widget backgroundWidget = const SizedBox.shrink();
                  Color textColor = Colors.black; // Cor padrão do texto
                  bool hasBackground = false;

                  if (isHoje) {
                    // Se for o dia atual, o fundo é laranja
                    backgroundWidget = Container(color: Colors.orange);
                    hasBackground = true;
                  } else if (modulosDoDia != null && modulosDoDia.isNotEmpty) {
                    // Coleta as cores dos módulos do dia, evitando duplicatas
                    final List<Color> moduleColors = modulosDoDia
                        .map((modulo) => coresModulos[modulo['nome']] ?? Colors.transparent)
                        .where((c) => c != Colors.transparent)
                        .toSet()
                        .toList();

                    if (moduleColors.isNotEmpty) {
                      hasBackground = true;
                      if (moduleColors.length == 1) {
                        // Se houver apenas uma cor, usa um Container simples
                        backgroundWidget = Container(color: moduleColors.first);
                      } else {
                        // NOVO: Se houver várias cores, cria uma Row para dividi-las
                        backgroundWidget = Row(
                          children: moduleColors.map((color) {
                            return Expanded(child: Container(color: color));
                          }).toList(),
                        );
                      }
                    }
                  }

                  // Se houver qualquer cor de fundo, o texto do dia fica branco
                  if (hasBackground) {
                    textColor = Colors.white;
                  }

                  return GestureDetector(
                    onTap: () {
                      if (modulosDoDia != null && modulosDoDia.isNotEmpty) {
                        _mostrarDialogoModulos(context, dia, modulosDoDia);
                      }
                    },
                    // Usamos um Stack para colocar o número sobre o fundo colorido
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // O widget de fundo (pode ser um Container ou uma Row)
                        backgroundWidget,
                        // O texto com o número do dia
                        Text(
                          "${dia.day}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                // FIM DA MODIFICAÇÃO
              ),
            ),
          ],
        ),
      ),
    );
  }
}
