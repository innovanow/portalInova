import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../services/presenca_service.dart';
import '../widgets/drawer.dart';
import '../widgets/filter.dart';
import '../widgets/wave.dart';

class HistoricoFrequenciaJovemPage extends StatefulWidget {
  final String jovemId;
  const HistoricoFrequenciaJovemPage({super.key, required this.jovemId});

  @override
  State<HistoricoFrequenciaJovemPage> createState() => _HistoricoFrequenciaJovemPageState();
}

class _HistoricoFrequenciaJovemPageState extends State<HistoricoFrequenciaJovemPage> {
  final PresencaService _presencaService = PresencaService();
  bool modoPesquisa = false;
  bool modoPesquisa2 = false;
  List<Map<String, dynamic>> _frequencias = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _frequenciasFiltrados = [];
  final TextEditingController _pesquisaController = TextEditingController();
  final DateTime _dataSelecionada = DateTime.now();

  @override
  void initState() {
    _carregarFrequencias();
    super.initState();
  }

  Future<void> _carregarFrequencias() async {
    if (auth.tipoUsuario == "jovem_aprendiz") {
      final frequencias = await _presencaService.buscarFrequenciaDoJovem(widget.jovemId);
      setState(() {
        _frequencias = frequencias;
        _frequenciasFiltrados = List.from(_frequencias);
        _isFetching = false;
      });
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: const DatePickerThemeData(
                confirmButtonStyle: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
                ),
                cancelButtonStyle: ButtonStyle(
                  textStyle: WidgetStatePropertyAll(TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
                ),

            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      if (kDebugMode) {
        print("Data selecionada: $data");
      }
      modoPesquisa2 = true;
      filtrarLista(
        query: data.toString(),
        listaOriginal: _frequencias,
        atualizarListaFiltrada: (novaLista) {
          setState(() => _frequenciasFiltrados = novaLista);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _frequenciasFiltrados = List.from(_frequencias); // 🔹 Restaura a lista original
          });
        }
      },
      child: PopScope(
        canPop: kIsWeb ? false : true, // impede voltar
        child: Scaffold(
          backgroundColor: Color(0xFF0A63AC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: AppBar(
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: const Color(0xFF0A63AC),
              title:
              modoPesquisa
                  ? TextField(
                controller: _pesquisaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Pesquisar...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  filtrarLista(
                    query: value,
                    listaOriginal: _frequencias,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _frequenciasFiltrados = novaLista);
                    },
                  );
                },
              )
                  : Text(
                'Histórico de Presenças',
                style: TextStyle(
                  fontFamily: 'FuturaBold',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false,
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
                    _frequencias,
                        (novaLista) => setState(() {
                      _frequenciasFiltrados = novaLista;
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
                    modoPesquisa = true; //
                  }),
                ),
                modoPesquisa2 == false ?
                IconButton(
                  tooltip: "Filtrar por Data",
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  enableFeedback: false,
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  onPressed: () => _selecionarData()
                ) : IconButton(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  enableFeedback: false,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => fecharPesquisa(
                    setState,
                    _pesquisaController,
                    _frequencias,
                        (novaLista) => setState(() {
                      _frequenciasFiltrados = novaLista;
                      modoPesquisa2 = false; // 🔹 Agora o modo pesquisa é atualizado corretamente
                    }),
                  ),

                )
              ],
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
                    padding: const EdgeInsets.fromLTRB(5, 40, 5, 15),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width,
                            height: auth.tipoUsuario == "administrador"
                                ? constraints.maxHeight - 100
                                : constraints.maxHeight - 50,
                            child: _isFetching
                                ? const Center(
                              child: CircularProgressIndicator(),)
                                : SuperListView.builder(
                              itemCount: _frequenciasFiltrados.length,
                              itemBuilder: (context, index) {
                                final item = _frequenciasFiltrados[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    title: Text(
                                        DateFormat('dd/MM/yyyy').format(DateTime.parse(item['data'])),
                                        style: const TextStyle(
                                          fontFamily: 'FuturaBold',
                                        )),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Jovem: ${item['jovem_nome']}"),
                                        Text("Módulo: ${item['modulo_nome']}"),
                                        Text('Professor: ${item['professor_nome']}'),
                                        Text(item['presente'] ? '✅ Presente' : '⛔ Falta'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
