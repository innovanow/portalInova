import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/widgets/widgets.dart';
import 'package:inova/services/auth_service.dart';

final auth = AuthService();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {}); // força reconstrução após o login
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:false, // impede voltar
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            shape: const LinearBorder(),
            elevation: 0,
            backgroundColor: const Color(0xFF0A63AC),
            title: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🔹 Parte que rola horizontalmente
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text(
                                'Inova',
                                style: TextStyle(
                                  fontFamily: 'FuturaBold',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 20),
                              buildAppBarItem(
                                Icons.person,
                                'Lista de Aprendiz',
                              ),
                              buildAppBarItem(
                                Icons.chat_bubble_outline,
                                'Ocorrências',
                              ),
                              buildAppBarItem(Icons.history, 'Histórico'),
                            ],
                          ),
                        ),
                      ),

                      // 🔹 Parte fixa que empurra os ícones para o final da tela
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildIcon(Icons.message_outlined, context: context, "Mensagens"),
                          buildNotificationIcon(Icons.mark_chat_unread, 1),
                          buildIcon(Icons.campaign, "Campanhas", context: context),
                          buildIcon(Icons.notifications, "Notificações", context: context),
                          buildIcon(Icons.search, "Pesquisar", context: context),
                          buildIcon(Icons.logout, "Sair",  context: context),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inova',
                        style: TextStyle(
                          fontFamily: 'FuturaBold',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      buildIcon(Icons.logout, "Sair",  context: context),
                    ],
                  );
                }
              },
            ),
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
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.white,),
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
                      'Perfil: ${auth.tipoUsuario?.replaceAll("jovem_aprendiz", "Jovem Aprendiz").toUpperCase() ?? "Carregando..."}',
                      style: const TextStyle(color: Color(0xFF0A63AC), fontSize: 12),
                    ),
                  ],
                ),
              ),
              buildDrawerItem(Icons.home, "Home", context),
              if (auth.tipoUsuario == "jovem_aprendiz")
                buildDrawerItem(Icons.account_circle, "Meu Perfil", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.view_module, "Cadastro de Módulo", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
              if (auth.tipoUsuario == "administrador")
                buildDrawerItem(Icons.man, "Cadastro de Professor", context),
              buildDrawerItem(Icons.calendar_month, "Calendário", context),
              buildDrawerItem(Icons.logout, "Sair", context),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              opacity: 0.2,
              image: AssetImage("assets/fundo.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Onda Superior Laranja
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    height: 45,
                    color: Colors.orange
                  ),
                ),
              ),
              // Onda Superior Azul sobreposta
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: WaveClipper(heightFactor: 0.6),
                  child: Container(
                    height: 60,
                    color: const Color(0xFF0A63AC),
                  ),
                ),
              ),
              // Onda Inferior Laranja
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: WaveClipper(flip: true),
                  child: Container(
                    height: 60,
                    color: Colors.orange,
                  ),
                ),
              ),
              // Onda Inferior Azul sobreposta
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: WaveClipper(flip: true, heightFactor: 0.6),
                  child: Container(
                    height: 50,
                    color: const Color(0xFF0A63AC),
                  ),
                ),
              ),
              // Conteúdo Centralizado

            ],
          ),
        ),
      ),
    );
  }
}
