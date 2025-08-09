import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/turma_service.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';

String statusTurma = "ativo";

class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  final TurmaService _turmaService = TurmaService();
  List<Map<String, dynamic>> _turmas = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _turmasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();
  final DocService _docsService = DocService();
  String? _uploadStatus;
  DropzoneViewController? _controller;

  String sanitizeFileName(String nomeOriginal) {
    return nomeOriginal
        .toLowerCase()
        .replaceAll(RegExp(r"[çÇ]"), "c")
        .replaceAll(RegExp(r"[áàãâä]"), "a")
        .replaceAll(RegExp(r"[éèêë]"), "e")
        .replaceAll(RegExp(r"[íìîï]"), "i")
        .replaceAll(RegExp(r"[óòõôö]"), "o")
        .replaceAll(RegExp(r"[úùûü]"), "u")
        .replaceAll(RegExp(r"[^\w.]+"), "_"); // Substitui outros caracteres especiais por _
  }


  @override
  void initState() {
    super.initState();
    _carregarTurmas(statusTurma);
  }

  void _carregarTurmas(String statusTurma) async {
    final turmas = await _turmaService.buscarTurmas(statusTurma);
    setState(() {
      _turmas = turmas;
      _turmasFiltradas = List.from(_turmas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? turma}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                turma == null ? "Cadastrar Turma" : "Editar Turma",
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
          content: _FormTurma(
            turma: turma,
            onTurmaSalva: () {
              _carregarTurmas(statusTurma); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarTurma(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar esta turma?",
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
                await _turmaService
                    .inativarTurma(id);
                _carregarTurmas(statusTurma);
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

  void ativarTurma(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar esta turma?",
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
                await _turmaService
                    .ativarTurma(id);
                _carregarTurmas(statusTurma);
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

  void _abrirDocumentos(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Documentos",
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb)
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(20),),
                        child: DropzoneView(
                          operation: DragOperation.copy,
                          onCreated: (ctrl) => _controller = ctrl,
                          onDropFile: (DropzoneFileInterface  file) async {
                            final nomeSanitizado = sanitizeFileName(file.name);
                            final bytes = await _controller!.getFileData(file);

                            final resultado = await _docsService.uploadDocumento(userId, nomeSanitizado, bytes);
                            setState(() {
                              _uploadStatus = resultado?.startsWith("Erro") == true
                                  ? resultado
                                  : "Arquivo \"$nomeSanitizado\" enviado com sucesso!";
                            });
                          },
                          onHover: () => setState(() => _uploadStatus = "Solte o arquivo aqui para enviar."),
                          onLeave: () => setState(() => _uploadStatus = null),
                          mime: [
                            "application/pdf",
                            "image/*",
                            "application/msword",
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                          ],
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Arraste os documentos em PDF aqui",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_uploadStatus != null)
                  Center(
                    child: Text(
                      _uploadStatus!,
                      style: TextStyle(
                        color: _uploadStatus!.startsWith("Erro") ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _docsService.listarDocumentos(userId),
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text("Nenhum documento enviado.",
                            style: TextStyle(color: Colors.white),),
                        );
                      }

                      return SuperListView.builder(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final doc = docs[i];
                          return FutureBuilder<String?>(
                            future: _docsService.gerarLinkTemporario(doc["path"]),
                            builder: (_, snap) {
                              if (!snap.hasData) return const SizedBox.shrink();
                              return Tooltip(
                                message: "Abrir: ${doc["name"]}",
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      doc["name"],
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    trailing: IconButton(
                                      tooltip: "Excluir",
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      enableFeedback: false,
                                      icon: const Icon(Icons.close, color: Colors.black),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: Color(0xFF0A63AC),
                                            title: const Text("Confirma exclusão?",
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontFamily: 'FuturaBold',
                                              ),),
                                            content: Text("Deseja excluir \"${doc["name"]}\"?",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),),
                                            actions: [
                                              TextButton(
                                                  style: ButtonStyle(
                                                    overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                                  ),
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text("Cancelar",style: TextStyle(color: Colors.orange,
                                                    fontFamily: 'FuturaBold',
                                                    fontSize: 15,
                                                  ))),
                                              TextButton(
                                                  style: ButtonStyle(
                                                    overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text("Excluir",style: TextStyle(color: Colors.red,
                                                    fontFamily: 'FuturaBold',
                                                    fontSize: 15,
                                                  )
                                                  )),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          final result = await _docsService.excluirDocumento(doc["path"]);
                                          if (result == null) {
                                            setState(() {
                                              _uploadStatus = "Documento excluído com sucesso.";
                                            });
                                          } else {
                                            setState(() {
                                              _uploadStatus = result;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                    onTap: () async {
                                      final url = snap.data!;
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                ),
                child: const Text("Fechar",
                    style: TextStyle(color: Colors.orange,
                      fontFamily: 'FuturaBold',
                      fontSize: 15,
                    )),
                onPressed: () {
                  _uploadStatus = null;
                  Navigator.pop(context);
                }
            ),
            TextButton(
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                ),
                child: const Text("Incluir",
                    style: TextStyle(color: Colors.green,
                      fontFamily: 'FuturaBold',
                      fontSize: 15,
                    )),
                onPressed: ()  async {
                  try {
                    Uint8List? bytes;
                    String? nome;

                    if (kIsWeb) {
                      final files = await _controller?.pickFiles();
                      if (files!.isNotEmpty) {
                        final file = files.first;
                        nome = sanitizeFileName(file.name);
                        bytes = await _controller!.getFileData(file);
                      }
                    } else {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
                        allowMultiple: false,
                        withData: true,
                      );

                      if (result != null && result.files.single.bytes != null) {
                        nome = sanitizeFileName(result.files.single.name);
                        bytes = result.files.single.bytes;
                      }
                    }

                    if (nome != null && bytes != null) {
                      final result = await _docsService.uploadDocumento(userId, nome, bytes);
                      setState(() {
                        _uploadStatus = result?.startsWith("Erro") == true
                            ? result
                            : "Arquivo \"$nome\" enviado com sucesso!";
                      });
                    }
                  } catch (e) {
                    setState(() {
                      _uploadStatus = "Erro ao enviar: $e";
                    });
                  }
                }
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusTurma.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _turmasFiltradas = List.from(_turmas); // 🔹 Restaura a lista original
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
              title: modoPesquisa
                  ? TextField(
                controller: _pesquisaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Pesquisar turma...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  filtrarLista(
                    query: value,
                    listaOriginal: _turmas,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _turmasFiltradas = novaLista);
                    },
                  );
                },
              )
                  : const Text(
                'Turmas',
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
                    _turmas,
                        (novaLista) => setState(() {
                      _turmasFiltradas = novaLista;
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
            
                  // Formulário centralizado
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 40, 5, 30),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Turmas: ${isAtivo ? "Ativas" : "Inativas"}",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Tooltip(
                                      message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                      child: Switch(
                                        value: isAtivo,
                                        onChanged: (value) {
                                          setState(() {
                                            statusTurma = value ? "ativo" : "inativo";
                                          });
                                          _carregarTurmas(statusTurma);
                                        },
                                        activeColor: Color(0xFF0A63AC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: constraints.maxHeight - 100,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child:
                                _isFetching
                                    ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                    : SuperListView.builder(
                                  itemCount: _turmasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final turma = _turmasFiltradas[index];
                                    return Card(
                                      elevation: 3,
                                      child: ListTile(
                                        title: Text(
                                          "Turma: ${turma['codigo_turma']}",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        leading: const Icon(Icons.groups, color: Colors.black,),
                                        subtitle: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ano: ${turma['ano']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_inicio']))} até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_termino']))}",
                                              style: const TextStyle(color: Colors.black),
                                            ),
                                            Divider(color: Colors.black),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if (auth.tipoUsuario == "administrador")
                                                IconButton(
                                                  tooltip: "Editar",
                                                  focusColor: Colors.transparent,
                                                  hoverColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                  enableFeedback: false,
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                    color: Colors.black,
                                                  ),
                                                  onPressed:
                                                      () => _abrirFormulario(
                                                    turma: turma,
                                                  ),
                                                ),
                                                if (auth.tipoUsuario == "administrador")
                                                Container(
                                                  width: 2, // Espessura da linha
                                                  height: 30, // Altura da linha
                                                  color: Colors.black.withValues(alpha: 0.2), // Cor da linha
                                                ),
                                                if (auth.tipoUsuario == "administrador")
                                                  IconButton(
                                                    focusColor: Colors.transparent,
                                                    hoverColor: Colors.transparent,
                                                    splashColor: Colors.transparent,
                                                    highlightColor: Colors.transparent,
                                                    enableFeedback: false,
                                                    tooltip: "Documentos",
                                                    icon: const Icon(Icons.attach_file, color: Colors.black, size: 20),
                                                    onPressed: () => _abrirDocumentos(context, turma['id']),
                                                  ),
                                                if (auth.tipoUsuario == "administrador")
                                                  Container(
                                                    width: 2, // Espessura da linha
                                                    height: 30, // Altura da linha
                                                    color: Colors.black.withValues(alpha: 0.2), // Cor da linha
                                                  ),
                                                if (auth.tipoUsuario == "administrador")
                                                IconButton(
                                                  tooltip: isAtivo == true ? "Inativar" : "Ativar",
                                                  focusColor: Colors.transparent,
                                                  hoverColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                  highlightColor: Colors.transparent,
                                                  enableFeedback: false,
                                                  icon: Icon(isAtivo == true ? Icons.block : Icons.restore, color: Colors.black, size: 20,),
                                                  onPressed: () => isAtivo == true ? inativarTurma(turma['id']) : ativarTurma(turma['id']),
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
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: "Cadastrar Turma",
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            enableFeedback: false,
            onPressed: () => _abrirFormulario(),
            backgroundColor: Color(0xFF0A63AC),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _FormTurma extends StatefulWidget {
  final Map<String, dynamic>? turma;
  final VoidCallback onTurmaSalva;

  const _FormTurma({this.turma, required this.onTurmaSalva});

  @override
  _FormTurmaState createState() => _FormTurmaState();
}

class _FormTurmaState extends State<_FormTurma> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _anoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataTerminoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _turmaId;
  final TurmaService _turmaservice = TurmaService();
  //final TurmaService _moduloService = TurmaService();
  //List<Map<String, dynamic>> _modulos = [];
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  List<String> modulosSelecionados = []; // Lista para armazenar os módulos selecionados

  @override
  void initState() {
    super.initState();
    //_carregarModulos();

    if (widget.turma != null) {
      _editando = true;
      _turmaId = widget.turma!['id'].toString();
      _codigoController.text = widget.turma!['codigo_turma'];
      _anoController.text = widget.turma!['ano'].toString();
      _dataInicioController.text = formatarDataParaExibicao(widget.turma!['data_inicio'] ?? "");
      _dataTerminoController.text = formatarDataParaExibicao(widget.turma!['data_termino'] ?? "");

      /*_turmaservice.buscarModulosDaTurma(_turmaId!).then((modulos) {
        if (kDebugMode) {
          print("Modulos da turma: $modulos");
        }
        setState(() {
          modulosSelecionados = modulos;
        });
      });*/
    }
  }

/*  void _carregarModulos() async {
    final modulos = await _moduloService.buscarModulos();
    setState(() {
      _modulos = modulos;
    });
  }*/

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _turmaservice.atualizarTurmas(
          id: _turmaId!,
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          //modulosSelecionados: modulosSelecionados,
        );
      } else {
        error = await _turmaservice.cadastrarTurmas(
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          //modulosSelecionados: modulosSelecionados,
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onTurmaSalva();
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
              buildTextField(_codigoController, true, "Código da Turma", onChangedState: () => setState(() {})),
              buildTextField(_anoController, true, "Ano", isAno: true, onChangedState: () => setState(() {})),
              buildTextField(_dataInicioController, true, "Data de Início", isData: true, onChangedState: () => setState(() {})),
              buildTextField(_dataTerminoController, true, "Data de Término", isData: true, onChangedState: () => setState(() {})),
              /*MultiSelectChips(
                modulos: _modulos, // Lista de módulos carregada do Supabase
                onSelecionado: (selecionados) {
                  setState(() {
                    modulosSelecionados = selecionados;
                  });
                },
                modulosSelecionados: modulosSelecionados, // Garante que os valores iniciais sejam preenchidos
              ),*/
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
