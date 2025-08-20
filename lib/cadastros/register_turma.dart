import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import '../services/turma_service.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';

String statusTurma = "ativo";

class TurmaScreen extends StatefulWidget {
  const TurmaScreen({super.key});

  @override
  State<TurmaScreen> createState() => _TurmaScreenState();
}

class _TurmaScreenState extends State<TurmaScreen> {
  final TurmaService _turmaService = TurmaService();
  List<Map<String, dynamic>> _turmas = [];
  bool _isFetching = true;
  bool modoPesquisa = false;
  List<Map<String, dynamic>> _turmasFiltradas = [];
  final TextEditingController _pesquisaController = TextEditingController();
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
        .replaceAll(RegExp(r"[^\w.]+"), "_"); // Substitui outros caracteres especiais por _
  }


  @override
  void initState() {
    super.initState();
    _carregarTurmas(statusTurma);
  }

  void _carregarTurmas(String statusTurma) async {
    final turmas = await _turmaService.buscarTurmas(statusTurma);
    setState(() {
      _turmas = turmas;
      _turmasFiltradas = List.from(_turmas);
      _isFetching = false;
    });
  }

  void _abrirFormulario({Map<String, dynamic>? turma}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                turma == null ? "Cadastrar Turma" : "Editar Turma",
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
          content: _FormTurma(
            turma: turma,
            onTurmaSalva: () {
              _carregarTurmas(statusTurma); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarTurma(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar esta turma?",
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
                await _turmaService
                    .inativarTurma(id);
                _carregarTurmas(statusTurma);
                if (context.mounted){
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text("Inativar",
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

  void ativarTurma(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar esta turma?",
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
                await _turmaService
                    .ativarTurma(id);
                _carregarTurmas(statusTurma);
                if (context.mounted){
                  Navigator.of(context).pop(); // Fecha o alerta
                }
              },
              child: const Text("Ativar",
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
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb)
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

                      return SuperListView.builder(
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
                                                fontFamily: 'LeagueSpartan',
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
                                                    fontFamily: 'LeagueSpartan',
                                                    fontSize: 15,
                                                  ))),
                                              TextButton(
                                                  style: ButtonStyle(
                                                    overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove o destaque ao passar o mouse
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text("Excluir",style: TextStyle(color: Colors.red,
                                                    fontFamily: 'LeagueSpartan',
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
                      fontFamily: 'LeagueSpartan',
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
                      fontFamily: 'LeagueSpartan',
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

  /// Abre o diálogo para selecionar o mês e ano e iniciar a geração do relatório.
  void _abrirDialogoRelatorio() {
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    // Gera uma lista de anos, por exemplo, dos últimos 5 anos até o próximo.
    final anos =
    List.generate(6, (index) => DateTime.now().year - 5 + index + 1);
    String? mesSelecionado = meses[DateTime.now().month - 1];
    int? anoSelecionado = DateTime.now().year;
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A63AC),
              title: Text('Gerar Relatório Pagamento',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 800 ? 20 : 15,
                  color: Colors.white,
                  fontFamily: 'LeagueSpartan',
                ),),
              content: SizedBox(
                width: 400,
                height: 150,
                child: isLoading
                    ? const Center(
                    child:
                    SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Colors.white
                        )))
                    : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown para Mês
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Mês",
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                              const BorderSide(color: Colors.white)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2.0)),
                        ),
                        initialValue: mesSelecionado,
                        dropdownColor: const Color(0xFF0A63AC),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        style: const TextStyle(color: Colors.white),
                        items: meses.map((String mes) {
                          return DropdownMenuItem<String>(
                              value: mes, child: Text(mes));
                        }).toList(),
                        onChanged: (String? novoValor) {
                          setStateDialog(() {
                            mesSelecionado = novoValor;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      // Dropdown para Ano
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Ano",
                          labelStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                              const BorderSide(color: Colors.white)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2.0)),
                        ),
                        initialValue: anoSelecionado,
                        dropdownColor: const Color(0xFF0A63AC),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        style: const TextStyle(color: Colors.white),
                        items: anos.map((int ano) {
                          return DropdownMenuItem<int>(
                              value: ano, child: Text(ano.toString()));
                        }).toList(),
                        onChanged: (int? novoValor) {
                          setStateDialog(() {
                            anoSelecionado = novoValor;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Fechar",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'LeagueSpartan',
                      fontSize: 15,
                    ),),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (mesSelecionado == null || anoSelecionado == null) {
                      return;
                    }

                    setStateDialog(() {
                      isLoading = true;
                    });

                    try {
                      // Converte o nome do mês para número (1-12)
                      final numeroMes = meses.indexOf(mesSelecionado!) + 1;

                      // Busca os dados da view no Supabase
                      final response = await Supabase.instance.client
                          .from('relatorio_gastos_cantina')
                          .select()
                          .eq('mes', numeroMes)
                          .eq('ano', '$anoSelecionado');

                      // O Supabase retorna uma lista de mapas
                      final dados = response;

                      // Fecha o diálogo antes de gerar o PDF
                      if (context.mounted){
                        Navigator.of(context).pop();
                      }
                      await _gerarPdfRelatorio(
                          dados, numeroMes, anoSelecionado!);
                    } catch (e) {
                      debugPrint('Erro ao buscar dados: $e');
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erro ao buscar dados: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      // Garante que o estado de loading seja resetado
                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text("Gerar PDF",
                    style: TextStyle(
                      color: Colors.orange,
                      fontFamily: 'LeagueSpartan',
                      fontSize: 15,
                    ),),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'R\$ 0,00';
    final format =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
    return format.format(value);
  }

  /// Gera o PDF com base nos dados do relatório de pagamento dos professores.
  Future<void> _gerarPdfRelatorio(List<Map<String, dynamic>> dadosRelatorio,
      int mes, int ano) async {
    if (dadosRelatorio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum dado encontrado para o período selecionado.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final doc = pw.Document();
    final logoSvg = await rootBundle.loadString('assets/logoInova.svg');

    // Cabeçalhos da tabela do PDF
    const headers = [
      'Turma',
      'Lanches no Mês',
      'Valor Lanche',
      'Total a Gasto'
    ];

    // Mapeia os dados recebidos do Supabase para o formato da tabela
    final data = dadosRelatorio.map((row) {
      return [
        row['turma'] ?? 'N/A',
        row['total_lanches_no_mes']?.toString() ?? '0',
        _formatCurrency(3.50),
        _formatCurrency(row['valor_total_gasto']?.toDouble()),
      ];
    }).toList();

    // Calcula o valor total para o rodapé
    final double valorTotalGeral = dadosRelatorio.fold(
        0.0,
            (sum, item) =>
        sum + (item['valor_total_gasto']?.toDouble() ?? 0.0));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'Relatório de Pagamento Lanche - ${mes.toString().padLeft(
                        2, '0')}/$ano',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SvgImage(svg: logoSvg, width: 60),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
          ]);
        },
        build: (pw.Context context) =>
        [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(color: PdfColors.grey600),
            headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Professor
              1: const pw.FlexColumnWidth(1.5), // Aulas no Mês
              2: const pw.FlexColumnWidth(1.5), // Valor Hora/Aula
              3: const pw.FlexColumnWidth(2), // Total a Receber
            },
          ),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10.0),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Divider(color: PdfColors.grey),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Valor Total do Mês: ${_formatCurrency(valorTotalGeral)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ]),
          );
        },
      ),
    );

    // Bloco para salvar e compartilhar o PDF
    try {
      final bytes = await doc.save();
      final fileName = 'Relatorio_Pagamento_${mes}_${ano}_Cantina.pdf';
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..style.display = 'none'
          ..setAttribute("download", fileName);
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/$fileName");
        await file.writeAsBytes(bytes);
        final files = [XFile(file.path, name: fileName)];
        await SharePlus.instance.share(ShareParams(
          files: files,
          text: 'Relatório de Pagamento de Cantina',
          subject: 'Relatório de Pagamento Cantina',
        ));
      }
    } catch (e) {
      debugPrint('Erro ao gerar ou abrir o PDF: $e');
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao gerar PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusTurma.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _turmasFiltradas = List.from(_turmas); // 🔹 Restaura a lista original
          });
        }
      },
      child: PopScope(
        canPop: kIsWeb ? false : true, // impede voltar
        child: Scaffold(
          backgroundColor: Color(0xFF0A63AC),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: AppBar(
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: const Color(0xFF0A63AC),
              title: modoPesquisa
                  ? TextField(
                controller: _pesquisaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Pesquisar turma...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  filtrarLista(
                    query: value,
                    listaOriginal: _turmas,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _turmasFiltradas = novaLista);
                    },
                  );
                },
              )
                  : const Text(
                'Turmas',
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
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
                    _turmas,
                        (novaLista) => setState(() {
                      _turmasFiltradas = novaLista;
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                                  "Turmas: ${isAtivo ? "Ativas" : "Inativas"}",
                                                  textAlign: TextAlign.end,
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Tooltip(
                                                  message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                                  child: Switch(
                                                    value: isAtivo,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        statusTurma = value ? "ativo" : "inativo";
                                                      });
                                                      _carregarTurmas(statusTurma);
                                                    },
                                                    activeThumbColor: Color(0xFF0A63AC),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: "Gerar Relatório PDF",
                                          onPressed: _abrirDialogoRelatorio,
                                          icon: Icon(Icons.picture_as_pdf, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: constraints.maxHeight - 100,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child:
                                _isFetching
                                    ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                    : SuperListView.builder(
                                  itemCount: _turmasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final turma = _turmasFiltradas[index];
                                    return Card(
                                      elevation: 3,
                                      child: ListTile(
                                        title: Text(
                                          "Turma: ${turma['codigo_turma']}",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        leading: const Icon(Icons.groups, color: Colors.black,),
                                        subtitle: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ano: ${turma['ano']} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_inicio']))} até ${DateFormat('dd/MM/yyyy').format(DateTime.parse(turma['data_termino']))}",
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
                                                    turma: turma,
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
                                                    onPressed: () => _abrirDocumentos(context, turma['id']),
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
                                                  onPressed: () => isAtivo == true ? inativarTurma(turma['id']) : ativarTurma(turma['id']),
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
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: "Cadastrar Turma",
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

class _FormTurma extends StatefulWidget {
  final Map<String, dynamic>? turma;
  final VoidCallback onTurmaSalva;

  const _FormTurma({this.turma, required this.onTurmaSalva});

  @override
  _FormTurmaState createState() => _FormTurmaState();
}

class _FormTurmaState extends State<_FormTurma> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _anoController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataTerminoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _turmaId;
  final TurmaService _turmaservice = TurmaService();
  //final TurmaService _moduloService = TurmaService();
  //List<Map<String, dynamic>> _modulos = [];
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  List<String> modulosSelecionados = []; // Lista para armazenar os módulos selecionados

  @override
  void initState() {
    super.initState();
    //_carregarModulos();

    if (widget.turma != null) {
      _editando = true;
      _turmaId = widget.turma!['id'].toString();
      _codigoController.text = widget.turma!['codigo_turma'];
      _anoController.text = widget.turma!['ano'].toString();
      _dataInicioController.text = formatarDataParaExibicao(widget.turma!['data_inicio'] ?? "");
      _dataTerminoController.text = formatarDataParaExibicao(widget.turma!['data_termino'] ?? "");

      /*_turmaservice.buscarModulosDaTurma(_turmaId!).then((modulos) {
        if (kDebugMode) {
          print("Modulos da turma: $modulos");
        }
        setState(() {
          modulosSelecionados = modulos;
        });
      });*/
    }
  }

/*  void _carregarModulos() async {
    final modulos = await _moduloService.buscarModulos();
    setState(() {
      _modulos = modulos;
    });
  }*/

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _turmaservice.atualizarTurmas(
          id: _turmaId!,
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          //modulosSelecionados: modulosSelecionados,
        );
      } else {
        error = await _turmaservice.cadastrarTurmas(
          codigo: _codigoController.text.trim(),
          ano: int.parse(_anoController.text.trim()),
          dataInicio: _dataInicioController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataInicioController.text))
              : null,
          dataTermino: _dataTerminoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataTerminoController.text))
              : null,
          //modulosSelecionados: modulosSelecionados,
        );
      }

      setState(() => _isLoading = false);

      if (error == null) {
        widget.onTurmaSalva();
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
              buildTextField(_codigoController, true, "Código da Turma", onChangedState: () => setState(() {})),
              buildTextField(_anoController, true, "Ano", isAno: true, onChangedState: () => setState(() {})),
              buildTextField(_dataInicioController, true, "Data de Início", isData: true, onChangedState: () => setState(() {})),
              buildTextField(_dataTerminoController, true, "Data de Término", isData: true, onChangedState: () => setState(() {})),
              /*MultiSelectChips(
                modulos: _modulos, // Lista de módulos carregada do Supabase
                onSelecionado: (selecionados) {
                  setState(() {
                    modulosSelecionados = selecionados;
                  });
                },
                modulosSelecionados: modulosSelecionados, // Garante que os valores iniciais sejam preenchidos
              ),*/
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
