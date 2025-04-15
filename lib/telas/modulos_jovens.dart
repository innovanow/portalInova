import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    dynamic response;

    if (auth.tipoUsuario == "jovem_aprendiz") {
      response = await supabase
          .from('jovens_aprendizes')
          .select('turma_id, turmas(modulos_turmas(modulos(*, professores(nome))))')
          .eq('id', widget.jovemId)
          .single();
    } else if (auth.tipoUsuario == "professor") {
      // Para professor: busca os módulos onde ele é o professor
      response = await supabase
          .from('modulos')
          .select('*, professores(nome)')
          .eq('professor_id', auth.idUsuario.toString());
    }

    final List<Map<String, dynamic>> resultado = [];

    if (auth.tipoUsuario == "jovem_aprendiz") {
      final modulosTurma = response['turmas']['modulos_turmas'] as List;

      for (var m in modulosTurma) {
        final modulo = m['modulos'];
        final materiais = await supabase
            .storage
            .from('fotosjovens')
            .list(path: '${modulo["id"]}/documentos/');

        final links = await Future.wait(materiais.map((file) async {
          final signedUrl = await supabase.storage
              .from('fotosjovens')
              .createSignedUrl('${modulo["id"]}/documentos/${file.name}', 3600);
          return {"nome": file.name, "url": signedUrl};
        }));

        resultado.add({
          "nomeModulo": modulo['nome'],
          "professor": modulo['professores']?['nome'] ?? "Não informado",
          "materiais": links,
        });
      }
    } else if (auth.tipoUsuario == "professor") {
      for (var modulo in response) {
        final materiais = await supabase
            .storage
            .from('fotosjovens')
            .list(path: '${modulo["id"]}/documentos/');

        final links = await Future.wait(materiais.map((file) async {
          final signedUrl = await supabase.storage
              .from('fotosjovens')
              .createSignedUrl('${modulo["id"]}/documentos/${file.name}', 3600);
          return {"nome": file.name, "url": signedUrl};
        }));

        resultado.add({
          "nomeModulo": modulo['nome'],
          "professor": modulo['professores']?['nome'] ?? "Você",
          "materiais": links,
        });
      }
    }

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
                padding: const EdgeInsets.fromLTRB(5, 40, 5, 30),
                child: carregando
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
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
                          ),
              ),]
          ),
        ),
      ),
    );
  }
}
