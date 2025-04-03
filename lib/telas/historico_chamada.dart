import 'package:flutter/material.dart';
import 'package:inova/telas/presenca.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/presenca_service.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';

class HistoricoChamadasPage extends StatefulWidget {
  final String professorId;

  const HistoricoChamadasPage({super.key, required this.professorId});

  @override
  State<HistoricoChamadasPage> createState() => _HistoricoChamadasPageState();
}

class _HistoricoChamadasPageState extends State<HistoricoChamadasPage> {
  final PresencaService _presencaService = PresencaService();
  late Future<List<Map<String, dynamic>>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _historicoFuture = _presencaService.buscarHistoricoChamadas(
      widget.professorId,
    );
  }

  Future<void> _refazerChamada(
    DateTime data,
    String moduloId,
    String turmaId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Color(0xFF0A63AC),
            title: const Text(
              "Tem certeza que deseja remover a chamada e refazê-la?",
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'FuturaBold',
              ),
            ),
            actions: [
              TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.orange,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Refazer',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'FuturaBold',
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _presencaService.removerChamada(data, moduloId);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => RegistrarPresencaPage(
                  professorId: auth.idUsuario.toString(),
                ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A63AC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppBar(
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: const Color(0xFF0A63AC),
            title: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Histórico de Presenças",
                      style: TextStyle(
                        fontFamily: 'FuturaBold',
                        fontWeight: FontWeight.bold,
                        fontSize: constraints.maxWidth > 800 ? 20 : 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
            // Evita que o Flutter gere um botão automático
            leading: Builder(
              builder:
                  (context) => Tooltip(
                    message: "Voltar", // Texto do tooltip
                    child: IconButton(
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      enableFeedback: false,
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      // Ícone do Drawer
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (_) => RegistrarPresencaPage(
                                  professorId: auth.idUsuario.toString(),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 40, 10, 60),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _historicoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma presença registrada.',
                        style: TextStyle(
                          fontFamily: 'FuturaBold',
                          fontSize: 18,
                          color: Colors.black,
                        )),
                    );
                  }

                  final historico = snapshot.data!;

                  return ListView.builder(
                    itemCount: historico.length,
                    itemBuilder: (context, index) {
                      final item = historico[index];
                      final data = DateTime.parse(item['data']);
                      final presentes = item['presentes'] ?? 0;
                      final faltas = item['faltas'] ?? 0;
                      final total = presentes + faltas;
                      final percentual = total == 0 ? 0.0 : presentes / total;
                      final nomesFaltantes = item['faltantes'] ?? [];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('dd/MM/yyyy').format(data)} - ${item['modulo_nome']} (Turma ${item['codigo_turma']})',
                                      style: const TextStyle(
                                        fontFamily: 'FuturaBold',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    enableFeedback: false,
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refazer chamada',
                                    onPressed:
                                        () => _refazerChamada(
                                          data,
                                          item['modulo_id'],
                                          item['turma_id'],
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircularPercentIndicator(
                                    radius: 30,
                                    lineWidth: 5,
                                    percent: percentual,
                                    center: Text(
                                      '${(percentual * 100).toStringAsFixed(0)}%',
                                    ),
                                    progressColor: Colors.green,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Presentes: $presentes'),
                                        Text('Faltas: $faltas'),
                                        if (nomesFaltantes.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Jovens faltantes:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ...List.generate(
                                            nomesFaltantes.length,
                                            (i) =>
                                                Text('👤 ${nomesFaltantes[i]}'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
