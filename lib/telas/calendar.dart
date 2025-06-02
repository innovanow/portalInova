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
  Map<DateTime, String> diasModulos = {};
  Map<String, Color> coresModulos = {};
  int anoAtual = DateTime.now().year;
  final DateTime hoje = DateTime.now(); // Data de hoje

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  Future<void> _carregarModulos() async {
    final userId = supabase.auth.currentUser?.id;
    final userType = (await supabase
        .from('users')
        .select('tipo')
        .eq('id', userId.toString())
        .maybeSingle())?['tipo'];

    List<Map<String, dynamic>> modulos = [];

    if (userType == 'professor') {
      modulos = await supabase
          .from('modulos')
          .select('nome, datas, cor')
          .eq('status', 'ativo')
          .eq('professor_id', userId.toString());
    } else if (userType == 'jovem_aprendiz') {
      final jovem = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('id', userId.toString())
          .maybeSingle();

      final turmaId = jovem?['turma_id'];

      if (turmaId != null) {
        final modulosTurmas = await supabase
            .from('modulos_turmas')
            .select('modulo_id')
            .eq('turma_id', turmaId);

        final moduloIds = modulosTurmas.map((e) => e['modulo_id']).toList();

        if (moduloIds.isNotEmpty) {
          modulos = await supabase
              .from('modulos')
              .select('nome, datas, cor')
              .inFilter('id', moduloIds)
              .eq('status', 'ativo');
        }
      }
    } else if (userType == 'empresa') {
      final jovens = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('empresa_id', userId.toString());

      final turmaIds = jovens.map((e) => e['turma_id']).where((id) => id != null).toSet().toList();

      if (turmaIds.isNotEmpty) {
        final modulosTurmas = await supabase
            .from('modulos_turmas')
            .select('modulo_id')
            .inFilter('turma_id', turmaIds);

        final moduloIds = modulosTurmas.map((e) => e['modulo_id']).toSet().toList();

        if (moduloIds.isNotEmpty) {
          modulos = await supabase
              .from('modulos')
              .select('nome, datas, cor')
              .inFilter('id', moduloIds)
              .eq('status', 'ativo');
        }
      }
    } else if (userType == 'escola') {
      final jovens = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('escola_id', userId.toString());

      final turmaIds = jovens.map((e) => e['turma_id']).where((id) => id != null).toSet().toList();

      if (turmaIds.isNotEmpty) {
        final modulosTurmas = await supabase
            .from('modulos_turmas')
            .select('modulo_id')
            .inFilter('turma_id', turmaIds);

        final moduloIds = modulosTurmas.map((e) => e['modulo_id']).toSet().toList();

        if (moduloIds.isNotEmpty) {
          modulos = await supabase
              .from('modulos')
              .select('nome, datas, cor')
              .inFilter('id', moduloIds)
              .eq('status', 'ativo');
        }
      }
    } else {
      // Administrador ou Instituto
      modulos = await supabase
          .from('modulos')
          .select('nome, datas, cor')
          .eq('status', 'ativo');
    }

    Map<DateTime, String> novosDiasModulos = {};

    for (var modulo in modulos) {
      final nomeModulo = modulo['nome'];
      final List<dynamic>? datas = modulo['datas'];
      final String? corHex = modulo['cor'];

      if (datas != null && datas.length.isEven) {
        for (int i = 0; i < datas.length; i += 2) {
          final DateTime inicio = DateTime.parse(datas[i]);
          final DateTime fim = DateTime.parse(datas[i + 1]);

          // Marca todos os dias entre início e fim (inclusive)
          for (DateTime dia = inicio;
          !dia.isAfter(fim);
          dia = dia.add(const Duration(days: 1))) {
            final diaSemHora = DateTime(dia.year, dia.month, dia.day);
            novosDiasModulos[diaSemHora] = nomeModulo;
          }
        }
      }

      if (corHex != null && !coresModulos.containsKey(nomeModulo)) {
        coresModulos[nomeModulo] = _hexToColor(corHex);
      }
    }

    setState(() {
      diasModulos = novosDiasModulos;
    });
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex));
  }

  void _mudarAno(int incremento) {
    setState(() {
      anoAtual += incremento;
    });
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;

    int colunas = larguraTela > 1200 ? 4 : larguraTela > 800 ? 3 : 2;
    double alturaCardBase = (alturaTela * 0.20).clamp(180, 320);

    return PopScope(
      canPop: kIsWeb ? false : true, // impede voltar
      child: Scaffold(
        backgroundColor: Color(0xFF0A63AC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            backgroundColor: const Color(0xFF0A63AC),
            title: LayoutBuilder(
                builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(constraints.maxWidth > 800 ?  'Calendário Inova $anoAtual' : '$anoAtual',
                      style: TextStyle(
                        fontFamily: 'FuturaBold',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                            onPressed: () => _mudarAno(-1), icon: Icon(Icons.arrow_back)),
                        IconButton(
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            enableFeedback: false,
                            onPressed: () => _mudarAno(1), icon: Icon(Icons.arrow_forward)),
                      ],
                    ),
                  ],
                );
              }
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
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colunas,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              DateTime primeiroDiaMes = DateTime(anoAtual, index + 1, 1);
                              return _buildCalendarioMes(primeiroDiaMes, alturaCardBase);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLegenda(),
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

  /// Legenda do calendário
  Widget _buildLegenda() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        // Exibe os módulos cadastrados com suas cores
        ...coresModulos.entries.map((entry) {
          return _buildLegendaItem(entry.value, entry.key);
        }),

        // Adiciona a indicação da data de hoje
        _buildLegendaItem(Colors.orange, "Hoje - ${DateFormat('d MMMM yyyy', 'pt_BR').format(DateTime.now())}"),
      ],
    );
  }

  Widget _buildLegendaItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }


  Widget _buildCalendarioMes(DateTime primeiroDiaMes, double alturaBase) {
    int ultimoDiaMes = DateTime(primeiroDiaMes.year, primeiroDiaMes.month + 1, 0).day;
    List<DateTime> diasDoMes = List.generate(
      ultimoDiaMes,
          (index) => DateTime(primeiroDiaMes.year, primeiroDiaMes.month, index + 1),
    );

    int primeiroDiaSemana = primeiroDiaMes.weekday;
    List<DateTime?> diasComEspacos = List.generate(primeiroDiaSemana % 7, (index) => null);
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
              decoration: BoxDecoration(
                color: const Color(0xFF0A63AC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Text(
                DateFormat.yMMMM('pt_BR').format(primeiroDiaMes).toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle
                  (color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  fontFamily: 'FuturaBold',
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text("D", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("T", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("Q", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("Q", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("S", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                itemBuilder: (context, index) {
                  DateTime? dia = diasComEspacos[index];
                  bool isHoje = dia != null &&
                      dia.year == hoje.year &&
                      dia.month == hoje.month &&
                      dia.day == hoje.day;
                  Color corFundo = isHoje ? Colors.orange : (dia != null ? coresModulos[diasModulos[dia] ?? ""] ?? Colors.transparent : Colors.transparent);

                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: corFundo, shape: BoxShape.rectangle),
                    child: Text(dia != null ? "${dia.day}" : ""),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
