import 'package:flutter/material.dart';
import 'package:inova/cadastros/register_jovem.dart';
import 'package:intl/intl.dart';
import '../services/ocorrencia_service.dart';
import '../telas/home.dart';
import '../widgets/wave.dart';

class OcorrenciasScreen extends StatefulWidget {
  final String jovemId;
  final String nomeJovem;

  const OcorrenciasScreen({super.key, required this.jovemId, required this.nomeJovem});

  @override
  State<OcorrenciasScreen> createState() => _OcorrenciasScreenState();
}

class _OcorrenciasScreenState extends State<OcorrenciasScreen> {
  final OcorrenciaService _ocorrenciaService = OcorrenciaService();
  List<Map<String, dynamic>> _ocorrencias = [];
  bool _isCarregando = true;
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data);
    return DateFormat('dd/MM/yyyy').format(dataConvertida);
  }

  @override
  void initState() {
    super.initState();
    _carregarOcorrencias();
  }

  Future<void> _carregarOcorrencias() async {
    final ocorrencias = await _ocorrenciaService.buscarOcorrenciasPorJovem(widget.jovemId);
    setState(() {
      _ocorrencias = ocorrencias;
      _isCarregando = false;
    });
  }

  void _abrirCadastroOcorrencia() {
    String tipoSelecionado = 'escola';
    TextEditingController descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A63AC),
        title: const Text("Nova Ocorrência", style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'FuturaBold')),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tipoSelecionado,
                decoration: InputDecoration(
                  labelText: "Tipo",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: const Color(0xFF0A63AC),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'escola', child: Text('Colégio')),
                  DropdownMenuItem(value: 'instituto', child: Text('Instituto')),
                  DropdownMenuItem(value: 'empresa', child: Text('Empresa')),
                ],
                onChanged: (value) => tipoSelecionado = value!,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descricaoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Descreva",
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              if (descricaoController.text.isNotEmpty) {
                await _ocorrenciaService.cadastrarOcorrencia(
                  jovemId: widget.jovemId,
                  tipo: tipoSelecionado,
                  descricao: descricaoController.text,
                  idUsuario: auth.idUsuario,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _carregarOcorrencias();
                }
              }
            },
            child: const Text("Salvar", style: TextStyle(color: Colors.orange)),
          )
        ],
      ),
    );
  }

  Widget _buildListaPorTipo(String tipo) {
    final ocorrenciasTipo = _ocorrencias.where((o) => o['tipo'] == tipo).toList();

    if (ocorrenciasTipo.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Define as bordas arredondadas do Card
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF0A63AC),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          title: Text(
            "Ocorrências: ${tipo.replaceAll("escola", "Colégio").replaceAll("instituto", "Instituto").replaceAll("empresa", "Empresa")}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          children: ocorrenciasTipo.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final oc = entry.value;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text("Ocorrência $index:\n${oc['descricao']}", style: const TextStyle(color: Colors.black)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Data: ${formatarDataParaExibicao(oc['data_ocorrencia'].toString().substring(0, 10))}", style: const TextStyle(color: Colors.black)),
                        if (oc['resolvido'] == true && oc['data_resolucao'] != null)
                          Text("Resolvido em: ${formatarDataParaExibicao(oc['data_resolucao'].toString())}", style: const TextStyle(color: Colors.green)),
                        if (oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty)
                          Text("Obs: ${oc['observacoes']}", style: const TextStyle(color: Colors.orange)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  oc['resolvido'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: oc['resolvido'] == true ? Colors.green : Colors.black,
                                ),
                                tooltip: oc['resolvido'] == true ? "Marcar como não resolvido" : "Marcar como resolvido",
                                onPressed: () async {
                                  if (oc['resolvido'] == true) {
                                    await _ocorrenciaService.desmarcarComoResolvido(oc['id']);
                                    setState(() {
                                      final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                      if (index != -1) {
                                        _ocorrencias[index]['resolvido'] = false;
                                        _ocorrencias[index]['data_resolucao'] = null;
                                      }
                                    });
                                  } else {
                                    await _ocorrenciaService.marcarComoResolvido(oc['id']);
                                    setState(() {
                                      final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                      if (index != -1) {
                                        _ocorrencias[index]['resolvido'] = true;
                                        _ocorrencias[index]['data_resolucao'] = DateTime.now().toIso8601String();
                                      }
                                    });
                                  }
                                },
                              ),
                              Container(
                                width: 2, // Espessura da linha
                                height: 30, // Altura da linha
                                color: Colors.black.withValues(alpha: 0.2), // Cor da linha
                              ),
                              IconButton(
                                icon: Icon(Icons.comment, color: oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty ? Colors.orange : Colors.black),
                                tooltip: oc['observacoes'] != null && oc['observacoes'].toString().trim().isNotEmpty ? "Editar observação" : "Adicionar observação",
                                onPressed: () async {
                                  TextEditingController obsController = TextEditingController();
                                  obsController.text = oc['observacoes'] ?? '';
                                  await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF0A63AC),
                                      title: const Text("Observação",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontFamily: 'FuturaBold',
                                        ),),
                                      content: SizedBox(
                                        width: MediaQuery.of(context).size.width,
                                        child: TextField(
                                          controller: obsController,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: "Observações",
                                            labelStyle: const TextStyle(color: Colors.white),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color: Colors.white),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color: Colors.white, width: 2.0),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancelar", style: TextStyle(color: Colors.orange)),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await _ocorrenciaService.adicionarObservacao(oc['id'], obsController.text);
                                            if (mounted) {
                                              Navigator.pop(context);
                                              setState(() {
                                                final index = _ocorrencias.indexWhere((item) => item['id'] == oc['id']);
                                                if (index != -1) {
                                                  _ocorrencias[index]['observacoes'] = obsController.text;
                                                }
                                              });
                                            }
                                          },
                                          child: const Text("Salvar", style: TextStyle(color: Colors.orange)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 2, // Espessura da linha
                                height: 30, // Altura da linha
                                color: Colors.black.withValues(alpha: 0.2), // Cor da linha
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.black),
                                tooltip: "Excluir ocorrência",
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF0A63AC),
                                      title: const Text("Excluir ocorrência",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontFamily: 'FuturaBold',
                                        ),),
                                      content: const Text("Tem certeza que deseja excluir esta ocorrência?", style: TextStyle(color: Colors.white)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Cancelar", style: TextStyle(color: Colors.orange)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Excluir", style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _ocorrenciaService.excluirOcorrencia(oc['id']);
                                    setState(() {
                                      _ocorrencias.removeWhere((item) => item['id'] == oc['id']);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
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
                        Text("Ocorrências: ${widget.nomeJovem}",
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
            _isCarregando
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.fromLTRB(10, 40, 10, 60),
              child: ListView(
                children: [
                  _buildListaPorTipo('escola'),
                  _buildListaPorTipo('instituto'),
                  _buildListaPorTipo('empresa'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Nova Ocorrência",
        onPressed: _abrirCadastroOcorrencia,
        backgroundColor: const Color(0xFF0A63AC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}