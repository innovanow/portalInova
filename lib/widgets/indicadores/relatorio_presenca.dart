import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RelatorioService {
  static final _client = Supabase.instance.client;

  /// Gera um relatório de frequência em Excel e o disponibiliza para download (Web) ou compartilhamento (Mobile).
  static Future<void> gerarRelatorioPresenca({
    required BuildContext context,
    required String moduloId,
    required String turmaId,
    required String moduloNome,
    required String codigoTurma,
  }) async {
    // O bloco try/catch foi movido para a tela (historico_chamada)
    // para garantir que o CircularProgressIndicator seja sempre fechado.

    // Permissões só são necessárias no mobile.
    if (!kIsWeb && Platform.isAndroid) {
      debugPrint("Verificando permissões de armazenamento...");
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Permissão de armazenamento negada.');
        }
      }
    }

    // 1. Busca os dados (comum para todas as plataformas)
    debugPrint("Buscando dados do Supabase...");
    final moduloResponse = await _client
        .from('modulos')
        .select('*, professores(nome), datas')
        .eq('id', moduloId)
        .single();

    final professorNome = moduloResponse['professores']?['nome'] ?? 'Não informado';
    final List<DateTime> datasAula = (moduloResponse['datas'] as List<dynamic>?)
        !.map((dataStr) => DateTime.parse(dataStr as String))
        .toList()
      ..sort();

    if (datasAula.isEmpty) {
      throw Exception('Não há datas de aula definidas para este módulo.');
    }

    final alunosResponse = await _client
        .from('jovens_aprendizes')
        .select('id, nome')
        .eq('turma_id', turmaId)
        .order('nome', ascending: true);
    final List<Map<String, dynamic>> alunos =
    List<Map<String, dynamic>>.from(alunosResponse);

    final presencasResponse = await _client
        .from('presencas')
        .select('jovem_id, data, presente')
        .eq('modulo_id', moduloId);

    debugPrint("Dados do Supabase obtidos com sucesso.");

    // 2. Processa os dados
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

    // 3. Cria o arquivo Excel
    debugPrint("Criando arquivo Excel...");
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Frequência'];
    excel.setDefaultSheet('Frequência');

    // --- Preenchimento do Excel (mantendo seus ajustes) ---
    sheetObject.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("F1"));
    var cellA1 = sheetObject.cell(CellIndex.indexByString("A1"));
    cellA1.value = TextCellValue("Controle de Frequência - Programa Jovem Aprendiz");

    var cellA3 = sheetObject.cell(CellIndex.indexByString("A3"));
    cellA3.value = TextCellValue("Módulo:");
    var cellB3 = sheetObject.cell(CellIndex.indexByString("B3"));
    cellB3.value = TextCellValue(moduloNome);

    var cellA4 = sheetObject.cell(CellIndex.indexByString("A4"));
    cellA4.value = TextCellValue("Turma:");
    var cellB4 = sheetObject.cell(CellIndex.indexByString("B4"));
    cellB4.value = TextCellValue(codigoTurma);

    var cellA5 = sheetObject.cell(CellIndex.indexByString("A5"));
    cellA5.value = TextCellValue("Professor:");
    var cellB5 = sheetObject.cell(CellIndex.indexByString("B5"));
    cellB5.value = TextCellValue(professorNome);

    int headerRow = 7;
    var cellHdrNum = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow));
    cellHdrNum.value = TextCellValue("Nº");
    var cellHdrNome = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow));
    cellHdrNome.value = TextCellValue("Nome do Aluno");

    for (int i = 0; i < datasAula.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2 + i, rowIndex: headerRow));
      cell.value = TextCellValue(DateFormat('dd/MM').format(datasAula[i]));
    }
    int totalColStart = 2 + datasAula.length;
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart, rowIndex: headerRow)).value = TextCellValue("P");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart + 1, rowIndex: headerRow)).value = TextCellValue("F");
    sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart + 2, rowIndex: headerRow)).value = TextCellValue("%");

    for (int i = 0; i < alunos.length; i++) {
      final aluno = alunos[i];
      final alunoId = aluno['id'];
      final alunoNome = aluno['nome'];
      int currentRow = headerRow + 1 + i;
      int totalPresentes = 0;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = IntCellValue(i + 1);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(alunoNome);
      for (int j = 0; j < datasAula.length; j++) {
        final dataFormatada = DateFormat('yyyy-MM-dd').format(datasAula[j]);
        final presente = presencasMap[alunoId]?[dataFormatada] ?? false;
        if (presente) totalPresentes++;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2 + j, rowIndex: currentRow)).value = TextCellValue(presente ? 'P' : 'F');
      }
      int totalFaltas = datasAula.length - totalPresentes;
      double frequencia = datasAula.isEmpty ? 0 : (totalPresentes / datasAula.length) * 100;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart, rowIndex: currentRow)).value = IntCellValue(totalPresentes);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart + 1, rowIndex: currentRow)).value = IntCellValue(totalFaltas);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: totalColStart + 2, rowIndex: currentRow)).value = TextCellValue("${frequencia.toStringAsFixed(0)}%");
    }

    for (var i = 0; i < totalColStart + 3; i++) {
      sheetObject.setColumnAutoFit(i);
    }

    // 4. Salva e disponibiliza o arquivo de acordo com a plataforma
    final fileName = 'Frequencia_${codigoTurma}_${moduloNome.replaceAll(RegExp(r'[/\s]'), '_')}.xlsx';

    if (kIsWeb) {
      // Na Web, o próprio método save() com fileName inicia o download.
      debugPrint("Iniciando download na Web...");
      excel.save(fileName: fileName);
    } else {
      // No Mobile, obtemos os bytes para salvar e compartilhar.
      final fileBytes = excel.save();
      if (fileBytes != null) {
        debugPrint("Compartilhando arquivo no Mobile...");
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await SharePlus.instance.share(ShareParams(
          files: [XFile(filePath)],
          text: 'Confira o relatório de jovens em anexo.',
          subject: 'Relatório de Jovens',
        ));
        debugPrint("Compartilhamento no Mobile iniciado.");
      } else {
        throw Exception('Não foi possível salvar o arquivo Excel no mobile.');
      }
    }
    debugPrint("Processo de geração de relatório finalizado.");
  }
}
