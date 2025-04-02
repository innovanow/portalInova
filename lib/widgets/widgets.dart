import 'package:chips_choice/chips_choice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:inova/cadastros/register_empresa.dart';
import 'package:inova/cadastros/register_escola.dart';
import 'package:inova/cadastros/register_jovem.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cadastros/register_modulo.dart';
import '../cadastros/register_professor.dart';
import '../cadastros/register_turma.dart';
import '../services/auth_service.dart';
import '../telas/calendar.dart';
import '../telas/home.dart';
import '../telas/jovem.dart';
import '../telas/login.dart';
import '../telas/presenca.dart';

/// 📌 Função para criar um item do menu lateral
Widget buildDrawerItem(IconData icon, String title, BuildContext context) {
  return Tooltip(
    message: title == "Sair" ? "Sair da conta" : 'Abrir $title',
    child: MouseRegion(
      cursor: SystemMouseCursors.click, // 👈 Mãozinha na web
      child: ListTile(
        onTap: () async {
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
          if (title == "Calendário") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ModulosCalendarScreen()));
          }
          if (title == "Home") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Home()));
          }
          if (title == "Sair") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
          if (title == "Presenças") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => RegistrarPresencaPage(professorId: auth.idUsuario.toString(),)));
          }
          if (title == "Meu Perfil") {
            final response = await Supabase.instance.client
                .from('jovens_aprendizes')
                .select()
                .eq('id', auth.idUsuario.toString())
                .maybeSingle();

            if (response != null && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => JovemAprendizDetalhes(jovem: response),
                ),
              );
            } else {
              if (context.mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Perfil não encontrado para este usuário.")),
                );
              }
            }
          }
        },
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
        shape: const Border(bottom: BorderSide()), // 👈 Borda visual separadora
      ),
    ),
  );
}

Widget buildIcon(IconData icon, String? title, {BuildContext? context}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: IconButton(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      enableFeedback: false,
      tooltip: title,
      onPressed: () async {
        if (icon == Icons.logout) {
          final authService = AuthService();
          await authService.signOut();
          if (context!.mounted) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      },
      icon: Icon(icon, color: Colors.white),)
  );
}

Widget buildNotificationIcon(IconData icon, int count) {
  return Stack(
    children: [
      buildIcon(icon, null),
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

Color selectedColor = Colors.blue; // Cor inicial

class ColorWheelPicker extends StatefulWidget {
  final Function(Color) onColorSelected;

  const ColorWheelPicker({super.key, required this.onColorSelected});

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0A63AC),
          title: const Text("Selecione uma cor",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'FuturaBold',
            ),),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar",
              style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Selecionar",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                widget.onColorSelected(selectedColor);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showColorPickerDialog,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: selectedColor,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "Cor: 0x${selectedColor.toARGB32().toRadixString(16).toUpperCase()}",
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
