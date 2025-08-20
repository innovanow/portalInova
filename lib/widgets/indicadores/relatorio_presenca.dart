import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'dart:ui' as ui;

import 'package:universal_html/html.dart' as html; // Import for Color

class RelatorioService {
  static final _client = Supabase.instance.client;

  /// Gera um relatório de frequência em Excel usando Syncfusion XlsIO.
  static Future<void> gerarRelatorioPresenca({
    required String moduloId,
    required String turmaId,
    required String moduloNome,
    required String codigoTurma,
    required String instituicao,
    required String projeto,
    required String localSala,
    required String cargaHoraria,
    required String horario,
    required int? mes,
    required int ano,
    required BuildContext context,
  }) async {
    // --- Carrega a imagem do logo dos assets ---
    final ByteData imageData = await rootBundle.load('assets/sescoop.png');
    final List<int> imageBytes = imageData.buffer.asUint8List();

    // --- Busca os dados do Supabase ---
    debugPrint("Buscando dados do Supabase... $moduloId");
    final moduloResponse = await _client
        .from('modulos')
        .select('*, professores(nome), datas') // 'datas' é o seu array de timestamps
        .eq('id', moduloId)
        .single();
    // Converte para DateTime, normaliza para o início do dia, filtra pelo mês e ano, remove duplicatas e ordena
    final List<dynamic>? datasDoModuloRaw = moduloResponse['datas'] as List<dynamic>?;

    if (datasDoModuloRaw == null || datasDoModuloRaw.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF0A63AC),
                  title: Text('Atenção:',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 800 ? 20 : 15,
                      color: Colors.white,
                      fontFamily: 'LeagueSpartan',
                    ),),
                  content: Text('Não há datas de aula definidas para este módulo.',
                    style: TextStyle(
                      color: Colors.white,),
                    ),
                  actions: [
                    TextButton(
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // Remove o destaque ao passar o mouse
                      ),
                      child: const Text(
                        "Fechar",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }

    final Set<DateTime> datasUnicasNormalizadas = {};
    for (var dataStr in datasDoModuloRaw!) {
      if (dataStr is String) {
        try {
          final DateTime dateTimeCompleta = DateTime.parse(dataStr);
          // Normaliza para o início do dia (meia-noite) para ignorar o horário
          final DateTime dataNormalizada = DateTime(dateTimeCompleta.year, dateTimeCompleta.month, dateTimeCompleta.day);

          // Filtra pelo mês e ano desejados ANTES de adicionar ao Set
          if (dataNormalizada.month == mes && dataNormalizada.year == ano) {
            datasUnicasNormalizadas.add(dataNormalizada);
          }
        } catch (e) {
          debugPrint("Erro ao parsear data: $dataStr. Erro: $e");
          // Lide com o erro como preferir, talvez ignorando a data inválida
        }
      }
    }

    if (datasUnicasNormalizadas.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF0A63AC),
                  title: Text('Atenção:',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 800 ? 20 : 15,
                      color: Colors.white,
                      fontFamily: 'LeagueSpartan',
                    ),),
                  content: Text('Não há datas de aula definidas para este módulo no mês e ano especificados.',style: TextStyle(
                    color: Colors.white,),
                  ),
                  actions: [
                    TextButton(
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ), // Remove o destaque ao passar o mouse
                      ),
                      child: const Text(
                        "Fechar",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'LeagueSpartan',
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }

// Converte o Set de volta para uma List e ordena
    final List<DateTime> datasAula = datasUnicasNormalizadas.toList()
      ..sort((a, b) => a.compareTo(b)); // mantém em ordem cronológica

    debugPrint("Datas de aula únicas para o relatório ($mes/$ano): $datasAula");

    final alunosResponse = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .eq('turma_id', turmaId)
        .order('nome', ascending: true);
    final List<Map<String, dynamic>> alunos =
    List<Map<String, dynamic>>.from(alunosResponse);

    // O campo 'presente' no banco de dados precisaria ser um texto ('P', 'F', 'A', 'D') em vez de booleano.
    final presencasResponse = await _client
        .from('presencas')
        .select('jovem_id, data, presente')
        .eq('modulo_id', moduloId);
    debugPrint("Dados do Supabase obtidos com sucesso.");

