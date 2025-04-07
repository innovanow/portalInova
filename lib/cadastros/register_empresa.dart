import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/empresa_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusEmpresa = "ativo";

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final EmpresaService _empresaService = EmpresaService();
  List<Map<String, dynamic>> _empresas = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _empresasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();
  final DocService _docsService = DocService();
  String? _uploadStatus;
  DropzoneViewController? _controller;
  var cnpjFormatter = MaskTextInputFormatter(
      mask: "##.###.###/####-##",
      filter: {"#": RegExp(r'[0-9]')}
  );
  var cepFormatter = MaskTextInputFormatter(
      mask: "#####-###",
      filter: {"#": RegExp(r'[0-9]')}
  );

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  void _carregarEmpresas() async {
    final empresas = await _empresaService.buscarEmpresas(statusEmpresa);
    setState(() {
      _empresas = empresas;
      _empresasFiltradas = List.from(_empresas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? empresa}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                empresa == null ? "Cadastrar Empresa" : "Editar Empresa",
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
          content: _FormEmpresa(
            empresa: empresa,
            onEmpresaSalva: () {
              _carregarEmpresas(); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarEmpresa(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar esta empresa?",
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
                await _empresaService
                    .inativarEmpresa(id);
                _carregarEmpresas();
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

  void ativarEmpresa(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar esta empresa?",
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
                await _empresaService
                    .ativarEmpresa(id);
                _carregarEmpresas();
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

                      return ListView.builder(
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
    final isAtivo = statusEmpresa.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _empresasFiltradas = List.from(_empresas); // 🔹 Restaura a lista original
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
                title: modoPesquisa
                    ? TextField(
                  controller: _pesquisaController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Pesquisar empresa...",
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    filtrarLista(
                      query: value,
                      listaOriginal: _empresas,
                      atualizarListaFiltrada: (novaLista) {
                        setState(() => _empresasFiltradas = novaLista);
                      },
                    );
                  },
                )
                    : const Text(
                  'Empresas',
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
                      _empresas,
                          (novaLista) => setState(() {
                        _empresasFiltradas = novaLista;
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
                                    "Empresas: ${isAtivo ? "Ativas" : "Inativas"}",
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Tooltip(
                                    message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                    child: Switch(
                                      value: isAtivo,
                                      onChanged: (value) {
                                        setState(() {
                                          statusEmpresa = value ? "ativo" : "inativo";
                                        });
                                        _carregarEmpresas();
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
                                        itemCount: _empresasFiltradas.length,
                                        itemBuilder: (context, index) {
                                          final empresa = _empresasFiltradas[index];
                                          return Card(
                                            elevation: 3,
                                            child: ListTile(
                                              title: Text(
                                                empresa['nome'],
                                                style: TextStyle(color: Colors.black),
                                              ),
                                              leading: const Icon(Icons.business, color: Colors.black,),
                                              subtitle: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CNPJ: ${cnpjFormatter.maskText(empresa['cnpj'] ?? '')}",
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
                                                          empresa: empresa,
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
                                                          onPressed: () => _abrirDocumentos(context, empresa['id']),
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
                                                        onPressed: () => isAtivo == true ? inativarEmpresa(empresa['id']) : ativarEmpresa(empresa['id']),
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
          floatingActionButton: FloatingActionButton(
            tooltip: "Cadastrar Empresa",
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

class _FormEmpresa extends StatefulWidget {
  final Map<String, dynamic>? empresa;
  final VoidCallback onEmpresaSalva;

  const _FormEmpresa({this.empresa, required this.onEmpresaSalva});

  @override
  _FormEmpresaState createState() => _FormEmpresaState();
}

class _FormEmpresaState extends State<_FormEmpresa> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _empresaId;
  var cnpjFormatter = MaskTextInputFormatter(
      mask: "##.###.###/####-##",
      filter: {"#": RegExp(r'[0-9]')}
  );
  var cepFormatter = MaskTextInputFormatter(
      mask: "#####-###",
      filter: {"#": RegExp(r'[0-9]')}
  );

  final EmpresaService _empresaService = EmpresaService();

  @override
  void initState() {
    super.initState();
    if (widget.empresa != null) {
      _editando = true;
      _empresaId = widget.empresa!['id'].toString();
      _nomeController.text = widget.empresa!['nome'].toString();
      _cnpjController.text = cnpjFormatter.maskText(widget.empresa!['cnpj'].toString());
      _enderecoController.text = widget.empresa!['endereco'].toString();
      _cidadeController.text = widget.empresa!['cidade'].toString();
      _estadoController.text = widget.empresa!['estado'].toString();
      _numeroController.text = widget.empresa!['numero'].toString();
      _cepController.text = cepFormatter.maskText(widget.empresa!['cep'].toString());
      _telefoneController.text = widget.empresa!['telefone'].toString();
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _empresaService.atualizarEmpresa(
          id: _empresaId!,
          nome: _nomeController.text.trim(),
          cnpj: _cnpjController.text.trim(),
          endereco: _enderecoController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          numero: _numeroController.text.trim(),
          cep: _cepController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      } else {
        error = await _empresaService.cadastrarEmpresa(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cnpj: _cnpjController.text.trim(),
          endereco: _enderecoController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          numero: _numeroController.text.trim(),
          cep: _cepController.text.trim(),
          telefone: _telefoneController.text.trim(),
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onEmpresaSalva();
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
              buildTextField(_nomeController, true, "Nome", onChangedState: () => setState(() {})),
              if (!_editando) ...[
                buildTextField(_emailController, true, "E-mail", isEmail: true, onChangedState: () => setState(() {})),
                buildTextField(_senhaController, true, "Senha", isPassword: true, onChangedState: () => setState(() {})),
              ],
              buildTextField(_cnpjController, true, "CNPJ", isCnpj: true, onChangedState: () => setState(() {})),
              buildTextField(_enderecoController, true, "Endereço", onChangedState: () => setState(() {})),
              buildTextField(_cidadeController, true, "Cidade", onChangedState: () => setState(() {})),
              buildTextField(_estadoController, true, "Estado", onChangedState: () => setState(() {})),
              buildTextField(_numeroController, true, "Número", onChangedState: () => setState(() {})),
              buildTextField(_cepController, true,"CEP", isCep: true, onChangedState: () => setState(() {})),
              buildTextField(_telefoneController, true, "Telefone", onChangedState: () => setState(() {})),
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
