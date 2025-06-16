import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

Map<String, Color> gerarCoresRGB(Iterable<String> categorias) {
  final Map<String, Color> cores = {};
  final random = Random();

  for (final cat in categorias) {
    cores[cat] = Color.fromRGBO(
      random.nextInt(256), // Red: 0-255
      random.nextInt(256), // Green: 0-255
      random.nextInt(256), // Blue: 0-255
      1.0, // Opacidade total
    );
  }

  return cores;
}

class IndicadorPizza extends StatelessWidget {
  final String titulo;
  final Map<String, int> dados;
  final Map<String, Color>? cores;

  const IndicadorPizza({
    super.key,
    required this.titulo,
    required this.dados,
    this.cores,
  });

  @override
  Widget build(BuildContext context) {
    final total = dados.values.fold(0, (a, b) => a + b);
    final List<PieChartSectionData> sections = [];

    for (final entry in dados.entries) {
      final percentual = total > 0 ? entry.value / total : 0;
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${(percentual * 100).toStringAsFixed(0)}%',
          color: cores?[entry.key] ?? Colors.grey,
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return SizedBox(
      height: 415,
      width: 300,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.2,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 20,
                    children: dados.entries.map((entry) {
                      final cor = cores?[entry.key] ?? Colors.grey;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(width: 14, height: 14, color: cor),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text('${entry.key}: ${entry.value}',
                                      style: const TextStyle(fontSize: 10)),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