    // --- Processa os dados ---
    final presencasMap = <String, Map<String, bool>>{};
    for (var presenca in presencasResponse) {
      final alunoId = presenca['jovem_id'];
      final data = presenca['data'];
      final presente = presenca['presente'];
      if (!presencasMap.containsKey(alunoId)) {
        presencasMap[alunoId] = {};
      }
      presencasMap[alunoId]![data] = presente;
    }

    // --- Cria e preenche o arquivo Excel com Syncfusion XlsIO ---
    debugPrint("Criando arquivo Excel com Syncfusion...");
    await initializeDateFormatting('pt_BR', null);
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Frequência';

    // --- ESTILOS ---
    final Style borderStyle = workbook.styles.add('BorderStyle');
    borderStyle.borders.all.lineStyle = LineStyle.thin;
    borderStyle.borders.all.colorRgb = ui.Color.fromARGB(255, 0, 0, 0);
    borderStyle.vAlign = VAlignType.center;

    final Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;
    headerStyle.borders.all.lineStyle = LineStyle.thin;
    headerStyle.borders.all.colorRgb = ui.Color.fromARGB(255, 0, 0, 0);

    final Style grayTitleStyle = workbook.styles.add('GrayTitleStyle');
    grayTitleStyle.backColorRgb = ui.Color.fromARGB(255, 211, 211, 211); // Cinza
    grayTitleStyle.bold = true;
    grayTitleStyle.fontSize = 14;
    grayTitleStyle.hAlign = HAlignType.center;
    grayTitleStyle.vAlign = VAlignType.center;
    grayTitleStyle.borders.all.lineStyle = LineStyle.thin;
    grayTitleStyle.borders.all.colorRgb = ui.Color.fromARGB(255, 0, 0, 0);

    final Style infoStyle = workbook.styles.add('InfoStyle');
    infoStyle.borders.all.lineStyle = LineStyle.thin;
    infoStyle.vAlign = VAlignType.center;

    final Style percentStyle = workbook.styles.add('PercentStyle');
    percentStyle.numberFormat = '0%';
    percentStyle.borders.all.lineStyle = LineStyle.thin;
    percentStyle.vAlign = VAlignType.center;
    percentStyle.hAlign = HAlignType.center;

    // Estilos para a legenda
    final Style legendPStyle = workbook.styles.add('LegendP');
    legendPStyle.backColorRgb = ui.Color.fromARGB(255, 198, 239, 206);
    legendPStyle.borders.all.lineStyle = LineStyle.thin;

    final Style legendFStyle = workbook.styles.add('LegendF');
    legendFStyle.backColorRgb = ui.Color.fromARGB(255, 255, 199, 206);
    legendFStyle.borders.all.lineStyle = LineStyle.thin;

    final Style legendAStyle = workbook.styles.add('LegendA'); // Atestado (Amarelo)
    legendAStyle.backColorRgb = ui.Color.fromARGB(255, 255, 255, 0);
    legendAStyle.borders.all.lineStyle = LineStyle.thin;

    final Style legendDStyle = workbook.styles.add('LegendD'); // Desligado (Laranja)
    legendDStyle.backColorRgb = ui.Color.fromARGB(255, 251, 213, 181);
    legendDStyle.borders.all.lineStyle = LineStyle.thin;



    // --- CABEÇALHO SUPERIOR ---
    const int labelCol1 = 3;
    const int valueCol1Start = 4;
    const int valueCol1End = 15;
    const int labelCol2Start = 16;
    const int labelCol2End = 17;
    const int valueCol2Start = 18; // Coluna R
    const int valueCol2End = 19;   // Coluna S
    final int nAulasCol = 4 + datasAula.length;
    final int freqBlockStartCol = nAulasCol + 2;
    final int lastDateCol = freqBlockStartCol + 5;
    final int lastHeaderCol = valueCol2End;
    final int lastColIndex = lastDateCol > lastHeaderCol ? lastDateCol : lastHeaderCol;


    Style presensaStyle = workbook.styles.add('style');
    presensaStyle.fontColor = '#C67878';
    presensaStyle.bold = true;

