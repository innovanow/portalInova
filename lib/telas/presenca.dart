import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inova/telas/splash.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../services/presenca_service.dart';
import 'package:intl/intl.dart';
import '../widgets/drawer.dart';
import '../widgets/wave.dart';
import 'historico_chamada.dart';

class RegistrarPresencaPage extends StatefulWidget {
  final String professorId;

  const RegistrarPresencaPage({super.key, required this.professorId});

  @override
  State<RegistrarPresencaPage> createState() => _RegistrarPresencaPageState();
}

class _RegistrarPresencaPageState extends State<RegistrarPresencaPage> {
  final PresencaService _presencaService = PresencaService();

  List<Map<String, dynamic>> _modulos = [];
  Map<String, dynamic>? _moduloSelecionado;
  DateTime _dataSelecionada = DateTime.now();

  List<Map<String, dynamic>> _alunos = [];
  Map<String, bool> _presencas = {};

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  Future<void> _carregarModulos() async {
    if (kDebugMode) {
      print("🔍 Buscando módulos para: ${widget.professorId}");
    }
    final modulos = await _presencaService.listarModulosDoProfessor(widget.professorId);
    if (kDebugMode) {
      print("🔢 Módulos encontrados: ${modulos.length}");
    }
    setState(() {
      _modulos = modulos;
    });
  }


  Future<void> _carregarAlunosPorTurmaId(String turmaId) async {
    setState(() => _carregando = true);

    final alunos = await _presencaService.listarAlunosPorTurma(turmaId);
    setState(() {
      _alunos = alunos;
      _presencas = {for (var aluno in alunos) aluno['id']: true};
      _carregando = false;
    });
  }


  Future<void> _salvarPresencas() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Text(
            "Tem certeza de que deseja salvar as presenças?",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'LeagueSpartan',
            ),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
              ),
              onPressed: () => Navigator.pop(context),
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
                try {
                  final lista = _alunos.map((aluno) {
                    return {
                      'id': aluno['id'],
                      'presente': _presencas[aluno['id']] ?? false,
                    };
                  }).toList();

                  try {
                    await _presencaService.salvarPresencas(
                      listaPresenca: lista,
                      turmaId: _moduloSelecionado!['turma_id'],
                      moduloId: _moduloSelecionado!['id'],
                      data: _dataSelecionada,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SplashScreen(title: 'Registrado!',)));
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Erro ao salvar presenças: $e');
                    }
                    if (e.toString().contains('duplicate key')) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Color(0xFF0A63AC),
                              content: Text('Já existe presença registrada nesta data.',
                                  style: TextStyle(
                                color: Colors.white,
                              ))),
                        );
                        Navigator.of(context).pop();
                      }
                    } else {
                      debugPrint('Erro ao salvar presenças: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar presença: $e')),
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('Erro geral: $e');
                }
              },
              child: const Text("Confirmar",
                  style: TextStyle(color: Colors.green,
                    fontFamily: 'LeagueSpartan',
                    fontSize: 15,
                  )
              ),
            ),
          ],
        );
      },
    );
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
      setState(() {
        _dataSelecionada = data;
      });
    }
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
                      Text("Presenças",
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                        IconButton(
                          tooltip: "Histórico",
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          enableFeedback: false,
                          onPressed: (){
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => HistoricoChamadasPage(professorId: '${auth.idUsuario}',)));
                          },
                          icon: Icon(
                            Icons.history,
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                        height: 45,
                        color: Colors.orange
                    ),
                  ),
                ),
                // Onda Superior Azul sobreposta
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
                // Conteúdo Centralizado
                // Dropdown de Módulos
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 60, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 10,
                    children: [
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _moduloSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Selecione o Módulo',
                          border: OutlineInputBorder(),
                        ),
                        items: _modulos.map((modulo) {
                          final label = 'Turma: ${modulo['nome']}';
                          return DropdownMenuItem(
                            value: modulo,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (kDebugMode) {
                            print(value?['turma_id'].toString());
                          }
                          if (value != null) {
                            _carregarAlunosPorTurmaId(value['turma_id'].toString());
                            setState(() {
                              _moduloSelecionado = value;
                            });
                          }
                        },
                      ),
                      // Seletor de Data
                      InkWell(
                        onTap: _selecionarData,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      Text( _moduloSelecionado == null ? "Selecione um módulo para registrar as presenças." : "Desmarque os jovens que não estiveram presentes:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,)),
                      _carregando
                          ? const Expanded(child: Center(child: CircularProgressIndicator()))
                          : Expanded(
                        child: SuperListView.builder(
                          itemCount: _alunos.length,
                          itemBuilder: (context, index) {
                            final aluno = _alunos[index];
                            return Column(
                              children: [
                                CheckboxListTile(
                                  title: Text("${index + 1} - ${aluno['nome']}"),
                                  value: _presencas[aluno['id']] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      _presencas[aluno['id']] = value ?? false;
                                    });
                                  },
                                ),
                                const Divider(height: 1), // <- divide os itens
                              ],
                            );
                          },
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text("Salvar Presença",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                )),
                            onPressed: _moduloSelecionado == null ? null : _salvarPresencas,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              disabledBackgroundColor: Colors.grey,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}