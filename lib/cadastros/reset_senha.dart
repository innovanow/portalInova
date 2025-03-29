import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificarTokenScreen extends StatefulWidget {
  const VerificarTokenScreen({super.key});

  @override
  State<VerificarTokenScreen> createState() => _VerificarTokenScreenState();
}

class _VerificarTokenScreenState extends State<VerificarTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  String? _mensagemErro;
  String? _mensagemSucesso;

  Future<void> _verificarEAtualizarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _mensagemErro = null;
      _mensagemSucesso = null;
    });

    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final novaSenha = _novaSenhaController.text;

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );

      if (response.session == null) {
        setState(() {
          _mensagemErro = 'Código inválido ou expirado.';
          _carregando = false;
        });
        return;
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: novaSenha),
      );

      setState(() {
        _mensagemSucesso = 'Senha atualizada com sucesso!';
      });
    } catch (e) {
      setState(() {
        _mensagemErro = 'Erro: ${e.toString()}';
      });
    }

    setState(() => _carregando = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validar Token e Redefinir Senha')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) =>
                value!.isEmpty ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Token recebido'),
                validator: (value) =>
                value!.isEmpty ? 'Informe o token' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _novaSenhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Confirmar nova senha'),
                validator: (value) =>
                value != _novaSenhaController.text
                    ? 'Senhas não coincidem'
                    : null,
              ),
              const SizedBox(height: 20),
              if (_mensagemErro != null)
                Text(_mensagemErro!, style: const TextStyle(color: Colors.red)),
              if (_mensagemSucesso != null)
                Text(_mensagemSucesso!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 20),
              _carregando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _verificarEAtualizarSenha,
                child: const Text('Atualizar Senha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
