import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:inova/widgets/filter.dart';
import 'package:inova/widgets/wave.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../services/jovem_service.dart';
import '../services/professor_service.dart';
import '../services/uploud_docs.dart';
import '../widgets/drawer.dart';
import '../widgets/widgets.dart';

String statusProfessor = "ativo";

class CadastroProfessor extends StatefulWidget {
  const CadastroProfessor({super.key});

  @override
  State<CadastroProfessor> createState() => _CadastroProfessorState();
}

class _CadastroProfessorState extends State<CadastroProfessor> {
  final ProfessorService _professorService = ProfessorService();
  List<Map<String, dynamic>> _professores = [];
  bool _isFetching = true;
  List<Map<String, dynamic>> _professoresFiltrados = [];
  bool modoPesquisa = false;
  final TextEditingController _pesquisaController = TextEditingController();
  final DocService _docsService = DocService();
  String? _uploadStatus;
  DropzoneViewController? _controller;

  @override
  void initState() {
    super.initState();
    _carregarProfessores(statusProfessor);
  }

  void _carregarProfessores(String statusProfessor) async {
    final professores = await _professorService.buscarprofessor(statusProfessor);
    setState(() {
      _professores = professores;
      _professoresFiltrados = List.from(_professores);
      _isFetching = false;
    });
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
                jovem == null ? "Cadastrar Prof." : "Editar Prof.",
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
              _carregarProfessores(statusProfessor); // Atualiza lista ao fechar modal
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void inativarProfessor(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja inativar este professor?",
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
                await _professorService
                    .inativarProfessor(id);
                _carregarProfessores(statusProfessor);
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

  void ativarProfessor(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Tem certeza de que deseja ativar este professor?",
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
                await _professorService
                    .ativarProfessor(id);
                _carregarProfessores(statusProfessor);
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
      'Professor',
      'Aulas no Mês',
      'Valor Hora/Aula',
      'Total a Receber'
    ];

    // Mapeia os dados recebidos do Supabase para o formato da tabela
    final data = dadosRelatorio.map((row) {
      return [
        row['professor_nome'] ?? 'N/A',
        row['total_aulas_no_mes']?.toString() ?? '0',
        _formatCurrency(row['valor_hora_aula']?.toDouble()),
        _formatCurrency(row['valor_total_a_receber']?.toDouble()),
      ];
    }).toList();

    // Calcula o valor total para o rodapé
    final double valorTotalGeral = dadosRelatorio.fold(
        0.0,
            (sum, item) =>
        sum + (item['valor_total_a_receber']?.toDouble() ?? 0.0));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'Relatório de Pagamento - ${mes.toString().padLeft(2, '0')}/$ano',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SvgImage(svg: logoSvg, width: 60),
              ],
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
          ]);
        },
        build: (pw.Context context) => [
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
                          .from('relatorio_pagamento_professores')
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

  @override
  Widget build(BuildContext context) {
    final isAtivo = statusProfessor.toLowerCase() == 'ativo';
    return GestureDetector(
      onTap: () {
        if (modoPesquisa) {
          setState(() {
            modoPesquisa = false;
            _pesquisaController.clear(); // 🔹 Limpa a pesquisa ao sair
            _professoresFiltrados = List.from(_professores); // 🔹 Restaura a lista original
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
                  hintText: "Pesquisar professor...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  filtrarLista(
                    query: value,
                    listaOriginal: _professores,
                    atualizarListaFiltrada: (novaLista) {
                      setState(() => _professoresFiltrados = novaLista);
                    },
                  );
                },
              )
                  : const Text(
                'Professores',
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
                    _professores,
                        (novaLista) => setState(() {
                      _professoresFiltrados = novaLista;
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
                    modoPesquisa = true;
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
                                          "Professores: ${isAtivo ? "Ativos" : "Inativos"}",
                                          textAlign: TextAlign.end,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Tooltip(
                                          message: isAtivo ? "Exibir Inativos" : "Exibir Ativos",
                                          child: Switch(
                                            value: isAtivo,
                                            onChanged: (value) {
                                              setState(() {
                                                statusProfessor = value ? "ativo" : "inativo";
                                              });
                                              _carregarProfessores(statusProfessor);
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
                                  itemCount: _professoresFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final professor = _professoresFiltrados[index];
                                    return Card(
                                      elevation: 3,
                                      child: ListTile(
                                        title: Text(
                                          professor['nome'] ?? '',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        leading: const Icon(Icons.man, color: Colors.black,),
                                        subtitle: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Formação: ${professor['formacao'] ?? ''}",
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
                                                        color: Colors.black,
                                                        size: 20
                                                    ),
                                                    onPressed:
                                                        () => _abrirFormulario(
                                                      jovem: professor,
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
                                                    onPressed: () => _abrirDocumentos(context, professor['id']),
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
                                                    onPressed: () => isAtivo == true ? inativarProfessor(professor['id']) : ativarProfessor(professor['id']),
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
            tooltip: "Cadastrar Professor",
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
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _formacaoController = TextEditingController();
  final _valorHoraAulaController = TextEditingController();
  final _valorHoraAula2Controller = TextEditingController();
  final _codCarteiraTrabalhoController = TextEditingController();
  final _rgController = TextEditingController();
  final _cepController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _cidadeSelecionada;
  String? _cidadeNatalSelecionada;
  String? _nacionalidadeSelecionada;
  String? _estadoCivilSelecionado;
  String? _internoSelecionado;
  bool _isLoading = false;
  String? _errorMessage;
  bool _editando = false;
  String? _jovemId;
  String? _sexoSelecionado;
  String? _escolaSelecionada;
  final JovemService _jovemService = JovemService();
  List<Map<String, dynamic>> _escolas = [];
  final List<Map<String, dynamic>> escolas = [];
  // Criando um formatador de data no formato "yyyy-MM-dd"
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  String formatarDataParaExibicao(String data) {
    DateTime dataConvertida = DateTime.parse(data); // Converte string para DateTime
    return DateFormat('dd/MM/yyyy').format(dataConvertida); // Retorna formatado
  }
  String formatarDinheiro(double valor) {
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatador.format(valor);
  }

  final ProfessorService _professorService = ProfessorService();

  @override
  void initState() {
    super.initState();
    _carregarEscolas();
    if (widget.jovem != null) {
      _editando = true;
      _jovemId = widget.jovem!['id'] ?? "";
      _nomeController.text = widget.jovem!['nome'] ?? "";
      _dataNascimentoController.text = formatarDataParaExibicao(widget.jovem!['data_nascimento'] ?? "");
      _enderecoController.text = widget.jovem!['endereco'] ?? "";
      _numeroController.text = widget.jovem!['numero'] ?? "";
      _bairroController.text = widget.jovem!['bairro'] ?? "";
      _cidadeSelecionada = widget.jovem!['cidade_estado'] ?? "Palotina-PR";
      _cidadeNatalSelecionada = widget.jovem!['cidade_natal'] ?? "Palotina-PR";
      _nacionalidadeSelecionada = widget.jovem!['nacionalidade'] ?? "Brasileira";
      _codCarteiraTrabalhoController.text = widget.jovem!['cod_carteira_trabalho'] ?? "";
      _rgController.text = widget.jovem!['rg'] ?? "";
      _cepController.text = widget.jovem!['cep'] ?? "";
      _cpfController.text = widget.jovem!['cpf'] ?? "";
      _telefoneController.text = widget.jovem!['telefone'] ?? "";
      _formacaoController.text = widget.jovem!['formacao'] ?? "";
      _valorHoraAulaController.text = formatarDinheiro(
        double.tryParse(widget.jovem?['valor_hora_aula']?.toString() ?? '0.0') ?? 0.0,
      );
      _valorHoraAula2Controller.text = formatarDinheiro(
        double.tryParse(widget.jovem?['valor_hora_aula2']?.toString() ?? '0.0') ?? 0.0,
      );
      _estadoCivilSelecionado = widget.jovem!['estado_civil'] ?? "";
      _sexoSelecionado= widget.jovem!['sexo'] ?? "";
      _internoSelecionado = widget.jovem!['interno'] == true ? 'interno' : 'externo';
      _escolaSelecionada = widget.jovem!['id_colegio'] ?? "";
    }
  }

  void _carregarEscolas() async {
    final escolas = await _jovemService.buscarEscolas();
    setState(() {
      _escolas = escolas;
    });
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error;
      if (_editando) {
        error = await _professorService.atualizarprofessor(
          id: _jovemId!,
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidadeEstado: _cidadeSelecionada?.trim(),
          nacionalidade: _nacionalidadeSelecionada?.trim(),
          cidadeEstadoNatal: _cidadeNatalSelecionada?.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          cep: _cepController.text.trim(),
          cpf: _cpfController.text.trim(),
          telefone: _telefoneController.text.trim(),
          formacao: _formacaoController.text.trim(),
          estadoCivil: _estadoCivilSelecionado,
          sexo: _sexoSelecionado,
          horaAula: _valorHoraAulaController.text.trim(),
          interno: _internoSelecionado == 'interno' ? true : false,
          idColegio: _escolaSelecionada,
          horaAula2: _valorHoraAula2Controller.text.trim(),
        );
      } else {
        error = await _professorService.cadastrarprofessor(
          nome: _nomeController.text.trim(),
          dataNascimento: _dataNascimentoController.text.isNotEmpty
              ? formatter.format(DateFormat('dd/MM/yyyy').parse(_dataNascimentoController.text))
              : null,
          endereco: _enderecoController.text.trim(),
          numero: _numeroController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidadeEstado: _cidadeSelecionada?.trim(),
          nacionalidade: _nacionalidadeSelecionada?.trim(),
          cidadeEstadoNatal: _cidadeNatalSelecionada?.trim(),
          rg: _rgController.text.trim(),
          codCarteiraTrabalho: _codCarteiraTrabalhoController.text.trim(),
          cep: _cepController.text.trim(),
          email: _emailController.text.trim(),
          senha: _senhaController.text.trim(),
          cpf: _cpfController.text.trim(),
          telefone: _telefoneController.text.trim(),
          formacao: _formacaoController.text.trim(),
          estadoCivil: _estadoCivilSelecionado,
          sexo: _sexoSelecionado,
          horaAula: _valorHoraAulaController.text.trim(),
          interno: _internoSelecionado == 'interno' ? true : false,
          idColegio: _escolaSelecionada,
          horaAula2: _valorHoraAula2Controller.text.trim(),
        );
      }

      setState(() => _isLoading = false);

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
              buildTextField(_nomeController, true, "Nome", onChangedState: () => setState(() {})),
              if (!_editando) ...[
                buildTextField(_emailController, true, "E-mail", isEmail: true, onChangedState: () => setState(() {})),
                buildTextField(_senhaController, true, "Senha", isPassword: true, onChangedState: () => setState(() {})),
              ],
              buildTextField(_dataNascimentoController, false, "Data de Nascimento", isData: true, onChangedState: () => setState(() {})),
              DropdownButtonFormField<String>(
                initialValue: _sexoSelecionado,
                decoration: InputDecoration(
                  labelText: "Sexo",
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
                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  DropdownMenuItem(value: 'Prefiro não informar', child: Text('Prefiro não informar')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexoSelecionado = value!;
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
              buildTextField(_cpfController, false, "CPF", isCpf: true, onChangedState: () => setState(() {})),
              buildTextField(_rgController, false, "RG", isRg: false, onChangedState: () => setState(() {})),
              buildTextField(_codCarteiraTrabalhoController, false, "Carteira de Trabalho", onChangedState: () => setState(() {})),
              buildTextField(_enderecoController, false, "Endereço", onChangedState: () => setState(() {})),
              buildTextField(_numeroController, false, "Número", onChangedState: () => setState(() {})),
              buildTextField(_bairroController, false, "Bairro", onChangedState: () => setState(() {})),
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
              buildTextField(_cepController, false, "CEP", isCep: true, onChangedState: () => setState(() {})),
              buildTextField(_telefoneController, false, "Telefone", onChangedState: () => setState(() {})),
              buildTextField(_formacaoController, false, "Formação", onChangedState: () => setState(() {})),
              DropdownButtonFormField<String>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma opção';
                  }
                  return null;
                },
                initialValue: _internoSelecionado,
                decoration: InputDecoration(
                  labelText: "Tipo",
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
                  DropdownMenuItem(value: 'interno', child: Text('Interno')),
                  DropdownMenuItem(value: 'externo', child: Text('Externo')),
                ],
                onChanged: (value) {
                  setState(() {
                    _internoSelecionado = value!;
                  });
                },
              ),
              if (_internoSelecionado == 'interno')
              const SizedBox(height: 10),
              if (_internoSelecionado == 'interno')
              buildTextField(
                _valorHoraAulaController, true,
                "Valor Hora Aula",
                isDinheiro: true,
                onChangedState: () => setState(() {}),
              ),
              if (_internoSelecionado == 'interno')
                buildTextField(
                  _valorHoraAula2Controller, true,
                  "Valor Hora Aula Sescoop",
                  isDinheiro: true,
                  onChangedState: () => setState(() {}),
                ),
              const SizedBox(height: 10),
              if (_internoSelecionado == 'externo')
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