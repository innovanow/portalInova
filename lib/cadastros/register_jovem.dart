import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:inova/cadastros/register_ocorrencia.dart';
import 'package:inova/telas/jovem.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/jovem_service.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusJovem = "ativo";

class CadastroJovem extends StatefulWidget {
  const CadastroJovem({super.key});

  @override
  State<CadastroJovem> createState() => _CadastroJovemState();
}

class _CadastroJovemState extends State<CadastroJovem> {
  final JovemService _jovemService = JovemService();
  List<Map<String, dynamic>> _jovens = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _jovensFiltrados = [];
  bool modoPesquisa = false;
  final TextEditingController _pesquisaController = TextEditingController();
  String? fotoUrlAssinada;
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
        .replaceAll(
          RegExp(r"[^\w.]+"),
          "_",
        ); // Substitui outros caracteres especiais por _
  }

  @override
  void initState() {
    super.initState();
    _carregarjovens(statusJovem);
  }

  void _carregarjovens(String status) async {
    List<Map<String, dynamic>> jovens;

    if (auth.tipoUsuario == "professor") {
      jovens = await _jovemService.buscarJovensDoProfessor(
        auth.idUsuario.toString(),
        status,
      );
    } else if (auth.tipoUsuario == "escola") {
      jovens = await _jovemService.buscarJovensDaEscola(
        auth.idUsuario.toString(),
        status,
      );
    } else if (auth.tipoUsuario == "empresa") {
      jovens = await _jovemService.buscarJovensDaEmpresa(
        auth.idUsuario.toString(),
        status,
      );
    } else {
      jovens = await _jovemService.buscarjovem(status);
    }

    setState(() {
      _jovens = jovens;
      _jovensFiltrados = List.from(jovens);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? jovem}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jovem == null ? "Cadastrar Jovem" : "Editar Jovem",
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
          content: _Formjovem(
            jovem: jovem,
            onjovemSalva: () {
              _carregarjovens(statusJovem); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarJovem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text(
            "Tem certeza de que deseja inativar este jovem?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // Remove o destaque ao passar o mouse
              ),
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text(
                "Cancelar",
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'FuturaBold',
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // Remove o destaque ao passar o mouse
              ),
              onPressed: () async {
                await _jovemService.inativarJovem(id);
                _carregarjovens(statusJovem);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text(
                "Inativar",
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'FuturaBold',
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void ativarJovem(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text(
            "Tem certeza de que deseja ativar este jovem?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // Remove o destaque ao passar o mouse
              ),
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text(
                "Cancelar",
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'FuturaBold',
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  Colors.transparent,
                ), // Remove o destaque ao passar o mouse
              ),
              onPressed: () async {
                await _jovemService.ativarJovem(id);
                _carregarjovens(statusJovem);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text(
                "Ativar",
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'FuturaBold',
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getSignedUrl(String? path) async {
    if (path == null || path.trim().isEmpty) return null;

    try {
      final url = await Supabase.instance.client.storage
          .from('fotosjovens')
          .createSignedUrl(path, 3600);
      return url;
    } catch (e) {
      debugPrint("Erro ao gerar signed URL: $e");
      return null;
    }
  }

  String _getIniciais(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.trim().isEmpty) return "JA";

    final partes = nomeCompleto.trim().split(" ");
    if (partes.length == 1) return partes[0][0].toUpperCase();

    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  void _abrirDocumentos(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
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
                        Expanded(
                          flex: 1,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: DropzoneView(
                                  operation: DragOperation.copy,
                                  onCreated: (ctrl) => _controller = ctrl,
                                  onDropFile: (
                                    DropzoneFileInterface file,
                                  ) async {
                                    final nomeSanitizado = sanitizeFileName(
                                      file.name,
                                    );
                                    final bytes = await _controller!
                                        .getFileData(file);

                                    final resultado = await _docsService
                                        .uploadDocumento(
                                          userId,
                                          nomeSanitizado,
                                          bytes,
                                        );
                                    setState(() {
                                      _uploadStatus =
                                          resultado?.startsWith("Erro") == true
                                              ? resultado
                                              : "Arquivo \"$nomeSanitizado\" enviado com sucesso!";
                                    });
                                  },
                                  onHover:
                                      () => setState(
                                        () =>
                                            _uploadStatus =
                                                "Solte o arquivo aqui para enviar.",
                                      ),
                                  onLeave:
                                      () =>
                                          setState(() => _uploadStatus = null),
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
                                color:
                                    _uploadStatus!.startsWith("Erro")
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Expanded(
                          flex: 2,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _docsService.listarDocumentos(userId),
                            builder: (_, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final docs = snapshot.data ?? [];
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "Nenhum documento enviado.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: docs.length,
                                itemBuilder: (_, i) {
                                  final doc = docs[i];
                                  return FutureBuilder<String?>(
                                    future: _docsService.gerarLinkTemporario(
                                      doc["path"],
                                    ),
                                    builder: (_, snap) {
                                      if (!snap.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      return Tooltip(
                                        message: "Abrir: ${doc["name"]}",
                                        child: Card(
                                          child: ListTile(
                                            title: Text(
                                              doc["name"],
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            leading: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                            ),
                                            trailing: IconButton(
                                              tooltip: "Excluir",
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              splashColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              enableFeedback: false,
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.black,
                                              ),
                                              onPressed: () async {
                                                final confirm = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (_) => AlertDialog(
                                                        backgroundColor: Color(
                                                          0xFF0A63AC,
                                                        ),
                                                        title: const Text(
                                                          "Confirma exclusão?",
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'FuturaBold',
                                                          ),
                                                        ),
                                                        content: Text(
                                                          "Deseja excluir \"${doc["name"]}\"?",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            style: ButtonStyle(
                                                              overlayColor:
                                                                  WidgetStateProperty.all(
                                                                    Colors
                                                                        .transparent,
                                                                  ), // Remove o destaque ao passar o mouse
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              "Cancelar",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .orange,
                                                                fontFamily:
                                                                    'FuturaBold',
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            style: ButtonStyle(
                                                              overlayColor:
                                                                  WidgetStateProperty.all(
                                                                    Colors
                                                                        .transparent,
                                                                  ), // Remove o destaque ao passar o mouse
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                            child: const Text(
                                                              "Excluir",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontFamily:
                                                                    'FuturaBold',
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                                if (confirm == true) {
                                                  final result =
                                                      await _docsService
                                                          .excluirDocumento(
                                                            doc["path"],
                                                          );
                                                  if (result == null) {
                                                    setState(() {
                                                      _uploadStatus =
                                                          "Documento excluído com sucesso.";
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
                                              await launchUrl(
                                                Uri.parse(url),
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
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
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // Remove o destaque ao passar o mouse
                      ),
                      child: const Text(
                        "Fechar",
                        style: TextStyle(
                          color: Colors.orange,
                          fontFamily: 'FuturaBold',
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        _uploadStatus = null;
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // Remove o destaque ao passar o mouse
                      ),
                      child: const Text(
                        "Incluir",
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'FuturaBold',
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () async {
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
                              allowedExtensions: [
                                'pdf',
                                'jpg',
                                'png',
                                'doc',
                                'docx',
                              ],
                              allowMultiple: false,
                              withData: true,
                            );

                            if (result != null &&
                                result.files.single.bytes != null) {
                              nome = sanitizeFileName(result.files.single.name);
                              bytes = result.files.single.bytes;
                            }
                          }

                          if (nome != null && bytes != null) {
                            final result = await _docsService.uploadDocumento(
                              userId,
                              nome,
                              bytes,
                            );
                            setState(() {
                              _uploadStatus =
                                  result?.startsWith("Erro") == true
                                      ? result
                                      : "Arquivo \"$nome\" enviado com sucesso!";
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _uploadStatus = "Erro ao enviar: $e";
                          });
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusJovem.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _jovensFiltrados = List.from(
              _jovens,
            ); // 🔹 Restaura a lista original
          });
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Color(0xFF0A63AC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                            hintText: "Pesquisar jovem...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            filtrarLista(
                              query: value,
                              listaOriginal: _jovens,
                              atualizarListaFiltrada: (novaLista) {
                                setState(() => _jovensFiltrados = novaLista);
                              },
                            );
                          },
                        )
                        : const Text(
                          'Jovens',
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
                        onPressed:
                            () => fecharPesquisa(
                              setState,
                              _pesquisaController,
                              _jovens,
                              (novaLista) => setState(() {
                                _jovensFiltrados = novaLista;
                                modoPesquisa =
                                    false; // 🔹 Agora o modo pesquisa é atualizado corretamente
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
                        onPressed:
                            () => setState(() {
                              modoPesquisa = true;
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
                    child: Container(
                      height: 60,
                      color: const Color(0xFF0A63AC),
                    ),
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
                    child: Container(
                      height: 50,
                      color: const Color(0xFF0A63AC),
                    ),
                  ),
                ),
                // Formulário centralizado
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 40, 2, 30),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (auth.tipoUsuario == "administrador")
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Jovens: ${isAtivo ? "Ativos" : "Inativos"}",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Tooltip(
                                      message:
                                          isAtivo
                                              ? "Exibir Inativos"
                                              : "Exibir Ativos",
                                      child: Switch(
                                        value: isAtivo,
                                        onChanged: (value) {
                                          setState(() {
                                            statusJovem =
                                                value ? "ativo" : "inativo";
                                          });
                                          _carregarjovens(statusJovem);
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
                            height: 500,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child:
                                  _isFetching
                                      ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                      : ListView.builder(
                                        itemCount: _jovensFiltrados.length,
                                        itemBuilder: (context, index) {
                                          final jovem = _jovensFiltrados[index];
                                          return Card(
                                            elevation: 3,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    spacing: 10,
                                                    children: [
                                                      FutureBuilder<String?>(
                                                        future: _getSignedUrl(
                                                          jovem['foto_url'],
                                                        ),
                                                        builder: (
                                                          context,
                                                          snapshot,
                                                        ) {
                                                          final temFoto =
                                                              snapshot
                                                                  .hasData &&
                                                              snapshot
                                                                  .data!
                                                                  .isNotEmpty;

                                                          return CircleAvatar(
                                                            radius: 30,
                                                            backgroundColor:
                                                                const Color(
                                                                  0xFFFF9800,
                                                                ),
                                                            backgroundImage:
                                                                temFoto
                                                                    ? NetworkImage(
                                                                      snapshot
                                                                          .data!,
                                                                    )
                                                                    : null,
                                                            child:
                                                                !temFoto
                                                                    ? Text(
                                                                      _getIniciais(
                                                                        jovem['nome'],
                                                                      ),
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            20,
                                                                        color:
                                                                            Colors.white,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    )
                                                                    : null,
                                                          );
                                                        },
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            jovem['nome'] ?? '',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            "Colégio: ${jovem['escola'] ?? ''}\nEmpresa: ${jovem['empresa'] ?? ''}",
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                          if (auth.tipoUsuario ==
                                                              "professor")
                                                            SizedBox(height: 5),
                                                          Text(
                                                            auth.tipoUsuario ==
                                                                    "professor"
                                                                ? "Turma: ${jovem['cod_turma'] ?? ''}\nMódulo: ${jovem['turmas']?['modulos_turmas']?[0]?['modulos']?['nome'] ?? 'Não informado'}"
                                                                : "",
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .black,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Divider(color: Colors.black),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      IconButton(
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        splashColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        enableFeedback: false,
                                                        tooltip: "Visualizar",
                                                        icon: const Icon(
                                                          Icons.remove_red_eye,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pushReplacement(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => JovemAprendizDetalhes(
                                                                      jovem:
                                                                          jovem,
                                                                    ),
                                                              ),
                                                            ),
                                                      ),
                                                      Container(
                                                        width: 2,
                                                        // Espessura da linha
                                                        height: 30,
                                                        // Altura da linha
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ), // Cor da linha
                                                      ),
                                                      IconButton(
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        splashColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        enableFeedback: false,
                                                        tooltip: "Ocorrências",
                                                        icon: const Icon(
                                                          Icons
                                                              .chat_bubble_outline,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                        onPressed:
                                                            () => Navigator.of(
                                                              context,
                                                            ).pushReplacement(
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (
                                                                      _,
                                                                    ) => OcorrenciasScreen(
                                                                      jovemId:
                                                                          jovem['id'],
                                                                      nomeJovem:
                                                                          jovem['nome'],
                                                                    ),
                                                              ),
                                                            ),
                                                      ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        Container(
                                                          width: 2,
                                                          // Espessura da linha
                                                          height: 30,
                                                          // Altura da linha
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ), // Cor da linha
                                                        ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        IconButton(
                                                          focusColor:
                                                              Colors
                                                                  .transparent,
                                                          hoverColor:
                                                              Colors
                                                                  .transparent,
                                                          splashColor:
                                                              Colors
                                                                  .transparent,
                                                          highlightColor:
                                                              Colors
                                                                  .transparent,
                                                          enableFeedback: false,
                                                          tooltip: "Editar",
                                                          icon: const Icon(
                                                            Icons.edit,
                                                            color: Colors.black,
                                                            size: 20,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _abrirFormulario(
                                                                    jovem:
                                                                        jovem,
                                                                  ),
                                                        ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        Container(
                                                          width: 2,
                                                          // Espessura da linha
                                                          height: 30,
                                                          // Altura da linha
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ), // Cor da linha
                                                        ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        IconButton(
                                                          focusColor:
                                                              Colors
                                                                  .transparent,
                                                          hoverColor:
                                                              Colors
                                                                  .transparent,
                                                          splashColor:
                                                              Colors
                                                                  .transparent,
                                                          highlightColor:
                                                              Colors
                                                                  .transparent,
                                                          enableFeedback: false,
                                                          tooltip: "Documentos",
                                                          icon: const Icon(
                                                            Icons.attach_file,
                                                            color: Colors.black,
                                                            size: 20,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _abrirDocumentos(
                                                                    context,
                                                                    jovem['id'],
                                                                  ),
                                                        ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        Container(
                                                          width: 2,
                                                          // Espessura da linha
                                                          height: 30,
                                                          // Altura da linha
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ), // Cor da linha
                                                        ),
                                                      if (auth.tipoUsuario ==
                                                          "administrador")
                                                        IconButton(
                                                          focusColor:
                                                              Colors
                                                                  .transparent,
                                                          hoverColor:
                                                              Colors
                                                                  .transparent,
                                                          splashColor:
                                                              Colors
                                                                  .transparent,
                                                          highlightColor:
                                                              Colors
                                                                  .transparent,
                                                          enableFeedback: false,
                                                          tooltip:
                                                              isAtivo == true
                                                                  ? "Inativar"
                                                                  : "Ativar",
                                                          icon: Icon(
                                                            isAtivo == true
                                                                ? Icons.block
                                                                : Icons.restore,
                                                            color: Colors.black,
                                                            size: 20,
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  isAtivo ==
                                                                          true
                                                                      ? inativarJovem(
                                                                        jovem['id'],
                                                                      )
                                                                      : ativarJovem(
                                                                        jovem['id'],
                                                                      ),
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
          floatingActionButton:
              auth.tipoUsuario == "administrador"
                  ? FloatingActionButton(
                    tooltip: "Cadastrar Jovem",
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                    onPressed: () => _abrirFormulario(),
                    backgroundColor: Color(0xFF0A63AC),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                  : null,
        ),
      ),
    );
  }
}

class _Formjovem extends StatefulWidget {
  final Map<String, dynamic>? jovem;
  final VoidCallback onjovemSalva;

  const _Formjovem({this.jovem, required this.onjovemSalva});

  @override
  _FormjovemState createState() => _FormjovemState();
}

class _FormjovemState extends State<_Formjovem> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _nomePaiController = TextEditingController();
  final _nomeMaeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cpfPaiController = TextEditingController();
  final _cpfMaeController = TextEditingController();
  final _rgPaiController = TextEditingController();
  final _rgMaeController = TextEditingController();
  final _areaAprendizadoController = TextEditingController();
  final _codCarteiraTrabalhoController = TextEditingController();
  final _rgController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneJovemController = TextEditingController();
  final _telefonePaiController = TextEditingController();
  final _telefoneMaeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _horasTrabalhoController = TextEditingController();
  final _remuneracaoController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _cpfResponsavelController = TextEditingController();
  final _rgResponsavelController = TextEditingController();
  final _emailResponsavelController = TextEditingController();
  final _telefoneResponsavelController = TextEditingController();
  final _outraEscolaController = TextEditingController();
  final _outraEmpresaController = TextEditingController();
  final _anoInicioColegioController = TextEditingController();
  final _anoFimColegioController = TextEditingController();
  final _pisController = TextEditingController();
  final _rendaController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _jovemId;
  String? _empresaSelecionada;
  String? _escolaSelecionada;
  String? _turmaSelecionada;
  String? _sexoSelecionado;
  String? _orientacaoSelecionado;
  String? _identidadeSelecionado;
  String? _corSelecionado;
  String? _pcdSelecionado;
  String? _estadoCivilSelecionado;
  String? _estadoCivilPaiSelecionado;
  String? _estadoCivilMaeSelecionado;
  String? _estadoCivilResponsavelSelecionado;
  String? _moraComSelecionado;
  String? _filhosSelecionado;
  String? _membrosSelecionado;
  String? _escolaridadeSelecionado;
  String? _estaEstudandoSelecionado;
  String? _turnoColegioSelecionado;
  String? _estaTrabalhandoSelecionado;
  String? _cadastroCrasSelecionado;
  String? _atoInfracionalSelecionado;
  String? _beneficioSelecionado;
  String? _instituicaoSelecionado;
  String? _informaticaSelecionado;
  String? _habilidadeSelecionado;
  List<Map<String, dynamic>> _escolas = [];
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _turmas = [];
  String? _cidadeSelecionada;
  String? _cidadeNatalSelecionada;
  String? _nacionalidadeSelecionada;

  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(
      data,
    ); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }

  String formatarDinheiro(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  final JovemService _jovemService = JovemService();

  void _carregarEscolasEmpresas() async {
    final escolas = await _jovemService.buscarEscolas();
    final empresas = await _jovemService.buscarEmpresas();
    final turmas = await _jovemService.buscarTurmas();
    setState(() {
      _escolas = escolas;
      _empresas = empresas;
      _turmas = turmas;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarEscolasEmpresas();
    if (widget.jovem != null) {
      _editando = true;
      _jovemId = widget.jovem!['id'] ?? "";
      _nomeController.text = widget.jovem!['nome'] ?? "";
      _dataNascimentoController.text = formatarDataParaExibicao(
        widget.jovem!['data_nascimento'] ?? "",
      );
      _nomePaiController.text = widget.jovem!['nome_pai'] ?? "";
      _estadoCivilPaiSelecionado = widget.jovem!['estado_civil_pai'] ?? "";
      _estadoCivilMaeSelecionado = widget.jovem!['estado_civil_mae'] ?? "";
      _estadoCivilResponsavelSelecionado = widget.jovem!['estado_civil_responsavel'] ?? "";
      _estadoCivilSelecionado = widget.jovem!['estado_civil'] ?? "";
      _cpfPaiController.text = widget.jovem!['cpf_pai'] ?? "";
      _cpfMaeController.text = widget.jovem!['cpf_mae'] ?? "";
      _rgPaiController.text = widget.jovem!['rg_pai'] ?? "";
      _rgMaeController.text = widget.jovem!['rg_mae'] ?? "";
      _nomeMaeController.text = widget.jovem!['nome_mae'] ?? "";
      _cpfResponsavelController.text = widget.jovem!['cpf_responsavel'] ?? "";
      _rgResponsavelController.text = widget.jovem!['rg_responsavel'] ?? "";
      _emailResponsavelController.text = widget.jovem!['email_responsavel'] ?? "";
      _enderecoController.text = widget.jovem!['endereco'] ?? "";
      _numeroController.text = widget.jovem!['numero'] ?? "";
      _bairroController.text = widget.jovem!['bairro'] ?? "";
      _estadoController.text = widget.jovem!['estado'] ?? "";
      _codCarteiraTrabalhoController.text = widget.jovem!['cod_carteira_trabalho'] ?? "";
      _rgController.text = widget.jovem!['rg'] ?? "";
      _cepController.text = widget.jovem!['cep'] ?? "";
      _telefoneJovemController.text = widget.jovem!['telefone_jovem'] ?? "";
      _telefonePaiController.text = widget.jovem!['telefone_pai'] ?? "";
      _telefoneMaeController.text = widget.jovem!['telefone_mae'] ?? "";
      _escolaSelecionada = widget.jovem!['escola_id'] ?? "";
      _empresaSelecionada = widget.jovem!['empresa_id'] ?? "";
      _areaAprendizadoController.text = widget.jovem!['area_aprendizado'] ?? "";
      _cpfController.text = widget.jovem!['cpf'] ?? "";
      _horasTrabalhoController.text = widget.jovem!['horas_trabalho'] ?? "";
      _remuneracaoController.text = formatarDinheiro(
        widget.jovem!['remuneracao'] ?? 0.0,
      );
      _outraEscolaController.text = widget.jovem!['outra_escola'] ?? "";
      _turmaSelecionada = widget.jovem!['turma_id'] ?? "";
      _sexoSelecionado = widget.jovem!['sexo_biologico'] ?? "";
      _orientacaoSelecionado = widget.jovem!['orientacao_sexual'] ?? "";
      _identidadeSelecionado = widget.jovem!['identidade_genero'] ?? "";
      _cidadeSelecionada = widget.jovem!['cidade_estado'] ?? "";
      _escolaridadeSelecionado = widget.jovem!['escolaridade'] ?? "";
      _cidadeNatalSelecionada = widget.jovem!['cidade_estado_natal'] ?? "";
      _corSelecionado = widget.jovem!['cor'] ?? "";
      _pcdSelecionado = widget.jovem!['pcd'] ?? "";
      _nacionalidadeSelecionada =  widget.jovem!['nacionalidade'] ?? "";
      _moraComSelecionado = widget.jovem!['mora_com'] ?? "";
      _filhosSelecionado = widget.jovem!['filhos'] ?? "";
      _membrosSelecionado = widget.jovem!['membros'] ?? "";
      _estaEstudandoSelecionado = widget.jovem!['estudando'] ?? "";
      _nomeResponsavelController.text = widget.jovem!['nome_responsavel'] ?? "";
      _filhosSelecionado = widget.jovem!['possui_filhos'] ?? "";
      _membrosSelecionado = widget.jovem!['qtd_membros_familia'] ?? "";
      _beneficioSelecionado = widget.jovem!['beneficio_assistencial'] ?? "";
      _cadastroCrasSelecionado = widget.jovem!['cadastro_cras'] ?? "";
      _atoInfracionalSelecionado = widget.jovem!['infracao'] ?? "";
      _rendaController.text = formatarDinheiro(
        widget.jovem!['renda_mensal'] ?? 0.0,
      );
      _turnoColegioSelecionado = widget.jovem!['turno_escola'] ?? "";
      _anoInicioColegioController.text = widget.jovem!['ano_inicio_escola'] ?? "";
      _anoFimColegioController.text = widget.jovem!['ano_conclusao_escola'] ?? "";
      _instituicaoSelecionado = widget.jovem!['instituicao_escola'] ?? "";
      _informaticaSelecionado = widget.jovem!['informatica'] ?? "";
      _habilidadeSelecionado = widget.jovem!['habilidade_destaque'] ?? "";
      _estaTrabalhandoSelecionado = widget.jovem!['trabalhando'] ?? "";
      _outraEscolaController.text = widget.jovem!['escola_alternativa'] ?? "";
      _outraEmpresaController.text = widget.jovem!['empresa_alternativa'] ?? "";
      _pisController.text = widget.jovem!['cod_pis'] ?? "";
      _instagramController.text = widget.jovem!['instagram'] ?? "";
      _linkedinController.text = widget.jovem!['linkedin'] ?? "";
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _jovemService.atualizarjovem(
          id: _jovemId!,
          nome: _nomeController.text.trim(),
          dataNascimento:
              _dataNascimentoController.text.isNotEmpty
                  ? formatter.format(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).parse(_dataNascimentoController.text),
                  )
                  : null,
          nomePai: _nomePaiController.text.trim(),
          nomeMae: _nomeMaeController.text.trim(),
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidadeEstado: _cidadeSelecionada,
          cidadeEstadoNatal: _cidadeNatalSelecionada,
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          estadoCivilPai: _estadoCivilPaiSelecionado,
          estadoCivilMae: _estadoCivilMaeSelecionado,
          estadoCivil: _estadoCivilSelecionado,
          estadoCivilResponsavel: _estadoCivilResponsavelSelecionado,
          cpfPai: _cpfPaiController.text.trim(),
          cpfMae: _cpfMaeController.text.trim(),
          rgPai: _rgPaiController.text.trim(),
          rgMae: _rgMaeController.text.trim(),
          cep: _cepController.text.trim(),
          telefoneJovem: _telefoneJovemController.text.trim(),
          telefonePai: _telefonePaiController.text.trim(),
          telefoneMae: _telefoneMaeController.text.trim(),
          escola: _escolaSelecionada,
          empresa: _empresaSelecionada,
          areaAprendizado: _areaAprendizadoController.text.trim(),
          cpf: _cpfController.text.trim(),
          horasTrabalho: _horasTrabalhoController.text.trim(),
          remuneracao: _remuneracaoController.text.trim(),
          turma: _turmaSelecionada,
          sexoBiologico: _sexoSelecionado,
          escolaridade: _escolaridadeSelecionado,
          estudando: _estaEstudandoSelecionado,
          trabalhando: _estaTrabalhandoSelecionado,
          escolaAlternativa: _outraEscolaController.text.trim(),
          empresaAlternativa: _outraEmpresaController.text.trim(),
          nomeResponsavel: _nomeResponsavelController.text.trim(),
          orientacaoSexual: _orientacaoSelecionado,
          identidadeGenero: _identidadeSelecionado,
          cor: _corSelecionado,
          pcd: _pcdSelecionado,
          rendaMensal: _rendaController.text.trim(),
          turnoEscola: _turnoColegioSelecionado,
          anoIncioEscola: _anoInicioColegioController.text.trim(),
          anoConclusaoEscola: _anoFimColegioController.text.trim(),
          instituicaoEscola: _instituicaoSelecionado,
          informatica: _informaticaSelecionado,
          habilidadeDestaque: _habilidadeSelecionado,
          codPis: _pisController.text.trim(),
          instagram: _instagramController.text.trim(),
          linkedin: _linkedinController.text.trim(),
          nacionalidade: _nacionalidadeSelecionada,
          moraCom: _moraComSelecionado,
          infracao: _atoInfracionalSelecionado,
        );
      } else {
        error = await _jovemService.cadastrarjovem(
          nome: _nomeController.text.trim(),
          dataNascimento:
              _dataNascimentoController.text.isNotEmpty
                  ? formatter.format(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).parse(_dataNascimentoController.text),
                  )
                  : null,
          nomePai: _nomePaiController.text.trim(),
          nomeMae: _nomeMaeController.text.trim(),
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidadeEstado: _cidadeSelecionada,
          cidadeEstadoNatal: _cidadeNatalSelecionada,
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          estadoCivilPai: _estadoCivilPaiSelecionado,
          estadoCivilMae: _estadoCivilMaeSelecionado,
          estadoCivil: _estadoCivilSelecionado,
          estadoCivilResponsavel: _estadoCivilResponsavelSelecionado,
          cpfPai: _cpfPaiController.text.trim(),
          cpfMae: _cpfMaeController.text.trim(),
          rgPai: _rgPaiController.text.trim(),
          rgMae: _rgMaeController.text.trim(),
          cep: _cepController.text.trim(),
          telefoneJovem: _telefoneJovemController.text.trim(),
          telefonePai: _telefonePaiController.text.trim(),
          telefoneMae: _telefoneMaeController.text.trim(),
          escola: _escolaSelecionada,
          empresa: _empresaSelecionada,
          areaAprendizado: _areaAprendizadoController.text.trim(),
          escolaridade: _escolaridadeSelecionado,
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cpf: _cpfController.text.trim(),
          horasTrabalho: _horasTrabalhoController.text.trim(),
          remuneracao: _remuneracaoController.text.trim(),
          turma: _turmaSelecionada,
          sexoBiologico: _sexoSelecionado,
          estudando: _estaEstudandoSelecionado,
          trabalhando: _estaTrabalhandoSelecionado,
          escolaAlternativa: _outraEscolaController.text.trim(),
          empresaAlternativa: _outraEmpresaController.text.trim(),
          nomeResponsavel: _nomeResponsavelController.text.trim(),
          orientacaoSexual: _orientacaoSelecionado,
          identidadeGenero: _identidadeSelecionado,
          cor: _corSelecionado,
          pcd: _pcdSelecionado,
          rendaMensal: _rendaController.text.trim(),
          turnoEscola: _turnoColegioSelecionado,
          anoIncioEscola: _anoInicioColegioController.text.trim(),
          anoConclusaoEscola: _anoFimColegioController.text.trim(),
          instituicaoEscola: _instituicaoSelecionado,
          informatica: _informaticaSelecionado,
          habilidadeDestaque: _habilidadeSelecionado,
          codPis: _pisController.text.trim(),
          instagram: _instagramController.text.trim(),
          linkedin: _linkedinController.text.trim(),
          nacionalidade: _nacionalidadeSelecionada,
          moraCom: _moraComSelecionado,
          infracao: _atoInfracionalSelecionado,
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onjovemSalva();
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
              buildTextField(
                _nomeController, true,
                "Nome Completo",
                onChangedState: () => setState(() {}),
              ),
              if (!_editando) ...[
                buildTextField(
                  _emailController, true,
                  "E-mail",
                  isEmail: true,
                  onChangedState: () => setState(() {}),
                ),
                buildTextField(
                  _senhaController, true,
                  "Senha",
                  isPassword: true,
                  onChangedState: () => setState(() {}),
                ),
              ],
              buildTextField(
                _dataNascimentoController, true,
                "Data de Nascimento",
                isData: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _estadoCivilSelecionado,
                decoration: InputDecoration(
                  labelText: "Estado Civil",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Solteiro', child: Text('Solteiro')),
                  DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                  DropdownMenuItem(
                    value: 'Divorciado',
                    child: Text('Divorciado'),
                  ),
                  DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _estadoCivilSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _sexoSelecionado,
                decoration: InputDecoration(
                  labelText: "Sexo Biologico",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _orientacaoSelecionado,
                decoration: InputDecoration(
                  labelText: "Orientação de Sexual",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Heterosexual',
                    child: Text('Heterosexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Homossexual',
                    child: Text('Homossexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Bissexual',
                    child: Text('Bissexual'),
                  ),
                  DropdownMenuItem(
                    value: 'Pansexual',
                    child: Text('Pansexual'),
                  ),
                  DropdownMenuItem(value: 'Asexual', child: Text('Asexual')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _orientacaoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _identidadeSelecionado,
                decoration: InputDecoration(
                  labelText: "Identidade de gênero",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Mulher Cis.',
                    child: Text('Mulher Cis.'),
                  ),
                  DropdownMenuItem(
                    value: 'Homem Cis.',
                    child: Text('Homem Cis.'),
                  ),
                  DropdownMenuItem(
                    value: 'Homem Trans.',
                    child: Text('Homem Trans.'),
                  ),
                  DropdownMenuItem(
                    value: 'Mulher Trans.',
                    child: Text('Mulher Trans.'),
                  ),
                  DropdownMenuItem(value: 'Não binário', child: Text('Não binário')),
                  DropdownMenuItem(
                    value: 'Prefiro não responder',
                    child: Text('Prefiro não responder'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _identidadeSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _corSelecionado,
                decoration: InputDecoration(
                  labelText: "Cor",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Branco', child: Text('Branco')),
                  DropdownMenuItem(value: 'Pardo', child: Text('Pardo')),
                  DropdownMenuItem(value: 'Negro', child: Text('Negro')),
                  DropdownMenuItem(value: 'Amarelo', child: Text('Amarelo')),
                  DropdownMenuItem(
                    value: 'Não declarado',
                    child: Text('Não declarado'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _corSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _pcdSelecionado,
                decoration: InputDecoration(
                  labelText: "PCD",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _pcdSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownSearch<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                clickProps: ClickProps(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  enableFeedback: false,
                ),
                suffixProps: DropdownSuffixProps(
                  dropdownButtonProps: DropdownButtonProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                    color: Colors.white,
                    iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
                // Configuração da aparência do campo de entrada
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Nacionalidade",
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
                ),
                // Configuração do menu suspenso
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, color: Colors.white),),
                  ),
                  menuProps: MenuProps(
                    color: Colors.white,
                    backgroundColor: Color(0xFF0A63AC),
                  ),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Procurar Nacionalidade",
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: 250),
                ),
                // Função para buscar cidades do Supabase
                items: (String? filtro, dynamic _) async {
                  final response = await Supabase.instance.client
                      .from('pais')
                      .select('codigo, pais, nacionalidade')
                      .ilike('pais', '%${filtro ?? ''}%')
                      .order('pais', ascending: true);

                  // Concatena cidade + UF
                  return List<String>.from(
                    response.map((e) => "${e['nacionalidade']}"),
                  );
                },
                // Callback chamado quando uma cidade é selecionada
                onChanged: (value) {
                  setState(() {
                    _nacionalidadeSelecionada = value;
                  });
                },
                selectedItem: _nacionalidadeSelecionada,
                dropdownBuilder: (context, selectedItem) {
                  return Text(
                    selectedItem ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  );
                },
              ),
              if(_nacionalidadeSelecionada == "Brasileira")
              const SizedBox(height: 10),
              if(_nacionalidadeSelecionada == "Brasileira")
                DropdownSearch<String>(
                  clickProps: ClickProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                  ),
                  suffixProps: DropdownSuffixProps(
                    dropdownButtonProps: DropdownButtonProps(
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      enableFeedback: false,
                      color: Colors.white,
                      iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                    ),
                  ),
                  // Configuração da aparência do campo de entrada
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Cidade Natal",
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
                  ),
                  // Configuração do menu suspenso
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 15, color: Colors.white),),
                    ),
                    menuProps: MenuProps(
                      color: Colors.white,
                      backgroundColor: Color(0xFF0A63AC),
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: "Procurar Cidade Natal",
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    fit: FlexFit.loose,
                    constraints: BoxConstraints(maxHeight: 250),
                  ),
                  // Função para buscar cidades do Supabase
                  items: (String? filtro, dynamic _) async {
                    final response = await Supabase.instance.client
                        .from('cidades')
                        .select('cidade, uf')
                        .ilike('cidade', '%${filtro ?? ''}%')
                        .order('cidade', ascending: true);

                    // Concatena cidade + UF
                    return List<String>.from(
                      response.map((e) => "${e['cidade']} - ${e['uf']}"),
                    );
                  },
                  // Callback chamado quando uma cidade é selecionada
                  onChanged: (value) {
                    setState(() {
                      _cidadeNatalSelecionada = value;
                    });
                  },
                  selectedItem: _cidadeNatalSelecionada,
                  dropdownBuilder: (context, selectedItem) {
                    return Text(
                      selectedItem ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    );
                  },
                ),
              const SizedBox(height: 10),
              buildTextField(
                _cpfController, true,
                "CPF",
                isCpf: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _rgController, true,
                "RG",
                isRg: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _telefoneJovemController, false,
                "Telefone do Jovem",
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _moraComSelecionado,
                decoration: InputDecoration(
                  labelText: "Mora com quem",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Mãe', child: Text('Mãe')),
                  DropdownMenuItem(value: 'Pai', child: Text('Pai')),
                  DropdownMenuItem(
                    value: 'Mãe e Pai',
                    child: Text('Mãe e Pai'),
                  ),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                ],
                onChanged: (value) {
                  setState(() {
                    _moraComSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Pai'))
                buildTextField(
                  _nomePaiController, false,
                  "Nome do Pai",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  value: _estadoCivilPaiSelecionado,
                  decoration: InputDecoration(
                    labelText: "Estado Civil Pai",
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
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilPaiSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Pai'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Pai'))
                buildTextField(
                  _cpfPaiController, false,
                  "CPF do Pai",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai'))
                buildTextField(
                  _rgPaiController, false,
                  "RG do Pai",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Pai'))
                buildTextField(
                  _telefonePaiController, false,
                  "Telefone do Pai",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe'))
                buildTextField(
                  _nomeMaeController, false,
                  "Nome da Mãe",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  value: _estadoCivilMaeSelecionado,
                  decoration: InputDecoration(
                    labelText: "Estado Civil Mãe",
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
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilMaeSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Mãe'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Mãe'))
                buildTextField(
                  _cpfMaeController, false,
                  "CPF da Mãe",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe'))
                buildTextField(
                  _rgMaeController, false,
                  "RG da Mãe",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Mãe'))
                buildTextField(
                  _telefoneMaeController, false,
                  "Telefone da Mãe",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _nomeResponsavelController, false,
                  "Nome do Responsável",
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  value: _estadoCivilResponsavelSelecionado,
                  decoration: InputDecoration(
                    labelText: "Estado Civil Responsável",
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
                  dropdownColor: const Color(0xFF0A63AC),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'Solteiro',
                      child: Text('Solteiro'),
                    ),
                    DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                    DropdownMenuItem(
                      value: 'Divorciado',
                      child: Text('Divorciado'),
                    ),
                    DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                    DropdownMenuItem(
                      value: 'Prefiro não responder',
                      child: Text('Prefiro não responder'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _estadoCivilResponsavelSelecionado = value!;
                    });
                  },
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                const SizedBox(height: 10),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _cpfResponsavelController, false,
                  "CPF do Responsável",
                  isCpf: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _rgResponsavelController, false,
                  "RG do Responsável",
                  isRg: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_moraComSelecionado.toString().contains('Outro'))
                buildTextField(
                  _telefoneResponsavelController, false,
                  "Telefone do Responsável",
                  onChangedState: () => setState(() {}),
                ),
              buildTextField(
                _emailResponsavelController, false,
                "E-mail do Responsável",
                isEmail: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _filhosSelecionado,
                decoration: InputDecoration(
                  labelText: "Possui filhos",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                  DropdownMenuItem(value: '1', child: Text('1')),
                  DropdownMenuItem(value: '2', child: Text('2')),
                  DropdownMenuItem(value: '3', child: Text('3')),
                  DropdownMenuItem(value: '4', child: Text('4')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filhosSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _membrosSelecionado,
                decoration: InputDecoration(
                  labelText: "Quantidade de Membros na Família",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1')),
                  DropdownMenuItem(value: '2', child: Text('2')),
                  DropdownMenuItem(value: '3', child: Text('3')),
                  DropdownMenuItem(value: '4', child: Text('4')),
                  DropdownMenuItem(value: '5 ou +', child: Text('5 ou +')),
                ],
                onChanged: (value) {
                  setState(() {
                    _membrosSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _beneficioSelecionado,
                decoration: InputDecoration(
                  labelText: "Sua família recebe algum benefício assistencial?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                ],
                onChanged: (value) {
                  setState(() {
                    _beneficioSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _cadastroCrasSelecionado,
                decoration: InputDecoration(
                  labelText: "Possui cadastro no CRAS, CREAS ou Acolhimento?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _cadastroCrasSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _atoInfracionalSelecionado,
                decoration: InputDecoration(
                  labelText: "Já cumpriu ou cumpre medidas socioeducativas por ato infracional?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _atoInfracionalSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              buildTextField(
                _rendaController, false,
                "Renda mensal familiar",
                isDinheiro: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _cepController, true,
                "CEP",
                isCep: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _enderecoController, true,
                "Endereço",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _numeroController, true,
                "Número",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _bairroController, true,
                "Bairro",
                onChangedState: () => setState(() {}),
              ),
              DropdownSearch<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                clickProps: ClickProps(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  enableFeedback: false,
                ),
                suffixProps: DropdownSuffixProps(
                  dropdownButtonProps: DropdownButtonProps(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    enableFeedback: false,
                    color: Colors.white,
                    iconClosed: Icon(Icons.arrow_drop_down, color: Colors.white),
                  ),
                ),
                // Configuração da aparência do campo de entrada
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Cidade",
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
                ),
                // Configuração do menu suspenso
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  itemBuilder: (context, item, isDisabled, isSelected) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, color: Colors.white),),
                  ),
                  menuProps: MenuProps(
                    color: Colors.white,
                    backgroundColor: Color(0xFF0A63AC),
                  ),
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Procurar Cidade",
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  fit: FlexFit.loose,
                  constraints: BoxConstraints(maxHeight: 250),
                ),
                // Função para buscar cidades do Supabase
                items: (String? filtro, dynamic _) async {
                  final response = await Supabase.instance.client
                      .from('cidades')
                      .select('cidade, uf')
                      .ilike('cidade', '%${filtro ?? ''}%')
                      .order('cidade', ascending: true);

                  // Concatena cidade + UF
                  return List<String>.from(
                    response.map((e) => "${e['cidade']} - ${e['uf']}"),
                  );
                },
                // Callback chamado quando uma cidade é selecionada
                onChanged: (value) {
                  setState(() {
                    _cidadeSelecionada = value;
                  });
                },
                selectedItem: _cidadeSelecionada,
                dropdownBuilder: (context, selectedItem) {
                  return Text(
                    selectedItem ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _estaEstudandoSelecionado,
                decoration: InputDecoration(
                  labelText: "Estudando?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estaEstudandoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _escolaridadeSelecionado,
                decoration: InputDecoration(
                  labelText: "Escolaridade",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'Ensino Fundamental Incompleto',
                    child: Text('Ensino Fundamental Incompleto'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensino Fundamental Completo',
                    child: Text('Ensino Fundamental Completo'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensino Médio Incompleto',
                    child: Text('Ensino Médio Incompleto'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensino Médio Completo',
                    child: Text('Ensino Médio Completo'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensino Superior Incompleto',
                    child: Text('Ensino Superior Incompleto'),
                  ),
                  DropdownMenuItem(
                    value: 'Ensino Superior Completo',
                    child: Text('Ensino Superior Completo'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _escolaridadeSelecionado = value!;
                  });
                },
              ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  value:
                      (_escolaSelecionada != null &&
                              _escolas.any(
                                (e) => e['id'].toString() == _escolaSelecionada,
                              ))
                          ? _escolaSelecionada
                          : null,

                  // Evita erro caso o valor não esteja na lista
                  items:
                      _escolas
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['id'].toString(),
                              child: Text(
                                e['nome'],
                                style: const TextStyle(
                                  color: Colors.white,
                                ), // Cor do texto no menu
                              ),
                            ),
                          )
                          .toList(),

                  onChanged:
                      (value) =>
                          setState(() => _escolaSelecionada = value as String),

                  decoration: InputDecoration(
                    labelText: "Colégio",
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
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: const Color(0xFF0A63AC),
                  style: const TextStyle(color: Colors.white),
                ),
              const SizedBox(height: 10),
              if (_escolaSelecionada.toString().contains(
                'ed489387-3684-459e-8ad4-bde80c2cfb66',
              ))
                buildTextField(
                  _outraEscolaController, false,
                  "Qual Colégio?",
                  onChangedState: () => setState(() {}),
                ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _turnoColegioSelecionado,
                decoration: InputDecoration(
                  labelText: "Turno Colégio",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Manhã', child: Text('Manhã')),
                  DropdownMenuItem(value: 'Tarde', child: Text('Tarde')),
                  DropdownMenuItem(value: 'Noite', child: Text('Noite')),
                  DropdownMenuItem(value: 'Integral', child: Text('Integral')),
                  DropdownMenuItem(value: 'EAD', child: Text('EAD')),
                  DropdownMenuItem(value: 'Semi Presencial', child: Text('Semi Presencial')),
                ],
                onChanged: (value) {
                  setState(() {
                    _turnoColegioSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              buildTextField(
                _anoInicioColegioController, false,
                "Ano de Início",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _anoFimColegioController, false,
                "Ano de Conclusão (Previsto)",
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _instituicaoSelecionado,
                decoration: InputDecoration(
                  labelText: "Instituição de Ensino",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Privada', child: Text('Privada')),
                  DropdownMenuItem(value: 'Pública', child: Text('Pública')),
                ],
                onChanged: (value) {
                  setState(() {
                    _instituicaoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _informaticaSelecionado,
                decoration: InputDecoration(
                  labelText: "Conhecimento básico em informática?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _informaticaSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _habilidadeSelecionado,
                decoration: InputDecoration(
                  labelText: "Habilidade que mais se destaca:",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Adaptabilidade', child: Text('Adaptabilidade')),
                  DropdownMenuItem(value: 'Criatividade', child: Text('Criatividade')),
                  DropdownMenuItem(value: 'Flexibilidade', child: Text('Flexibilidade')),
                  DropdownMenuItem(value: 'Proatividade', child: Text('Proatividade')),
                  DropdownMenuItem(value: 'Trabalho em equipe', child: Text('Trabalho em equipe')),
                ],
                onChanged: (value) {
                  setState(() {
                    _habilidadeSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value: _estaTrabalhandoSelecionado,
                decoration: InputDecoration(
                  labelText: "Trabalhando?",
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
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  DropdownMenuItem(value: 'Não', child: Text('Não')),
                ],
                onChanged: (value) {
                  setState(() {
                    _estaTrabalhandoSelecionado = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  value:
                      (_empresaSelecionada != null &&
                              _empresas.any(
                                (e) =>
                                    e['id'].toString() == _empresaSelecionada,
                              ))
                          ? _empresaSelecionada
                          : null,

                  // Evita erro caso o valor não esteja na lista
                  items:
                      _empresas
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['id'].toString(),
                              child: Text(
                                e['nome'],
                                style: const TextStyle(
                                  color: Colors.white,
                                ), // Cor do texto no menu
                              ),
                            ),
                          )
                          .toList(),

                  onChanged:
                      (value) =>
                          setState(() => _empresaSelecionada = value as String),

                  decoration: InputDecoration(
                    labelText: "Empresa",
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
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: const Color(0xFF0A63AC),
                  style: const TextStyle(color: Colors.white),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_empresaSelecionada.toString().contains(
                '9d4a3fa4-e0ff-44fb-92c8-1f9a67868997',
              ))
                buildTextField(
                  _outraEmpresaController, false,
                  "Qual empresa?",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
              buildTextField(
                _codCarteiraTrabalhoController, false,
                "Código Carteira de Trabalho",
                onChangedState: () => setState(() {}),
              ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
              buildTextField(
                _pisController, false,
                "Código PIS",
                onChangedState: () => setState(() {}),
              ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _areaAprendizadoController, false,
                  "Área de Aprendizado",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _horasTrabalhoController, false,
                  "Horas de Trabalho",
                  isHora: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _remuneracaoController, false,
                  "Remuneração",
                  isDinheiro: true,
                  onChangedState: () => setState(() {}),
                ),
              DropdownButtonFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                value:
                    (_turmaSelecionada != null &&
                            _turmas.any(
                              (e) => e['id'].toString() == _turmaSelecionada,
                            ))
                        ? _turmaSelecionada
                        : null,

                // Evita erro caso o valor não esteja na lista
                items:
                    _turmas
                        .map(
                          (e) => DropdownMenuItem(
                            value: e['id'].toString(),
                            child: Text(
                              e['codigo_turma'],
                              style: const TextStyle(
                                color: Colors.white,
                              ), // Cor do texto no menu
                            ),
                          ),
                        )
                        .toList(),

                onChanged:
                    (value) =>
                        setState(() => _turmaSelecionada = value as String),

                decoration: InputDecoration(
                  labelText: "Turma",
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
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: const Color(0xFF0A63AC),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              buildTextField(
                _instagramController, false,
                "Pefil Instagram",
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _linkedinController, false,
                "Perfil LinkedIn",
                onChangedState: () => setState(() {}),
              ),
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
                SelectableText(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