    // Linha 1: Título
    sheet.getRangeByIndex(1, 1, 1, lastColIndex).merge();
    sheet.getRangeByName('A1').setText('Controle de Frequência - Programa Jovem Aprendiz');
    sheet.getRangeByName('A1').cellStyle = grayTitleStyle;

    // Linhas 2-4: Logo e Informações
    sheet.getRangeByName('A2:B4').merge();
    final Picture picture = sheet.pictures.addStream(2, 1, imageBytes);
    picture.height = 60;
    picture.width = 120;

    sheet.getRangeByIndex(2, labelCol1).setText('Instituição Formador:');
    sheet.getRangeByIndex(2, valueCol1Start, 2, valueCol1End).merge();
    sheet.getRangeByIndex(2, valueCol1Start).setText(instituicao);
    sheet.getRangeByIndex(2, labelCol2Start, 2, labelCol2End).merge();
    sheet.getRangeByIndex(2, labelCol2Start).setText('Local/Sala:');
    sheet.getRangeByIndex(2, valueCol2Start, 2, valueCol2End).merge();
    sheet.getRangeByIndex(2, valueCol2Start).setText(localSala);

    sheet.getRangeByIndex(3, labelCol1).setText('Projeto:');
    sheet.getRangeByIndex(3, valueCol1Start, 3, valueCol1End).merge();
    sheet.getRangeByIndex(3, valueCol1Start).setText(projeto);
    sheet.getRangeByIndex(3, labelCol2Start, 3, labelCol2End).merge();
    sheet.getRangeByIndex(3, labelCol2Start).setText('Carga Horária:');
    sheet.getRangeByIndex(3, valueCol2Start, 3, valueCol2End).merge();
    sheet.getRangeByIndex(3, valueCol2Start).setText(cargaHoraria);

    sheet.getRangeByIndex(4, labelCol1).setText('Módulo:');
    sheet.getRangeByIndex(4, valueCol1Start, 4, valueCol1End).merge();
    sheet.getRangeByIndex(4, valueCol1Start).setText(moduloNome);
    sheet.getRangeByIndex(4, labelCol2Start, 4, labelCol2End).merge();
    sheet.getRangeByIndex(4, labelCol2Start).setText('Horário:');
    sheet.getRangeByIndex(4, valueCol2Start, 4, valueCol2End).merge();
    sheet.getRangeByIndex(4, valueCol2Start).setText(horario);

    sheet.getRangeByName('A2:${String.fromCharCode(64 + lastColIndex)}4').cellStyle = infoStyle;

    // --- CABEÇALHO DA TABELA ---
    final monthName = DateFormat.MMMM('pt_BR').format(DateTime(ano, mes!)).toUpperCase();

    // Linha 5
    sheet.getRangeByName('A5').setText('Nº');
    sheet.getRangeByName('B5').setText('Nome do Aluno');
    sheet.getRangeByName('C5').setText('Mês:');
    sheet.getRangeByIndex(5, 4, 5, nAulasCol - 1).merge();
    sheet.getRangeByName('D5').setText(monthName);
    sheet.getRangeByIndex(5, nAulasCol).setText('Nº Aulas:');
    sheet.getRangeByIndex(5, nAulasCol + 1).setNumber(datasAula.length.toDouble());
    sheet.getRangeByIndex(5, freqBlockStartCol, 5, freqBlockStartCol + 5).merge();
    sheet.getRangeByIndex(5, freqBlockStartCol).setText('FREQUÊNCIA');

    // Linha 6
    sheet.getRangeByName('C6').setText('Dia');
    for (int i = 0; i < datasAula.length; i++) {
      sheet.getRangeByIndex(6, 4 + i).setText(DateFormat('dd').format(datasAula[i]));
    }
    sheet.getRangeByIndex(6, freqBlockStartCol).setText('P');
    sheet.getRangeByIndex(6, freqBlockStartCol + 1).setText('A');
    sheet.getRangeByIndex(6, freqBlockStartCol + 2).setText('F');
    sheet.getRangeByIndex(6, freqBlockStartCol + 3).setText('%');
    sheet.getRangeByIndex(6, freqBlockStartCol + 4, 6, freqBlockStartCol + 5).merge();
    sheet.getRangeByIndex(6, freqBlockStartCol + 4).setText('ASSINATURA');

