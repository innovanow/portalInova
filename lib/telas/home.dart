import 'package:flutter/material.dart';
import 'package:inova/widgets/wave.dart';
import 'package:inova/telas/widgets.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
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
                        buildIcon(Icons.message_outlined),
                        buildNotificationIcon(Icons.mark_chat_unread, 1),
                        buildIcon(Icons.campaign),
                        buildIcon(Icons.notifications),
                        buildIcon(Icons.search),
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
                    height: 100,
                    width: 150,
                    child: Image.asset("assets/logo.png"),
                  ),
                  const Text(
                    'Usuário: João Victor',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            buildDrawerItem(Icons.business, "Cadastro de Empresa", context),
            buildDrawerItem(Icons.school, "Cadastro de Colégio", context),
            buildDrawerItem(Icons.groups, "Cadastro de Turma", context),
            buildDrawerItem(Icons.person, "Cadastro de Jovem", context),
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
    );
  }
}
