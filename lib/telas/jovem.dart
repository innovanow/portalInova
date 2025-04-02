import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inova/widgets/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cadastros/register_jovem.dart';
import '../widgets/wave.dart';
import 'home.dart';

class JovemAprendizDetalhes extends StatefulWidget {
  final Map<String, dynamic> jovem;
  const JovemAprendizDetalhes({super.key, required this.jovem});

  @override
  State<JovemAprendizDetalhes> createState() => _JovemAprendizDetalhesState();
}

class _JovemAprendizDetalhesState extends State<JovemAprendizDetalhes> {

  String formatarParaDuasCasas(double valor) {
    return valor.toStringAsFixed(2); // ex: 800.00
  }

  String _getIniciais(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.trim().isEmpty) return "JA";

    final partes = nomeCompleto.trim().split(" ");
    if (partes.length == 1) return partes[0][0].toUpperCase();

    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  String? fotoUrlAssinada;

  @override
  void initState() {
    super.initState();
    _carregarFotoAssinada();
  }

  Future<void> _carregarFotoAssinada() async {
    final path = widget.jovem['foto_url']; // usa o nome salvo corretamente
    if (path != null && path.toString().trim().isNotEmpty) {
      try {
        final url = await Supabase.instance.client.storage
            .from('fotosjovens')
            .createSignedUrl(path, 3600); // 1h
        if (mounted) {
          setState(() {
            fotoUrlAssinada = url;
          });
        }
      } catch (e) {
        debugPrint("Erro ao gerar URL assinada: $e");
      }
    }
  }