    sheet.getRangeByName('A5:${String.fromCharCode(64 + lastColIndex)}6').cellStyle = headerStyle;


    // --- DADOS DOS ALUNOS ---
    for (int i = 0; i < alunos.length; i++) {
      final aluno = alunos[i];
      final int currentRow = 7 + i;
      int totalPresentes = 0;
      int totalAtestados = 0;

      sheet.getRangeByIndex(currentRow, 1).setNumber(i + 1);
      sheet.getRangeByIndex(currentRow, 2).setText(aluno['nome']);

// ALTERAÇÃO SUGERIDA
      for (int j = 0; j < datasAula.length; j++) {
        final dataFormatada = DateFormat('yyyy-MM-dd').format(datasAula[j]);
        final Range cell = sheet.getRangeByIndex(currentRow, 4 + j);

        final Object? statusPresencaRaw = presencasMap[aluno['id']]?[dataFormatada];
        String statusPresenca;

        if (statusPresencaRaw is String) {
          statusPresenca = statusPresencaRaw;
        } else if (statusPresencaRaw is bool) {
          statusPresenca = statusPresencaRaw ? 'P' : 'F';
        } else {
          statusPresenca = 'F';
        }

        // 1. Define o texto da célula
        cell.setText(statusPresenca);

        // 2. ADICIONE ESTA LÓGICA PARA APLICAR O ESTILO
        switch (statusPresenca) {
          case 'P':
            cell.cellStyle = legendPStyle; // Aplica o estilo de presença (verde)
            break;
          case 'F':
            cell.cellStyle = legendFStyle; // Aplica o estilo de falta (vermelho)
            break;
          case 'A':
            cell.cellStyle = legendAStyle; // Exemplo para Atestado
            break;
          case 'D':
            cell.cellStyle = legendDStyle; // Exemplo para Desligado
            break;
          default:
          // Aplica um estilo padrão caso não seja nenhum dos acima
            cell.cellStyle = borderStyle;
            break;
        }
      }

      int totalFaltas = datasAula.length - totalPresentes - totalAtestados;
      double frequencia = datasAula.isEmpty ? 0 : (totalPresentes / datasAula.length);

      sheet.getRangeByIndex(currentRow, freqBlockStartCol).setNumber(totalPresentes.toDouble());
      sheet.getRangeByIndex(currentRow, freqBlockStartCol + 1).setNumber(totalAtestados.toDouble());
      sheet.getRangeByIndex(currentRow, freqBlockStartCol + 2).setNumber(totalFaltas.toDouble());

      final Range percentCell = sheet.getRangeByIndex(currentRow, freqBlockStartCol + 3);
      percentCell.setNumber(frequencia);
      percentCell.cellStyle = percentStyle;

      sheet.getRangeByIndex(currentRow, freqBlockStartCol + 4, currentRow, freqBlockStartCol + 5).merge();

      // Aplica a borda em toda a linha do aluno, garantindo que a última coluna seja coberta
      sheet.getRangeByName('A$currentRow:${String.fromCharCode(64 + lastColIndex)}$currentRow').cellStyle = borderStyle;
    }

    // --- RODAPÉ ---
    int footerRowStart = 7 + alunos.length + 2;
    // --- Célula de texto informativo ---
    final Range footerInfoCell = sheet.getRangeByIndex(footerRowStart, 1, footerRowStart, lastColIndex);
    footerInfoCell.merge();
    footerInfoCell.setText("Os dados deste documento são necessários para confirmação de presença, prestação de contas para utilização de recurso do SESCOOP e Certificação no Programa de Aprendizagem por parte da Instituição Formadora.");
    footerInfoCell.cellStyle = borderStyle;
    footerInfoCell.cellStyle.fontSize = 10;
    footerInfoCell.cellStyle.wrapText = true;


// --- Bloco de Coordenação, Observações e Legenda ---
    int coordRow = footerRowStart + 2;

