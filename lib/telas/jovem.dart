import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inova/telas/splash.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cadastros/register_jovem.dart';
import '../services/jovem_service.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';
import '../widgets/widgets.dart';

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

  Future<void> _excluirFoto(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja excluir a foto de perfil?",
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
              onPressed: () => Navigator.of(context).pop(), // Fecha o alerta
              child: const Text("Cancelar",
                  style: TextStyle(color: Colors.orange,
                    fontFamily: 'LeagueSpartan',
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
                    fontFamily: 'LeagueSpartan',
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
                        Text(widget.jovem['nome'].split(" ")[0] ?? 'Perfil',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
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
                                }
                                else {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    bytes = await picked.readAsBytes();
                                    ext = picked.name.split('.').last.toLowerCase();
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
                              fontFamily: 'LeagueSpartan',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,)
                        ),
                        Text(
                          "${widget.jovem['status']?.toUpperCase()}\nCÓD: ${widget.jovem['codigo'].toString()}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        _buildSection("📋 Dados Pessoais", [
                          _info("Data de Nascimento", formatarDataParaExibicao(widget.jovem['data_nascimento'])),
                          _info("CPF", widget.jovem['cpf'] ?? '-'),
                          _info("RG", widget.jovem['rg'] ?? '-'),
                          _info("Código PIS", widget.jovem['cod_pis'] ?? '-'),
                          _info("Carteira de Trabalho", widget.jovem['cod_carteira_trabalho'] ?? '-'),
                          _info("Cidade Natal", widget.jovem['cidade_estado_natal'] ?? '-'),
                        ]),
                        _buildSection("📞 Contato", [
                          _info("Telefone Jovem", widget.jovem['telefone_jovem'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Telefone Pai", widget.jovem['telefone_pai'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Telefone Mãe", widget.jovem['telefone_mae'] ?? '-'),
                          if(widget.jovem['mora_com'] == "Outro")
                          _info("Telefone Responsável", widget.jovem['telefone_mae'] ?? '-'),
                        ]),
                        _buildSection("🏠 Endereço", [
                          _info("Endereço", widget.jovem['endereco'] ?? '-'),
                          _info("Número", widget.jovem['numero'] ?? '-'),
                          _info("Bairro", widget.jovem['bairro'] ?? '-'),
                          _info("CEP", widget.jovem['cep'] ?? '-'),
                        ]),
                        _buildSection("🎓 Educação", [
                          _info("Escola", widget.jovem['escola'] ?? '-'),
                          _info("Escolaridade", widget.jovem['escolaridade'] ?? '-'),
                          _info("Estudando", widget.jovem['estudando'] ?? '-'),
                          _info("Turno da Escola", widget.jovem['turno_escola'] ?? '-'),
                          _info("Ano Início", widget.jovem['ano_inicio_escola'].toString() == 'null' ? '-' : widget.jovem['ano_inicio_escola'].toString()),
                          _info("Ano Conclusão", widget.jovem['ano_conclusao_escola'].toString() == 'null' ? '-' : widget.jovem['ano_conclusao_escola'].toString()),
                          _info("Instituição", widget.jovem['instituicao_escola'] ?? '-'),
                          _info("Informática", widget.jovem['informatica'] ?? '-'),
                          _info("Habilidade em Destaque", widget.jovem['habilidade_destaque'] ?? '-'),
                        ]),
                        _buildSection("🧬 Identidade e Gênero", [
                          _info("Sexo Biológico", widget.jovem['sexo_biologico'] ?? '-'),
                          _info("Orientação Sexual", widget.jovem['orientacao_sexual'] ?? '-'),
                          _info("Identidade de Gênero", widget.jovem['identidade_genero'] ?? '-'),
                          _info("Cor", widget.jovem['cor'] ?? '-'),
                          _info("PCD", widget.jovem['pcd'] ?? '-'),
                        ]),
          
                        _buildSection("👨‍👩‍👧 Família", [
                          _info("Mora com", widget.jovem['mora_com'] ?? '-'),
                          if(widget.jovem['mora_com'] == "Outro")
                          _info("Nome do Responsável", widget.jovem['nome_responsavel'] ?? '-'),
                          if(widget.jovem['mora_com'] == "Outro")
                          _info("Estado Civil do Responsável", widget.jovem['estado_civil_responsavel'] ?? '-'),
                          if(widget.jovem['mora_com'] == "Outro")
                          _info("CPF do Responsável", widget.jovem['cpf_responsavel'] ?? '-'),
                          if(widget.jovem['mora_com'] == "Outro")
                          _info("RG do Responsável", widget.jovem['rg_responsavel'] ?? '-'),
                          _info("Email do Responsável", widget.jovem['email_responsavel'] ?? '-'),
                          const SizedBox(height: 10),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Nome do Pai", widget.jovem['nome_pai'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Estado Civil do Pai", widget.jovem['estado_civil_pai'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("CPF do Pai", widget.jovem['cpf_pai'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("RG do Pai", widget.jovem['rg_pai'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          const SizedBox(height: 10),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Nome da Mãe", widget.jovem['nome_mae'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("Estado Civil da Mãe", widget.jovem['estado_civil_mae'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("CPF da Mãe", widget.jovem['cpf_mae'] ?? '-'),
                          if(widget.jovem['mora_com'] != "Outro")
                          _info("RG da Mãe", widget.jovem['rg_mae'] ?? '-'),
                          const SizedBox(height: 10),
                          _info("Possui Filhos?", widget.jovem['possui_filhos'] ?? '-'),
                          _info("Qtd. Membros Família", widget.jovem['qtd_membros_familia'] ?? '-'),
                          _info("Recebe Benefício?", widget.jovem['beneficio_assistencial'] ?? '-'),
                          _info("Cadastro no CRAS", widget.jovem['cadastro_cras'] ?? '-'),
                          _info("Cometeu Infração?", widget.jovem['infracao'].toString()),
                          _info("Renda Mensal", widget.jovem['renda_mensal'] != null
                              ? "R\$ ${formatarParaDuasCasas(double.parse(widget.jovem['renda_mensal'].toString()))}"
                              : "-"),
                        ]),
                        _buildSection("🏢 Empresa", [
                          _info("Empresa", widget.jovem['empresa'] ?? '-'),
                          _info("Trabalhando", widget.jovem['trabalhando'] ?? '-'),
                          _info("Área de Aprendizado", widget.jovem['area_aprendizado'] ?? '-'),
                          _info("Horas de Trabalho", widget.jovem['horas_trabalho'] ?? '-'),
                          _info(
                              "Remuneração",
                              "R\$ ${(double.tryParse(widget.jovem['remuneracao']?.toString() ?? '') ?? 0.0).toStringAsFixed(2)}"),
                        ]),
                        _buildSection("🌐 Redes Sociais", [
                          _info("Instagram", widget.jovem['instagram'] ?? '-'),
                          _info("LinkedIn", widget.jovem['linkedin'] ?? '-'),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton:
        auth.tipoUsuario == "administrador" || auth.tipoUsuario == "jovem_aprendiz"
            ? FloatingActionButton(
          tooltip: "Atualizar Informações",
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          enableFeedback: false,
          onPressed: () => _abrirFormulario(
            jovem:
            widget.jovem,
          ),
          backgroundColor: Color(0xFF0A63AC),
          child: const Icon(Icons.edit, color: Colors.white),
        )
            : null,
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
                    fontFamily: 'LeagueSpartan',
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
    try {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          children: [
            Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(value ?? '-', overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
    } catch (e, stackTrace) {
      // Você pode logar o erro ou exibir uma mensagem padrão
      debugPrint('Erro ao construir _info: $e');
      debugPrintStack(stackTrace: stackTrace);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          children: const [
            Text("Erro: ", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text("Não foi possível carregar a informação", overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
    }
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
                "Editar Informações",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'LeagueSpartan',
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
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SplashScreen(title: 'Atualizando...',)));
            },
          ),
        );
      },
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
  final _codCarteiraTrabalhoController = TextEditingController();
  final _rgController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneJovemController = TextEditingController();
  final _telefonePaiController = TextEditingController();
  final _telefoneMaeController = TextEditingController();
  final _cpfController = TextEditingController();
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
  String? _jovemId;
  String? _empresaSelecionada;
  String? _escolaSelecionada;
  String? _turmaSelecionada;
  String? _sexoSelecionado;
  String? _orientacaoSelecionado;
  String? _identidadeSelecionado;
  String? _corSelecionado;
  String? _pcdSelecionado;
  String? _estadoCivilSelecionado = "Solteiro";
  String? _estadoCivilPaiSelecionado = "Solteiro";
  String? _estadoCivilMaeSelecionado = "Solteiro";
  String? _estadoCivilResponsavelSelecionado = "Solteiro";
  String? _moraComSelecionado;
  String? _filhosSelecionado = "Não";
  String? _membrosSelecionado = "1";
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
  String? _areaAprendizadoSelecionada;

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
      _jovemId = widget.jovem!['id'] ?? "";
      _nomeController.text = widget.jovem!['nome'] ?? "";
      _dataNascimentoController.text = formatarDataParaExibicao(
        widget.jovem!['data_nascimento'] ?? "",
      );
      _nomePaiController.text = widget.jovem!['nome_pai'] ?? "";
      _estadoCivilPaiSelecionado = widget.jovem!['estado_civil_pai'] ?? "Solteiro";
      _estadoCivilMaeSelecionado = widget.jovem!['estado_civil_mae'] ?? "Solteiro";
      _estadoCivilResponsavelSelecionado = widget.jovem!['estado_civil_responsavel'] ?? "Solteiro";
      _estadoCivilSelecionado = widget.jovem!['estado_civil'] ?? "Solteiro";
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
      _escolaSelecionada = widget.jovem!['escola_id'];
      _empresaSelecionada = widget.jovem!['empresa_id'];
      _areaAprendizadoSelecionada = widget.jovem!['area_aprendizado'] ?? "Outros";
      _cpfController.text = widget.jovem!['cpf'] ?? "";
      _horasTrabalhoController.text = widget.jovem!['horas_trabalho'] ?? "00:00:00";
      _remuneracaoController.text = formatarDinheiro(
        double.tryParse(widget.jovem?['remuneracao']?.toString() ?? '0.0') ?? 0.0,
      );
      _outraEscolaController.text = widget.jovem!['outra_escola'] ?? "Outro";
      _turmaSelecionada = widget.jovem!['turma_id'] ?? "Sem turma";
      _sexoSelecionado = widget.jovem!['sexo_biologico'] ?? "Prefiro não responder";
      _orientacaoSelecionado = widget.jovem!['orientacao_sexual'] ?? "Prefiro não responder";
      _identidadeSelecionado = widget.jovem!['identidade_genero'] ?? "Prefiro não responder";
      _cidadeSelecionada = widget.jovem!['cidade_estado'] ?? "Palotina-PR";
      _escolaridadeSelecionado = widget.jovem!['escolaridade'] ?? "Ensino Médio Completo";
      _cidadeNatalSelecionada = widget.jovem!['cidade_estado_natal'] ?? "Palotina-PR";
      _corSelecionado = widget.jovem!['cor'] ?? "Não declarado";
      _pcdSelecionado = widget.jovem!['pcd'] ?? "Não";
      _nacionalidadeSelecionada =  widget.jovem!['nacionalidade'] ?? "Brasileira";
      _moraComSelecionado = widget.jovem!['mora_com'] ?? "Outro";
      _membrosSelecionado = widget.jovem!['membros'] ?? "1";
      _estaEstudandoSelecionado = widget.jovem!['estudando'] ?? "Sim";
      _nomeResponsavelController.text = widget.jovem!['nome_responsavel'] ?? "";
      _filhosSelecionado = widget.jovem!['possui_filhos'] ?? "Não";
      _membrosSelecionado = widget.jovem!['qtd_membros_familia'] ?? "1";
      _beneficioSelecionado = widget.jovem!['beneficio_assistencial'] ?? "Não";
      _cadastroCrasSelecionado = widget.jovem!['cadastro_cras'] ?? "Não";
      _atoInfracionalSelecionado = widget.jovem!['infracao'] ?? "Não";
      _rendaController.text = formatarDinheiro(
        double.tryParse(widget.jovem?['renda_mensal']?.toString() ?? '0.0') ?? 0.0,
      );
      _turnoColegioSelecionado = widget.jovem!['turno_escola'] ?? "Matutino";
      _anoInicioColegioController.text = widget.jovem!['ano_inicio_escola'] == null ? "2025" : widget.jovem!['ano_inicio_escola'].toString();
      _anoFimColegioController.text = widget.jovem!['ano_conclusao_escola']  == null ? "2025" : widget.jovem!['ano_conclusao_escola'].toString();
      _instituicaoSelecionado = widget.jovem!['instituicao_escola'] ?? "Outro";
      _informaticaSelecionado = widget.jovem!['informatica'] ?? "Não";
      _habilidadeSelecionado = widget.jovem!['habilidade_destaque'] ?? "Flexibilidade";
      _estaTrabalhandoSelecionado = widget.jovem!['trabalhando'] ?? "Não";
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
          cidadeEstado: _cidadeSelecionada?.trim(),
          cidadeEstadoNatal: _cidadeNatalSelecionada?.trim(),
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
          areaAprendizado: _areaAprendizadoSelecionada,
          cpf: _cpfController.text.trim(),
          horasTrabalho: _horasTrabalhoController.text.trim().isEmpty ||
              _horasTrabalhoController.text.trim() == "00:00:00"
              ? null
              : _horasTrabalhoController.text.trim(),
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
          anoIncioEscola: _anoInicioColegioController.text.trim().isNotEmpty
              ? int.parse(_anoInicioColegioController.text.trim())
              : null,
          anoConclusaoEscola: _anoFimColegioController.text.trim().isNotEmpty
              ? int.parse(_anoFimColegioController.text.trim())
              : null,
          instituicaoEscola: _instituicaoSelecionado,
          informatica: _informaticaSelecionado,
          habilidadeDestaque: _habilidadeSelecionado,
          codPis: _pisController.text.trim(),
          instagram: _instagramController.text.trim(),
          linkedin: _linkedinController.text.trim(),
          nacionalidade: _nacionalidadeSelecionada,
          moraCom: _moraComSelecionado,
          infracao: _atoInfracionalSelecionado,
          emailResponsavel: _emailResponsavelController.text.trim(),
        );

      setState(() {
        _isLoading = false;
      });

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
                initialValue: _estadoCivilSelecionado,
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
                initialValue: _sexoSelecionado,
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
                initialValue: _orientacaoSelecionado,
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
                initialValue: _identidadeSelecionado,
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
                initialValue: _corSelecionado,
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
                  DropdownMenuItem(value: 'Branca', child: Text('Branca')),
                  DropdownMenuItem(value: 'Parda', child: Text('Parda')),
                  DropdownMenuItem(value: 'Preta', child: Text('Preta')),
                  DropdownMenuItem(value: 'Amarela', child: Text('Amarela')),
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
                initialValue: _pcdSelecionado,
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
                      .select('nacionalidade')
                      .ilike('nacionalidade', '%${filtro ?? ''}%')
                      .order('nacionalidade', ascending: true);

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
                        .select('cidade_estado')
                        .ilike('cidade_estado', '%${filtro ?? ''}%')
                        .order('cidade_estado', ascending: true);

                    // Concatena cidade + UF
                    return List<String>.from(
                      response.map((e) => "${e['cidade_estado']}"),
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
                _rgController, false,
                "RG",
                isRg: true,
                onChangedState: () => setState(() {}),
              ),
              buildTextField(
                _telefoneJovemController, false,
                "Telefone do Jovem",
                isTelefone: true,
                onChangedState: () => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _moraComSelecionado,
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
                  DropdownMenuItem(value: 'Sozinho', child: Text('Sozinho')),
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
                  initialValue: _estadoCivilPaiSelecionado,
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
                  isTelefone: true,
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
                  initialValue: _estadoCivilMaeSelecionado,
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
                  isTelefone: true,
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
                  initialValue: _estadoCivilResponsavelSelecionado,
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
                  isTelefone: true,
                  onChangedState: () => setState(() {}),
                ),
              if (!_moraComSelecionado.toString().contains('Sozinho'))
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
                initialValue: _filhosSelecionado,
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
                initialValue: _membrosSelecionado,
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
                initialValue: _beneficioSelecionado,
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
                initialValue: _cadastroCrasSelecionado,
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
                initialValue: _atoInfracionalSelecionado,
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
                      .select('cidade_estado')
                      .ilike('cidade_estado', '%${filtro ?? ''}%')
                      .order('cidade_estado', ascending: true);

                  // Concatena cidade + UF
                  return List<String>.from(
                    response.map((e) => "${e['cidade_estado']}"),
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
                initialValue: _estaEstudandoSelecionado,
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
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _escolaridadeSelecionado,
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
                  initialValue:
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
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_escolaSelecionada.toString().contains(
                'ed489387-3684-459e-8ad4-bde80c2cfb66',
              ))
                buildTextField(
                  _outraEscolaController, false,
                  "Qual Colégio?",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _turnoColegioSelecionado,
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
                    DropdownMenuItem(value: 'Matutino', child: Text('Matutino')),
                    DropdownMenuItem(value: 'Vespertino', child: Text('Vespertino')),
                    DropdownMenuItem(value: 'Noturno', child: Text('Noturno')),
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
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _anoInicioColegioController, false, isAno: true,
                  "Ano de Início",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _anoFimColegioController, false, isAno: true,
                  "Ano de Conclusão (Previsto)",
                  onChangedState: () => setState(() {}),
                ),
              if (_estaEstudandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _instituicaoSelecionado,
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
                initialValue: _informaticaSelecionado,
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
                initialValue: _habilidadeSelecionado,
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
                initialValue: _estaTrabalhandoSelecionado,
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
                  initialValue:
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
                  isCtps: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _pisController, false,
                  "Código PIS",
                  isPis: true,
                  onChangedState: () => setState(() {}),
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma opção';
                    }
                    return null;
                  },
                  initialValue: _areaAprendizadoSelecionada,
                  decoration: InputDecoration(
                    labelText: "Área de Aprendizado",
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
                    DropdownMenuItem(value: 'Administração', child: Text('Administração')),
                    DropdownMenuItem(value: 'Educação', child: Text('Educação')),
                    DropdownMenuItem(value: 'Engenharia', child: Text('Engenharia')),
                    DropdownMenuItem(value: 'Saúde', child: Text('Saúde')),
                    DropdownMenuItem(value: 'Tecnologia', child: Text('Tecnologia')),
                    DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _areaAprendizadoSelecionada = value!;
                    });
                  },
                ),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                const SizedBox(height: 10),
              if (_estaTrabalhandoSelecionado.toString().contains('Sim'))
                buildTextField(
                  _horasTrabalhoController, false,
                  "Horas de Trabalho Exemplo: 08:00:00",
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
                initialValue:
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
                    child: Text("Atualizar",
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