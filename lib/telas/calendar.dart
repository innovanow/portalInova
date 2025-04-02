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
    final response = await supabase.from('modulos').select('nome, data_inicio, data_termino, dia_semana, cor').eq('status', 'ativo');

    Map<DateTime, String> novosDiasModulos = {};

    for (var modulo in response) {
      DateTime inicio = DateTime.parse(modulo['data_inicio']);
      DateTime termino = DateTime.parse(modulo['data_termino']);
      String? diaSemana = modulo['dia_semana'];
      String nomeModulo = modulo['nome'];
      String? corHex = modulo['cor'];

      if (diaSemana != null) {
        for (var dia in _getDiasSemanaNoIntervalo(inicio, termino, diaSemana)) {
          novosDiasModulos[dia] = nomeModulo;
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

  Set<DateTime> _getDiasSemanaNoIntervalo(DateTime inicio, DateTime termino, String diaSemana) {
    Set<DateTime> diasMarcados = {};
    Map<String, int> dias = {
      'Domingo': DateTime.sunday,
      'Segunda-feira': DateTime.monday,
      'Terça-feira': DateTime.tuesday,
      'Quarta-feira': DateTime.wednesday,
      'Quinta-feira': DateTime.thursday,
      'Sexta-feira': DateTime.friday,
      'Sábado': DateTime.saturday,
    };

    int diaSemanaInt = dias[diaSemana] ?? 0;

    for (DateTime date = inicio; !date.isAfter(termino); date = date.add(const Duration(days: 1))) {
      if (date.weekday == diaSemanaInt) {
        diasMarcados.add(DateTime(date.year, date.month, date.day));
      }
    }
    return diasMarcados;
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
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(0xFF0A63AC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppBar(
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
