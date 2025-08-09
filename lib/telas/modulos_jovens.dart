import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:url_launcher/url_launcher.dart';

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
            .eq('turma_id', turmaId);
      }

      // --- Lógica para Professor ---
    } else if (auth.tipoUsuario == "professor") {
      // A lógica para professor permanece a mesma.
      modulosResponse = await supabase
          .from('modulos')
          .select('*, professores(nome)')
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
      });
    }

    // Atualiza o estado da UI
    setState(() {
      modulos = resultado;
      carregando = false;
    });
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
                            fontFamily: 'FuturaBold',
                            fontWeight: FontWeight.bold,
                            fontSize: constraints.maxWidth > 800 ? 20 : 15,
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
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                onTap: () => launchUrl(
                                  Uri.parse(doc['url']),
                                  mode: LaunchMode.externalApplication,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                            ) : const Center(
                    child: Text('Nenhum módulo encontrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'FuturaBold',
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
