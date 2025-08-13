import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inova/telas/presenca.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../services/presenca_service.dart';
import '../widgets/drawer.dart';
import '../widgets/filter.dart';
import '../widgets/indicadores/relatorio_presenca.dart';
import '../widgets/wave.dart';

class HistoricoChamadasPage extends StatefulWidget {
  final String professorId;

  const HistoricoChamadasPage({super.key, required this.professorId});

  @override
  State<HistoricoChamadasPage> createState() => _HistoricoChamadasPageState();
}

class _HistoricoChamadasPageState extends State<HistoricoChamadasPage> {
  final PresencaService _presencaService = PresencaService();
  List<Map<String, dynamic>> _historico = [];
  List<Map<String, dynamic>> _historicoFiltrados = [];
  bool modoPesquisa = false;
  bool modoPesquisa2 = false;
  bool _isFetching = true;
  final TextEditingController _pesquisaController = TextEditingController();
  final DateTime _dataSelecionada = DateTime.now();
  Map<String, dynamic>? _moduloSelecionadoParaRelatorio;


  @override
  void initState() {
    super.initState();
    _buscarHistoricoChamadas();
  }

  Future<void> _buscarHistoricoChamadas() async {
    if (widget.professorId.isNotEmpty) {
      final historico = await _presencaService.buscarHistoricoChamadas(
        widget.professorId,
      );
      setState(() {
        _historico = historico;
        _historicoFiltrados = List.from(_historico);
        _isFetching = false;
      });
    } else {
      final historico = await _presencaService.buscarHistoricoChamadasGeral();
      setState(() {
        _historico = historico;
        _historicoFiltrados = List.from(_historico);
        _isFetching = false;
      });
    }
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
        listaOriginal: _historico,
        atualizarListaFiltrada: (novaLista) {
          setState(() => _historicoFiltrados = novaLista);
        },
      );
    }
  }

  void _showGenerateReportDialog() {
    final uniqueModules = <String, Map<String, dynamic>>{};
    for (var historico in _historico) {
      final uniqueKey = "${historico['modulo_id']}-${historico['turma_id']}";
      if (!uniqueModules.containsKey(uniqueKey)) {
        uniqueModules[uniqueKey] = historico;
      }
    }

    final moduleList = uniqueModules.values.toList();

    if (moduleList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum histórico para gerar relatório.')),
      );
      return;
    }

    setState(() {
      _moduloSelecionadoParaRelatorio = moduleList.first;
    });

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFF0A63AC),
              title: Text('Gerar Relatório',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 800 ? 20 : 15,
                  color: Colors.white,
                  fontFamily: 'FuturaBold',
                ),),
              content:
              DropdownButtonFormField<Map<String, dynamic>>(
                isExpanded: true,
                value: _moduloSelecionadoParaRelatorio,
                decoration: InputDecoration(
                  labelText: "Selecione o Módulo",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (newValue) {
                  setDialogState(() {
                    _moduloSelecionadoParaRelatorio = newValue;
                  });
                  setState(() {
                    _moduloSelecionadoParaRelatorio = newValue;
                  });
                },
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: moduleList.map((module) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: module,
                    child: Text(
                      '${module['modulo_nome']} (Turma ${module['codigo_turma']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ), // Remove o destaque ao passar o mouse
                  ),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'FuturaBold',
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ), // Remove o destaque ao passar o mouse
                  ),
                  onPressed: _moduloSelecionadoParaRelatorio == null
                      ? null
                      : () async {
                    // 1. Fecha o diálogo de seleção
                    Navigator.pop(ctx);

                    await RelatorioService.gerarRelatorioPresenca(
                      moduloId: _moduloSelecionadoParaRelatorio!['modulo_id'],
                      turmaId: _moduloSelecionadoParaRelatorio!['turma_id'],
                      moduloNome: _moduloSelecionadoParaRelatorio!['modulo_nome'],
                      codigoTurma: _moduloSelecionadoParaRelatorio!['codigo_turma'].toString(),
                      instituicao: 'INOVA DE PALOTINA - IIP', projeto: '1348/0038', localSala: '00', cargaHoraria: '0000', horario: '0000',
                    );
                  },
                  child: const Text(
                    "Gerar Relatório",
                    style: TextStyle(
                      color: Colors.orange,
                      fontFamily: 'FuturaBold',
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            );
          },
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
            _historicoFiltrados = List.from(_historico); // 🔹 Restaura a lista original
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
                      listaOriginal: _historico,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _historicoFiltrados = novaLista);
                      },
                    );
                  },
                )
                    : Text(
                  'Histórico',
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
                      _historico,
                          (novaLista) => setState(() {
                        _historicoFiltrados = novaLista;
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
                      _historico,
                          (novaLista) => setState(() {
                        _historicoFiltrados = novaLista;
                        modoPesquisa2 = false; // 🔹 Agora o modo pesquisa é atualizado corretamente
                      }),
                    ),

                  )
                ],
                // Evita que o Flutter gere um botão automático
                leading: widget.professorId.isNotEmpty ?
                Builder(
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
                ) :
                Builder(
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
                                      itemCount: _historicoFiltrados.length,
                                      itemBuilder: (context, index) {
                                        final item = _historicoFiltrados[index];
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
                                                    if (widget.professorId.isNotEmpty)
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
                                    )));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton:
            FloatingActionButton(
              tooltip: "Gerar Relatório",
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              enableFeedback: false,
              onPressed: _showGenerateReportDialog,
              backgroundColor: Color(0xFF0A63AC),
              child: const Icon(Icons.picture_as_pdf, color: Colors.white),
            )
        ),
      ),
    );
  }
}
