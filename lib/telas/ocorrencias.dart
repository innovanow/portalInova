import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../services/ocorrencia_service.dart';
import '../widgets/drawer.dart';
import '../widgets/filter.dart';
import '../widgets/wave.dart';

class OcorrenciasPage extends StatefulWidget {
  const OcorrenciasPage({super.key});

  @override
  State<OcorrenciasPage> createState() => _OcorrenciasPageState();
}

class _OcorrenciasPageState extends State<OcorrenciasPage> {
  final OcorrenciaService _ocorrenciaService = OcorrenciaService();
  bool modoPesquisa = false;
  bool modoPesquisa2 = false;
  List<Map<String, dynamic>> _ocorrencias = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _ocorrenciasFiltrados = [];
  final TextEditingController _pesquisaController = TextEditingController();
  final DateTime _dataSelecionada = DateTime.now();
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data);
    return DateFormat('dd/MM/yyyy').format(dataConvertida);
  }

  @override
  void initState() {
    _carregarOcorrencias();
    super.initState();
  }

  Future<void> _carregarOcorrencias() async {
      final ocorrencias = await _ocorrenciaService.buscarOcorrenciasGeral();
      setState(() {
        _ocorrencias = ocorrencias;
        _ocorrenciasFiltrados = List.from(_ocorrencias);
        _isFetching = false;
      });
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
        listaOriginal: _ocorrencias,
        atualizarListaFiltrada: (novaLista) {
          setState(() => _ocorrenciasFiltrados = novaLista);
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
            _ocorrenciasFiltrados = List.from(_ocorrencias); // 🔹 Restaura a lista original
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
                    listaOriginal: _ocorrencias,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _ocorrenciasFiltrados = novaLista);
                    },
                  );
                },
              )
                  : Text(
                'Ocorrências',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
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
                    _ocorrencias,
                        (novaLista) => setState(() {
                      _ocorrenciasFiltrados = novaLista;
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
                    _ocorrencias,
                        (novaLista) => setState(() {
                      _ocorrenciasFiltrados = novaLista;
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
                                  itemCount: _ocorrenciasFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final oc = _ocorrenciasFiltrados[index];
                                    return Card(
                                      color: const Color(0xFF0A63AC),
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child:  ListTile(
                                        title: Text("Ocorrência ${index + 1}: ${oc['jovens_aprendizes']['nome']}\n${oc['descricao']}", style: const TextStyle(color: Colors.white)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Data: ${formatarDataParaExibicao(oc['data_ocorrencia'].toString().substring(0, 10))}", style: const TextStyle(color: Colors.white)),
                                            Text("Origem: ${oc['tipo'].toString().toUpperCase()}", style: const TextStyle(color: Colors.white)),
                                            if (oc['resolvido'] == true && oc['data_resolucao'] != null)
                                              Text("Resolvido em: ${formatarDataParaExibicao(oc['data_resolucao'].toString())}", style: const TextStyle(color: Colors.greenAccent)),
                                            if (oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty)
                                              Text("Obs: ${oc['observacoes']}", style: const TextStyle(color: Colors.orange)),
                                            const SizedBox(height: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  IconButton(
                                                    focusColor: Colors.transparent,
                                                    hoverColor: Colors.transparent,
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    enableFeedback: false,
                                                    icon: Icon(
                                                      oc['resolvido'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                                                      color: oc['resolvido'] == true ? Colors.greenAccent : Colors.white,
                                                    ),
                                                    tooltip: oc['resolvido'] == true ? "Marcar como não resolvido" : "Marcar como resolvido",
                                                    onPressed: () async {
                                                      if (oc['resolvido'] == true) {
                                                        await _ocorrenciaService.desmarcarComoResolvido(oc['id']);
                                                        setState(() {
                                                          final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                                          if (index != -1) {
                                                            _ocorrencias[index]['resolvido'] = false;
                                                            _ocorrencias[index]['data_resolucao'] = null;
                                                          }
                                                        });
                                                      } else {
                                                        await _ocorrenciaService.marcarComoResolvido(oc['id']);
                                                        setState(() {
                                                          final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                                          if (index != -1) {
                                                            _ocorrencias[index]['resolvido'] = true;
                                                            _ocorrencias[index]['data_resolucao'] = DateTime.now().toIso8601String();
                                                          }
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  Container(
                                                    width: 2, // Espessura da linha
                                                    height: 30, // Altura da linha
                                                    color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                                  ),
                                                  IconButton(
                                                    focusColor: Colors.transparent,
                                                    hoverColor: Colors.transparent,
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    enableFeedback: false,
                                                    icon: Icon(Icons.comment, color: oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty ? Colors.orange : Colors.white),
                                                    tooltip: oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty ? "Editar observação" : "Adicionar observação",
                                                    onPressed: () async {
                                                      TextEditingController obsController = TextEditingController();
                                                      obsController.text = oc['observacoes'] ?? '';
                                                      await showDialog(
                                                        context: context,
                                                        builder: (_) {
                                                          return StatefulBuilder(
                                                            builder: (context, setState) {
                                                              return AlertDialog(
                                                                backgroundColor: const Color(0xFF0A63AC),
                                                                title: const Text(
                                                                  "Observação",
                                                                  style: TextStyle(
                                                                    fontSize: 20,
                                                                    color: Colors.white,
                                                                    fontFamily: 'LeagueSpartan',
                                                                  ),
                                                                ),
                                                                content: SizedBox(
                                                                  width: MediaQuery.of(context).size.width / 2,
                                                                  child: TextField(
                                                                    controller: obsController,
                                                                    style: const TextStyle(color: Colors.white),
                                                                    decoration: InputDecoration(
                                                                      suffixIcon: obsController.text.isNotEmpty
                                                                          ? IconButton(
                                                                        tooltip: "Limpar",
                                                                        icon: const Icon(Icons.clear, color: Colors.white),
                                                                        onPressed: () {
                                                                          setState(() {
                                                                            obsController.clear();
                                                                          });
                                                                        },
                                                                      )
                                                                          : null,
                                                                      labelText: "Observações",
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
                                                                    onChanged: (value) {
                                                                      setState(() {});
                                                                    },
                                                                    maxLines: 3,
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    style: ButtonStyle(
                                                                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                                                                    ),
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text(
                                                                        "Cancelar",
                                                                        style: TextStyle(color: Colors.orange,
                                                                          fontFamily: 'LeagueSpartan',
                                                                          fontSize: 20,
                                                                        )
                                                                    ),
                                                                  ),
                                                                  TextButton(
                                                                    style: ButtonStyle(
                                                                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                                                                    ),
                                                                    onPressed: () async {
                                                                      await _ocorrenciaService.adicionarObservacao(oc['id'], obsController.text);
                                                                      if (context.mounted) {
                                                                        Navigator.pop(context);
                                                                        setState(() {
                                                                          final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                                                          if (index != -1) {
                                                                            _ocorrencias[index]['observacoes'] = obsController.text;
                                                                          }
                                                                        });
                                                                      }
                                                                    },
                                                                    child: const Text(
                                                                      "Salvar",
                                                                      style: TextStyle(
                                                                        color: Colors.green,
                                                                        fontFamily: 'LeagueSpartan',
                                                                        fontSize: 20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                      );
                                                    },
                                                  ),
                                                  Container(
                                                    width: 2, // Espessura da linha
                                                    height: 30, // Altura da linha
                                                    color: Colors.white.withValues(alpha: 0.2), // Cor da linha
                                                  ),
                                                  IconButton(
                                                    focusColor: Colors.transparent,
                                                    hoverColor: Colors.transparent,
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    enableFeedback: false,
                                                    icon: const Icon(Icons.delete, color: Colors.white),
                                                    tooltip: "Excluir ocorrência",
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (_) => AlertDialog(
                                                          backgroundColor: const Color(0xFF0A63AC),
                                                          title: const Text("Tem certeza que deseja excluir esta ocorrência?",
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color: Colors.white,
                                                              fontFamily: 'LeagueSpartan',
                                                            ),),
                                                          actions: [
                                                            TextButton(
                                                              style: ButtonStyle(
                                                                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                                              ),
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text("Cancelar",
                                                                  style: TextStyle(color: Colors.orange,
                                                                    fontFamily: 'LeagueSpartan',
                                                                    fontSize: 15,
                                                                  )
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, true),
                                                              child: const Text("Excluir",
                                                                  style: TextStyle(color: Colors.red,
                                                                    fontFamily: 'LeagueSpartan',
                                                                    fontSize: 15,
                                                                  )),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm == true) {
                                                        await _ocorrenciaService.excluirOcorrencia(oc['id']);
                                                        setState(() {
                                                          _ocorrencias.removeWhere((item) => item['id'] == oc['id']);
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            )
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
