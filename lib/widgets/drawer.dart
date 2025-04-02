import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inova/widgets/widgets.dart';
import '../services/auth_service.dart';

final auth = AuthService();

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
                  'Usuário: ${auth.nomeUsuario ?? "Carregando..."}',
                  style: const TextStyle(color: Color(0xFF0A63AC)),
                ),
                Text(
                  'Email: ${auth.emailUsuario ?? "Carregando..."}',
                  style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                ),
                Text(
                  'Perfil: ${auth.tipoUsuario?.toUpperCase() ?? "Carregando..."}',
                  style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                ),
              ],
            ),
          ),
          buildDrawerItem(Icons.home, "Home", context),
          if (auth.tipoUsuario == "administrador") ...[
            buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
            buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
            buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
            buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
            buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
            buildDrawerItem(Icons.man, "Cadastro de Professor", context),
          ],
          buildDrawerItem(Icons.calendar_month, "Calendário", context),
          buildDrawerItem(Icons.logout, "Sair", context),
        ],
      ),
    );
  }
}