  Future<void> _excluirFoto() async {
    final path = widget.jovem['foto_url']; // nome do arquivo salvo

    if (path == null || path.toString().isEmpty) return;

    try {
      final storage = Supabase.instance.client.storage.from('fotosjovens');

      // 1. Remove do Storage
      await storage.remove([path]);

      // 2. Remove do banco
      await Supabase.instance.client
          .from('jovens_aprendizes')
          .update({'foto_url': null})
          .eq('id', widget.jovem['id']);

      // 3. Atualiza a UI
      setState(() {
        fotoUrlAssinada = null;
        widget.jovem['foto_url'] = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto excluída com sucesso.")),
      );
    } catch (e) {
      debugPrint("Erro ao excluir foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao excluir foto: $e")),
      );
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
                        Text(widget.jovem['nome'] ?? 'Perfil',
                          style: TextStyle(
                            fontFamily: 'FuturaBold',
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth > 800 ? 20 : 15,
                            color: Colors.white,
                          ),
                        ),
                        if (fotoUrlAssinada != null)
                          IconButton(
                            tooltip: "Excluir foto",
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            enableFeedback: false,
                            onPressed: _excluirFoto,
                            icon: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                            ),
                          ),
                      ],
                    );
                  }
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: false,
              // Evita que o Flutter gere um botão automático
              leading: auth.tipoUsuario == 'administrador' ? Builder(
                builder:
                    (context) => Tooltip(
                  message: "Voltar", // Texto do tooltip
                  child: IconButton(
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    enableFeedback: false,
                    icon: Icon(Icons.arrow_back_ios,
                      color: Colors.white,) ,// Ícone do Drawer
                    onPressed: () {
                      fotoUrlAssinada = null;
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const CadastroJovem()));
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
              )
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white,),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 150,
                      child: SvgPicture.asset("assets/logoInova.svg"),
                    ),
                    Text(
                      'Usuário: ${auth.nomeUsuario ?? "Carregando..."}',
                      style: const TextStyle(color: Color(0xFF0A63AC)),
                    ),
                    Text(
                      'Email: ${auth.emailUsuario ?? "Carregando..."}',
                      style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            buildDrawerItem(Icons.home, "Home", context),
            if (auth.tipoUsuario == "jovem_aprendiz")
              buildDrawerItem(Icons.account_circle, "Meu Perfil", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
            if (auth.tipoUsuario == "administrador")
              buildDrawerItem(Icons.man, "Cadastro de Professor", context),
            buildDrawerItem(Icons.calendar_month, "Calendário", context),
            buildDrawerItem(Icons.logout, "Sair", context),
          ],
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: fotoUrlAssinada == null ? "Adicionar foto" : "Alterar foto",
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            Uint8List? bytes;
                            String ext = 'jpg';

                            if (kIsWeb) {
                              // ✅ Web: usa image_picker_for_web
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);

                              if (picked != null) {
                                bytes = await picked.readAsBytes();
                                ext = picked.name.split('.').last.toLowerCase();
                              }
                            } else {
                              if (await Permission.photos.isDenied && await Permission.storage.isDenied) {
                                await Permission.photos.request();
                                await Permission.storage.request();
                              }
                              // ✅ Mobile: solicita permissão antes
                              final status = await Permission.photos.request();
                              if (!status.isGranted) {
                                if(context.mounted){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Permissão negada para acessar fotos')),
                                  );
                                }
                                return;
                              }

                              // ✅ Mobile: usa file_picker
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                                withData: true,
                              );

                              if (result != null && result.files.single.bytes != null) {
                                bytes = result.files.single.bytes;
                                ext = result.files.single.extension?.toLowerCase() ?? 'jpg';
                              }
                            }

                            if (bytes != null) {
                              final extValida = (ext == 'png' || ext == 'jpg' || ext == 'jpeg') ? ext : 'jpg';
                              final fileName = '${widget.jovem['id']}_${DateTime.now().millisecondsSinceEpoch}.$extValida';

                              final storage = Supabase.instance.client.storage.from('fotosjovens');
                              await storage.uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

                              await Supabase.instance.client
                                  .from('jovens_aprendizes')
                                  .update({'foto_url': fileName})
                                  .eq('id', widget.jovem['id']);

                              setState(() {
                                widget.jovem['foto_url'] = fileName;
                              });

                              await _carregarFotoAssinada();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao fazer upload da imagem: $e')),
                              );
                            }
                          }
                        },
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFFF9800),
                          backgroundImage: (fotoUrlAssinada != null)
                              ? NetworkImage(fotoUrlAssinada!)
                              : null,
                          child: (fotoUrlAssinada == null)
                              ? Text(
                            _getIniciais(widget.jovem['nome']),
                            style: const TextStyle(
                              fontSize: 35,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.jovem['nome'] ?? 'Nome não disponível',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.jovem['status']?.toUpperCase() ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _buildSection("📋 Dados Pessoais", [
                      _info("Data de Nascimento", widget.jovem['data_nascimento']),
                      _info("CPF", widget.jovem['cpf']),
                      _info("RG", widget.jovem['rg']),
                      _info("Cidade Natal", widget.jovem['cidade_natal']),
                    ]),
                    _buildSection("📞 Contato", [
                      _info("Telefone", widget.jovem['telefone_jovem']),
                      _info("Telefone Pai", widget.jovem['telefone_pai']),
                      _info("Telefone Mãe", widget.jovem['telefone_mae']),
                    ]),
                    _buildSection("🏠 Endereço", [
                      _info("Endereço", widget.jovem['endereco']),
                      _info("Número", widget.jovem['numero']),
                      _info("Bairro", widget.jovem['bairro']),
                      _info("Cidade", widget.jovem['cidade']),
                      _info("Estado", widget.jovem['estado']),
                      _info("CEP", widget.jovem['cep']),
                    ]),
                    _buildSection("🎓 Educação e Empresa", [
                      _info("Escola", widget.jovem['escola']),
                      _info("Empresa", widget.jovem['empresa']),
                      _info("Área de Aprendizado", widget.jovem['area_aprendizado']),
                      _info("Escolaridade", widget.jovem['escolaridade']),
                    ]),
                    _buildSection("⏱ Carga Horária e Remuneração", [
                      _info("Horas de Trabalho", widget.jovem['horas_trabalho']),
                      _info("Horas Semanais", widget.jovem['horas_semanais']),
                      _info("Horas de Curso", widget.jovem['horas_curso']),
                      _info(
                          "Remuneração",
                          "R\$ ${(double.tryParse(widget.jovem['remuneracao']?.toString() ?? '') ?? 0.0).toStringAsFixed(2)}"),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
