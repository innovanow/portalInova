import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';

class TelaModulosDoJovem extends StatefulWidget {
  final String jovemId;
  const TelaModulosDoJovem({super.key, required this.jovemId});

  @override
  State<TelaModulosDoJovem> createState() => _TelaModulosDoJovemState();
}

class _TelaModulosDoJovemState extends State<TelaModulosDoJovem> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> modulos = [];
  bool carregando = true;
  String? _uploadStatus;
  final DocService _docsService = DocService();

  @override
  void initState() {
    super.initState();
    carregarModulos();
  }

  Future<void> carregarModulos() async {
    final supabase = Supabase.instance.client;
    List<Map<String, dynamic>> modulosResponse = [];

    // --- Lógica para Jovem Aprendiz ---
    if (auth.tipoUsuario == "jovem_aprendiz") {
      // 1. Pega a turma_id do jovem.
      final jovemResponse = await supabase
          .from('jovens_aprendizes')
          .select('turma_id')
          .eq('id', widget.jovemId)
          .single();

      final turmaId = jovemResponse['turma_id'];

      if (turmaId != null) {
        // 2. Busca os módulos que pertencem àquela turma.
        modulosResponse = await supabase
            .from('modulos')
            .select('*, professores(nome)') // Pega dados do módulo e nome do professor
            .eq('status', 'ativo')
            .eq('turma_id', turmaId);
      }

      // --- Lógica para Professor ---
    } else if (auth.tipoUsuario == "professor") {
      // A lógica para professor permanece a mesma.
      modulosResponse = await supabase
          .from('modulos')
          .select('*, professores(nome)')
          .eq('status', 'ativo')
          .eq('professor_id', auth.idUsuario.toString());
    }

    // --- Processamento dos resultados ---
    final List<Map<String, dynamic>> resultado = [];

    for (var modulo in modulosResponse) {
      // Busca os materiais no Storage
      final materiais = await supabase
          .storage
          .from('fotosjovens')
          .list(path: '${modulo["id"]}/documentos/');

      // Gera os links de acesso para os materiais
      final links = await Future.wait(materiais.map((file) async {
        final signedUrl = await supabase.storage
            .from('fotosjovens')
            .createSignedUrl('${modulo["id"]}/documentos/${file.name}', 3600);
        return {"nome": file.name, "url": signedUrl};
      }));

      // Define o nome do professor
      String professorNome = "Não informado";
      if (modulo['professores'] != null) {
        professorNome = modulo['professores']['nome'];
      } else if (auth.tipoUsuario == "professor") {
        professorNome = "Você";
      }

      resultado.add({
        "nomeModulo": modulo['nome'],
        "professor": professorNome,
        "materiais": links,
        "id": modulo['id'],
      });
    }

    // Atualiza o estado da UI
    setState(() {
      modulos = resultado;
      carregando = false;
    });
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
                        Text("Meus Módulos",
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false,
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
                  padding: const EdgeInsets.fromLTRB(5, 40, 5, 30),
                  child: carregando
                    ? const Center(child: CircularProgressIndicator())
                    : modulos.isNotEmpty ? SuperListView.builder(
                  itemCount: modulos.length,
                  itemBuilder: (context, index) {
                    final m = modulos[index];
                    return Card(
                      child: ListTile(
                        title: Text(m['nomeModulo']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Professor: ${m['professor']}"),
                            const SizedBox(height: 5),
                            Text("Materiais do Módulo:"),
                            ...m['materiais'].map<Widget>((doc) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(doc['nome'], style: const TextStyle(fontSize: 14)),
                                leading: doc["nome"].contains(".pdf") ?  Icon(Icons.picture_as_pdf, color: Colors.red) : doc["nome"].contains(".jpg") || doc["nome"].contains(".png") ? Icon(Icons.image, color: Colors.blue) : Icon(Icons.insert_drive_file, color: Colors.green),
                                trailing: auth.tipoUsuario == "professor" || auth.tipoUsuario == "administrador"
                                    ? IconButton(
                                  tooltip: "Excluir",
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  enableFeedback: false,
                                  icon: const Icon(Icons.close, color: Colors.black),
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: Color(0xFF0A63AC),
                                        title: const Text("Confirma exclusão?",
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontFamily: 'LeagueSpartan',
                                          ),),
                                        content: Text("Deseja excluir \"${doc["nome"]}\"?",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),),
                                        actions: [
                                          TextButton(
                                              style: ButtonStyle(
                                                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                              ),
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Cancelar",style: TextStyle(color: Colors.orange,
                                                fontFamily: 'LeagueSpartan',
                                                fontSize: 15,
                                              ))),
                                          TextButton(
                                              style: ButtonStyle(
                                                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                              ),
                                              onPressed: () async {
                                                if (kDebugMode) {
                                                  print("${m["id"]}/documentos/${doc["nome"]}");
                                                }
                                                final result = await _docsService.excluirDocumento("${m["id"]}/documentos/${doc["nome"]}");
                                                if (result == null) {
                                                  setState(() {
                                                    _uploadStatus = "Documento excluído com sucesso.";
                                                  });
                                                } else {
                                                  setState(() {
                                                    _uploadStatus = result;
                                                  });
                                                }
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                }

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                        backgroundColor: Color(0xFF0A63AC),
                                                        content: Text( _uploadStatus == null ? 'Algo deu errado!' : 'Excluído com sucesso!',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                            ))
                                                    ),
                                                  );
                                                  carregarModulos();
                                                }
                                              },
                                              child: const Text("Excluir",style: TextStyle(color: Colors.red,
                                                fontFamily: 'LeagueSpartan',
                                                fontSize: 15,
                                              )
                                              )),
                                        ],
                                      ),
                                    );
                                  },
                                ) : null,
                                onTap: () => launchUrl(
                                  Uri.parse(doc['url']),
                                  mode: LaunchMode.externalApplication,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                        trailing: auth.tipoUsuario == "professor" || auth.tipoUsuario == "administrador"
                            ? IconButton(
                          color: Colors.blue,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          tooltip: "Enviar fotos",
                          icon: const Icon(Icons.upload_file_outlined,
                              color: Color(0xFF0A63AC)),
                            onPressed: ()  async {
                            if (m['id'] != null) {
                              try {
                                Uint8List? bytes;
                                String fileName = 'documento.jpg';

                                if (kIsWeb) {
                                  // ✅ Web
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    bytes = await picked.readAsBytes();
                                    String fullName = picked.name;
                                    fileName = fullName.substring(fullName.lastIndexOf('-') + 1);
                                  }
                                }
                                else if (defaultTargetPlatform == TargetPlatform.iOS) {
                                  // ✅ iOS — usa image_picker (sem permission_handler)
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    bytes = await picked.readAsBytes();
                                    String fullName = picked.name;
                                    fileName = fullName.substring(fullName.lastIndexOf('-') + 1);
                                  }
                                } else {
                                  // ✅ Android — mantém file_picker com permissões
                                  final status = await Permission.photos.request();
                                  if (kDebugMode) {
                                    print(status);
                                  }
                                  if (!status.isGranted) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Color(0xFF0A63AC),
                                          content: Text('Permissão negada para acessar arquivos',
                                              style: TextStyle(color: Colors.white)),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                    withData: true,
                                  );

                                  if (result != null && result.files.single.bytes != null) {
                                    bytes = result.files.single.bytes;
                                    fileName = sanitizeFileName(result.files.single.name);
                                  }
                                }

                                if (bytes != null) {
                                  final result = await _docsService.uploadDocumento(m['id'], fileName, bytes);
                                  setState(() {
                                    _uploadStatus = result?.startsWith("Erro") == true
                                        ? result
                                        : "Arquivo \"$fileName\" enviado com sucesso!";
                                  });
                                  if (kDebugMode) {
                                    print(_uploadStatus);
                                  }
                                  carregarModulos();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Color(0xFF0A63AC),
                                          content: Text( _uploadStatus == null ? 'Algo deu errado!' : 'Enviado com sucesso!',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ))
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Color(0xFF0A63AC),
                                      content: Text('Erro ao fazer upload da imagem: $e',
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  );
                                }
                              }
                            } else {
                              if (kDebugMode) {
                                print('ID do módulo não encontrado.');
                              }
                            }
                            }
                        ) : null,
                    ));
                  },
                  ) : const Center(
                    child: Text('Nenhum módulo encontrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,)),
                  )
                ),]
            ),
          ),
        ),
      ),
    );
  }
}
