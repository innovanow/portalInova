import 'package:chips_choice/chips_choice.dart';
import 'package:flutter/material.dart';
import 'package:inova/cadastros/register_empresa.dart';
import 'package:inova/cadastros/register_escola.dart';
import 'package:inova/cadastros/register_jovem.dart';
import '../cadastros/register_modulo.dart';
import '../cadastros/register_professor.dart';
import '../cadastros/register_turma.dart';

/// 📌 Função para criar um item do menu lateral
Widget buildDrawerItem(IconData icon, String title, BuildContext context) {
  return Tooltip(
    message: 'Abrir $title',
    child: InkWell(
      onTap: () {
        if (title == "Cadastro de Empresa") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const EmpresaScreen()));
        }
        if (title == "Cadastro de Colégio") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const EscolaScreen()));
        }
        if (title == "Cadastro de Jovem") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CadastroJovem()));
        }
        if (title == "Cadastro de Turma") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TurmaScreen()));
        }
        if (title == "Cadastro de Professor") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CadastroProfessor()));
        }
        if (title == "Cadastro de Módulo") {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ModuloScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide()),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            size: 30,
            color: const Color(0xFF0A63AC),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'FuturaBold',
              color: Color(0xFF0A63AC),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buildIcon(IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Icon(icon, size: 24, color: Colors.white,),
  );
}

Widget buildNotificationIcon(IconData icon, int count) {
  return Stack(
    children: [
      buildIcon(icon),
      Positioned(
        right: 5,
        top: 5,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildAppBarItem(IconData icon, String label) {
  return Row(
    children: [
      Icon(icon, size: 18, color: Colors.white),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      const SizedBox(width: 20),
    ],
  );
}

class MultiSelectChips extends StatefulWidget {
  final List<Map<String, dynamic>> modulos; // Lista de módulos vinda do banco
  final Function(List<String>) onSelecionado; // Callback para retorno dos selecionados
  final List<String> modulosSelecionados; // Valores já selecionados

  const MultiSelectChips({super.key, required this.modulos, required this.onSelecionado, required this.modulosSelecionados});

  @override
  State<MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<MultiSelectChips> {
  List<String> modulosSelecionados = []; // Lista de módulos selecionados
  List<String> _selecionados = []; // Lista para armazenar os módulos selecionados

  @override
  void initState() {
    super.initState();
    _selecionados = List<String>.from(widget.modulosSelecionados); // Preenche ao abrir
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Selecione os Módulos:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),

        // Verifica se os módulos já foram carregados
        widget.modulos.isEmpty
            ? const Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10),
              Text(
                "Carregando módulos...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
            : ChipsChoice<String>.multiple(
          value: _selecionados,
          onChanged: (val) {
            setState(() {
              _selecionados = val;
            });
            widget.onSelecionado(_selecionados);
          },
          choiceItems: C2Choice.listFrom<String, Map<String, dynamic>>(
            source: widget.modulos,
            value: (i, modulo) => modulo['id'].toString(),
            label: (i, modulo) => modulo['nome'],
          ),
          choiceCheckmark: true,
          choiceStyle: C2ChipStyle.filled(
            color: Colors.blueGrey,
            selectedStyle: const C2ChipStyle(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          wrapped: true,
        ),
      ],
    );
  }
}