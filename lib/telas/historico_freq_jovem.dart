import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/presenca_service.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';

class HistoricoFrequenciaJovemPage extends StatefulWidget {
  final String jovemId;
  const HistoricoFrequenciaJovemPage({super.key, required this.jovemId});

  @override
  State<HistoricoFrequenciaJovemPage> createState() => _HistoricoFrequenciaJovemPageState();
}

class _HistoricoFrequenciaJovemPageState extends State<HistoricoFrequenciaJovemPage> {
  final PresencaService _presencaService = PresencaService();
  late Future<List<Map<String, dynamic>>> _frequenciasFuture;

  @override
  void initState() {
    super.initState();
    _frequenciasFuture = _presencaService.buscarFrequenciaDoJovem(widget.jovemId);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb ? false : true, // impede voltar
      child: Scaffold(
        backgroundColor: Color(0xFF0A63AC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
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
                      "Meu Histórico de Presenças",
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
                  padding: const EdgeInsets.fromLTRB(10, 40, 10, 60),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _frequenciasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        if (kDebugMode) {
                          print('Erro: \n${snapshot.error}');
                        }
                        return Center(child: Text('Erro: \n${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Nenhum registro de frequência encontrado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'FuturaBold',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,)));
                      }
          
                      final registros = snapshot.data!;
          
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: registros.length,
                        itemBuilder: (context, index) {
                          final item = registros[index];
                          final data = DateTime.parse(item['data']);
                          final presente = item['presente'] == true;
                          final modulo = item['modulo_nome'] ?? 'Módulo';
                          final professor = item['professor_nome'] ?? 'Professor';
          
                          return Card(
                            color: presente ? Colors.green[300] : Colors.red[300],
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(DateFormat('dd/MM/yyyy').format(data),
                                style: const TextStyle(
                                  fontFamily: 'FuturaBold',
                                )),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Módulo: $modulo"),
                                  Text('Professor: $professor'),
                                  Text(presente ? '✅ Presente' : '⛔ Falta'),
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
        ),
      ),
    );
  }
}
