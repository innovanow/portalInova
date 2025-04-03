import 'package:flutter/material.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/widgets/widgets.dart';
import '../widgets/drawer.dart';


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
                                'Portal Instituto Inova',
                                style: TextStyle(
                                  fontFamily: 'FuturaBold',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              /*const SizedBox(width: 20),
                              buildAppBarItem(
                                Icons.person,
                                'Lista de Aprendiz',
                              ),
                              buildAppBarItem(
                                Icons.chat_bubble_outline,
                                'Ocorrências',
                              ),
                              buildAppBarItem(Icons.history, 'Histórico'),*/
                            ],
                          ),
                        ),
                      ),

                      // 🔹 Parte fixa que empurra os ícones para o final da tela
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /*buildIcon(Icons.message_outlined, context: context, "Mensagens"),
                          buildNotificationIcon(Icons.mark_chat_unread, 1),
                          buildIcon(Icons.campaign, "Campanhas", context: context),
                          buildIcon(Icons.notifications, "Notificações", context: context),
                          buildIcon(Icons.search, "Pesquisar", context: context),*/
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
        drawer: InovaDrawer(context: context),
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