    // NOVO: Estilo dedicado para os blocos de texto do rodapé
    final Style blockTextStyle = workbook.styles.add('BlockTextStyle');
    blockTextStyle.borders.all.lineStyle = LineStyle.thin;
    blockTextStyle.borders.all.colorRgb = ui.Color.fromARGB(255, 0, 0, 0);
    blockTextStyle.vAlign = VAlignType.top;
    blockTextStyle.hAlign = HAlignType.left;
    blockTextStyle.wrapText = true;

// Bloco "Coordenação Pedagógica"
    final Range coordCell = sheet.getRangeByIndex(coordRow, 1, coordRow + 4, 8);
    coordCell.merge();
    coordCell.setText('Coordenação Pedagógica\n\nDeclaro que as informações estão de\nacordo com o plano de eventos do GDH.');
    coordCell.cellStyle = blockTextStyle; // Aplicando o novo estilo correto

// Bloco "Observações"
    final Range obsCell = sheet.getRangeByIndex(coordRow, 9, coordRow + 4, 17);
    obsCell.merge();
    obsCell.setText('Observações:');
    obsCell.cellStyle = borderStyle; // 'borderStyle' já inclui a borda
    obsCell.cellStyle.vAlign = VAlignType.top;

// Título "LEGENDA"
    int legendCol = 18;
    final Range legendTitleCell = sheet.getRangeByIndex(coordRow, legendCol, coordRow, legendCol + 1);
    legendTitleCell.merge();
    legendTitleCell.setText('LEGENDA');
    legendTitleCell.cellStyle = headerStyle;

// Itens da Legenda
    sheet.getRangeByIndex(coordRow + 1, legendCol).setText('P');
    sheet.getRangeByIndex(coordRow + 1, legendCol).cellStyle = borderStyle;
    sheet.getRangeByIndex(coordRow + 1, legendCol + 1).setText('Presença');
    sheet.getRangeByIndex(coordRow + 1, legendCol + 1).cellStyle = borderStyle;

    sheet.getRangeByIndex(coordRow + 2, legendCol).setText('F');
    sheet.getRangeByIndex(coordRow + 2, legendCol).cellStyle = borderStyle;
    sheet.getRangeByIndex(coordRow + 2, legendCol + 1).setText('Falta');
    sheet.getRangeByIndex(coordRow + 2, legendCol + 1).cellStyle = borderStyle;

    sheet.getRangeByIndex(coordRow + 3, legendCol).setText('A');
    sheet.getRangeByIndex(coordRow + 3, legendCol).cellStyle = borderStyle;
    sheet.getRangeByIndex(coordRow + 3, legendCol + 1).setText('Atestado');
    sheet.getRangeByIndex(coordRow + 3, legendCol + 1).cellStyle = borderStyle;

    sheet.getRangeByIndex(coordRow + 4, legendCol).setText('D');
    sheet.getRangeByIndex(coordRow + 4, legendCol).cellStyle = borderStyle;
    sheet.getRangeByIndex(coordRow + 4, legendCol + 1).setText('Desligado');
    sheet.getRangeByIndex(coordRow + 4, legendCol + 1).cellStyle = borderStyle;


    // --- AJUSTE FINAL DAS COLUNAS ---
    sheet.autoFitColumn(1);
    sheet.setColumnWidthInPixels(2, 300);
    sheet.autoFitColumn(3);
    for(int i=0; i < datasAula.length; i++){
      sheet.setColumnWidthInPixels(4 + i, 30);
    }
    sheet.autoFitColumn(nAulasCol);
    sheet.autoFitColumn(nAulasCol + 1);
    sheet.setColumnWidthInPixels(freqBlockStartCol + 4, 150);

    // --- SALVAR E COMPARTILHAR ---
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final fileName = 'Frequencia_${codigoTurma}_${moduloNome.replaceAll(RegExp(r'[/\s]'), '_')}.xlsx';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/xlsx');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..setAttribute("download", "Relatorio_Jovens.xlsx");
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(filePath)],
        text: 'Confira o relatório de jovens em anexo.',
        subject: 'Relatório de Jovens',
      ));
    }

    debugPrint("Processo de geração de relatório finalizado.");
  }
}