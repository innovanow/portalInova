import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cadastros/register_jovem.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';

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

  Future<void> _excluirFoto(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja excluir a foto de perfil?",
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
                  if (context.mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Color(0xFF0A63AC),
                          content: Text("Foto excluída com sucesso.",
                              style: TextStyle(
                                color: Colors.white,
                              ))
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Erro ao excluir foto: $e");
                  if (context.mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          backgroundColor: Color(0xFF0A63AC),
                          content: Text("Erro ao excluir foto: $e",
                              style: TextStyle(
                                color: Colors.white,
                              ))
                      ),
                    );
                  }
                }
                if (context.mounted){
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text("Sim",
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

  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(
      data,
    ); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
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
                        Text(widget.jovem['nome'] ?? 'Perfil',
                          style: TextStyle(
                            fontFamily: 'FuturaBold',
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth > 800 ? 20 : 15,
                            color: Colors.white,
                          ),
                        ),
                        if (fotoUrlAssinada != null && auth.tipoUsuario == "joven_aprendiz" || auth.tipoUsuario == "administrador")
                          IconButton(
                            tooltip: "Excluir foto",
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            enableFeedback: false,
                            onPressed: (){
                              _excluirFoto(context);
                            },
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
              leading: auth.tipoUsuario == 'jovem_aprendiz' ?
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
              ) :
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
                    icon: Icon(Icons.arrow_back_ios,
                      color: Colors.white,) ,// Ícone do Drawer
                    onPressed: () {
                      fotoUrlAssinada = null;
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const CadastroJovem()));
                    },
                  ),
                ),
              )
          ),
        ),
        drawer: InovaDrawer(context: context),
        body: Container(
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: (fotoUrlAssinada == null && (auth.tipoUsuario == 'administrador' || auth.tipoUsuario == 'jovem_aprendiz'))
                            ? "Adicionar foto"
                            : (fotoUrlAssinada != null && (auth.tipoUsuario == 'administrador' || auth.tipoUsuario == 'jovem_aprendiz'))
                            ? "Alterar foto"
                            : "",
                        child: GestureDetector(
                          onTap: auth.tipoUsuario == 'administrador' || auth.tipoUsuario == 'jovem_aprendiz' ? () async {
                            try {
                              Uint8List? bytes;
                              String ext = 'jpg';

                              if (kIsWeb) {
                                // ✅ Web
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  bytes = await picked.readAsBytes();
                                  ext = picked.name.split('.').last.toLowerCase();
                                }
                              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                                // ✅ iOS — usa image_picker (sem permission_handler)
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  bytes = await picked.readAsBytes();
                                  ext = picked.name.split('.').last.toLowerCase();
                                }
                              } else {
                                // ✅ Android — mantém file_picker com permissões
                                final status = await Permission.storage.request();
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
                                  SnackBar(
                                    backgroundColor: Color(0xFF0A63AC),
                                    content: Text('Erro ao fazer upload da imagem: $e',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                );
                              }
                            }
                          } : null,
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'FuturaBold',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,)
                      ),
                      Text(
                        "${widget.jovem['status']?.toUpperCase()}\nCÓD: ${widget.jovem['codigo']}" ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _buildSection("📋 Dados Pessoais", [
                        _info("Data de Nascimento", formatarDataParaExibicao(widget.jovem['data_nascimento'])),
                        _info("CPF", widget.jovem['cpf']),
                        _info("RG", widget.jovem['rg']),
                        _info("Código PIS", widget.jovem['cod_pis']),
                        _info("Carteira de Trabalho", widget.jovem['cod_carteira_trabalho']),
                        _info("Cidade Natal", widget.jovem['cidade_estado_natal']),
                      ]),
                      _buildSection("📞 Contato", [
                        _info("Telefone Jovem", widget.jovem['telefone_jovem']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Telefone Pai", widget.jovem['telefone_pai']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Telefone Mãe", widget.jovem['telefone_mae']),
                        if(widget.jovem['mora_com'] == "Outro")
                        _info("Telefone Responsável", widget.jovem['telefone_mae']),
                      ]),
                      _buildSection("🏠 Endereço", [
                        _info("Endereço", widget.jovem['endereco']),
                        _info("Número", widget.jovem['numero']),
                        _info("Bairro", widget.jovem['bairro']),
                        _info("Cidade", widget.jovem['cidade']),
                        _info("Estado", widget.jovem['estado']),
                        _info("CEP", widget.jovem['cep']),
                      ]),
                      _buildSection("🎓 Educação", [
                        _info("Escola", widget.jovem['escola']),
                        _info("Escolaridade", widget.jovem['escolaridade']),
                        _info("Estudando", widget.jovem['estudando']),
                        _info("Turno da Escola", widget.jovem['turno_escola']),
                        _info("Ano Início", widget.jovem['ano_inicio_escola']?.toString()),
                        _info("Ano Conclusão", widget.jovem['ano_conclusao_escola']),
                        _info("Instituição", widget.jovem['instituicao_escola']),
                        _info("Informática", widget.jovem['informatica']),
                        _info("Habilidade em Destaque", widget.jovem['habilidade_destaque']),
                      ]),
                      _buildSection("🧬 Identidade e Gênero", [
                        _info("Sexo Biológico", widget.jovem['sexo_biologico']),
                        _info("Orientação Sexual", widget.jovem['orientacao_sexual']),
                        _info("Identidade de Gênero", widget.jovem['identidade_genero']),
                        _info("Cor", widget.jovem['cor']),
                        _info("PCD", widget.jovem['pcd']),
                      ]),

                      _buildSection("👨‍👩‍👧 Família", [
                        _info("Mora com", widget.jovem['mora_com']),
                        if(widget.jovem['mora_com'] == "Outro")
                        _info("Nome do Responsável", widget.jovem['nome_responsavel']),
                        if(widget.jovem['mora_com'] == "Outro")
                        _info("Estado Civil do Responsável", widget.jovem['estado_civil_responsavel']),
                        if(widget.jovem['mora_com'] == "Outro")
                        _info("CPF do Responsável", widget.jovem['cpf_responsavel']),
                        if(widget.jovem['mora_com'] == "Outro")
                        _info("RG do Responsável", widget.jovem['rg_responsavel']),
                        _info("Email do Responsável", widget.jovem['email_responsavel']),
                        const SizedBox(height: 10),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Nome do Pai", widget.jovem['nome_pai']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Estado Civil do Pai", widget.jovem['estado_civil_pai']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("CPF do Pai", widget.jovem['cpf_pai']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("RG do Pai", widget.jovem['rg_pai']),
                        if(widget.jovem['mora_com'] != "Outro")
                        const SizedBox(height: 10),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Nome da Mãe", widget.jovem['nome_mae']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("Estado Civil da Mãe", widget.jovem['estado_civil_mae']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("CPF da Mãe", widget.jovem['cpf_mae']),
                        if(widget.jovem['mora_com'] != "Outro")
                        _info("RG da Mãe", widget.jovem['rg_mae']),
                        const SizedBox(height: 10),
                        _info("Possui Filhos?", widget.jovem['possui_filhos']),
                        _info("Qtd. Membros Família", widget.jovem['qtd_membros_familia']),
                        _info("Recebe Benefício?", widget.jovem['beneficio_assistencial']),
                        _info("Cadastro no CRAS", widget.jovem['cadastro_cras']),
                        _info("Cometeu Infração?", widget.jovem['infracao']),
                        _info("Renda Mensal", widget.jovem['renda_mensal'] != null
                            ? "R\$ ${formatarParaDuasCasas(double.parse(widget.jovem['renda_mensal'].toString()))}"
                            : "-"),
                      ]),
                      _buildSection("🏢 Empresa", [
                        _info("Empresa", widget.jovem['empresa']),
                        _info("Trabalhando", widget.jovem['trabalhando']),
                        _info("Área de Aprendizado", widget.jovem['area_aprendizado']),
                        _info("Horas de Trabalho", widget.jovem['horas_trabalho']),
                        _info(
                            "Remuneração",
                            "R\$ ${(double.tryParse(widget.jovem['remuneracao']?.toString() ?? '') ?? 0.0).toStringAsFixed(2)}"),
                      ]),
                      _buildSection("🌐 Redes Sociais", [
                        _info("Instagram", widget.jovem['instagram']),
                        _info("LinkedIn", widget.jovem['linkedin']),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'FuturaBold',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,)),
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
