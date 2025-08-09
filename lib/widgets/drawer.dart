import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cadastros/register_empresa.dart';
import '../cadastros/register_escola.dart';
import '../cadastros/register_jovem.dart';
import '../cadastros/register_modulo.dart';
import '../cadastros/register_professor.dart';
import '../cadastros/register_turma.dart';
import '../services/auth_service.dart';
import '../telas/calendar.dart';
import '../telas/historico_freq_jovem.dart';
import '../telas/home.dart';
import '../telas/jovem.dart';
import '../telas/login.dart';
import '../telas/modulos_jovens.dart';
import '../telas/presenca.dart';

final auth = AuthService();


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
          if (title == "Cadastro de Jovem" || title == "Jovens") {
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
          if (title == "Histórico de Presenças") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HistoricoFrequenciaJovemPage(jovemId: auth.idUsuario.toString(),)));
          }
          if (title == "Meus Módulos") {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => TelaModulosDoJovem(jovemId: auth.idUsuario.toString(),)));
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
                  const SnackBar(
                      backgroundColor: Color(0xFF0A63AC),
                      content: Text("Perfil não encontrado para este usuário.",
                          style: TextStyle(
                            color: Colors.white,
                          ))
                  ),
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

class InovaDrawer extends StatelessWidget {
  final BuildContext context;

  const InovaDrawer({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                  width: 150,
                  child: SvgPicture.asset("assets/logoInova.svg"),
                ),
                Text(
                  'Usuário:\n${auth.nomeUsuario ?? "Carregando..."}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF0A63AC)),
                ),
                Text(
                  'Email: ${auth.emailUsuario ?? "Carregando..."}',
                  style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                ),
                Text(
                  'Perfil: ${auth.tipoUsuario?.replaceAll("jovem_aprendiz", "Jovem Aprendiz").replaceAll("escola", "Colégio").toUpperCase() ?? "Carregando..."}',
                  style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                ),
              ],
            ),
          ),
          buildDrawerItem(Icons.home, "Home", context),
          if (auth.tipoUsuario == "jovem_aprendiz")
            buildDrawerItem(Icons.person, "Meu Perfil", context),
          if (auth.tipoUsuario == "administrador") ...[
            buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
            buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
            buildDrawerItem(Icons.man, "Cadastro de Professor", context),
            buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
            buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
            buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
          ],
          if (auth.tipoUsuario == "professor" || auth.tipoUsuario == "escola" || auth.tipoUsuario == "empresa")
            buildDrawerItem(Icons.person, "Jovens", context),
          if (auth.tipoUsuario == "professor")
          buildDrawerItem(Icons.check_circle_outline, "Presenças", context),
          if (auth.tipoUsuario == "jovem_aprendiz")
          buildDrawerItem(Icons.event_available, "Histórico de Presenças", context),
          buildDrawerItem(Icons.calendar_month, "Calendário", context),
          if (auth.tipoUsuario == "jovem_aprendiz" || auth.tipoUsuario == "professor")
          buildDrawerItem(Icons.book, "Meus Módulos", context),
          buildDrawerItem(Icons.logout, "Sair", context),
        ],
      ),
    );
  }
}