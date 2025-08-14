import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _listenAuthChanges(); // ✅ Escuta alterações automáticas
  }

  final supabase = Supabase.instance.client;

  String? nomeUsuario;
  String? emailUsuario;
  String? tipoUsuario;
  String? idUsuario;

  void _listenAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;

      if (session != null) {
        if (kDebugMode) {
          print("🔐 Sessão ativa para ${session.user.email}");
        }
        if (kDebugMode) {
          print("⏳ Expira em: ${session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : 'desconhecido'}");
        }
        if (session.refreshToken != null) {
          if (kDebugMode) {
            print("🔑 Access Token: ${session.accessToken.substring(0, 10)}...");
          }
        }
        if (session.refreshToken != null) {
          if (kDebugMode) {
            print("🔁 Refresh Token: ${session.refreshToken?.substring(0, 10)}...");
          }
        }

        await _saveSession(session);
        await _carregarDadosUsuario();
      } else {
        if (kDebugMode) {
          print("🔒 Sessão encerrada");
        }
        await _clearSession();
      }
    });
  }

  Future<String?> signIn(String email, String password, bool lembrar) async {
    try {
      if (kDebugMode) print("➡️ Iniciando login com $email");
      final response = await supabase.auth.signInWithPassword(email: email, password: password);

      if (response.session != null) {
        if (kDebugMode) print("✅ Login realizado com sucesso");

        await _saveSession(response.session!);
        await _saveCredentials(email, password, lembrar);
        await _carregarDadosUsuario(); // 👈 carrega nome/email aqui também

        return null;
      }
      return "Erro desconhecido ao fazer login.";
    } catch (e) {
      if (kDebugMode) print("❌ Erro de login: $e");
      return e.toString();
    }
  }

  Future<void> clearCredentials() async {
    await _clearCredentials();
    if (kDebugMode) {
      print("🧹 Credenciais apagadas manualmente");
    }
  }

  Future<void> _carregarDadosUsuario() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final response = await supabase
          .from('users')
          .select('nome, email, tipo')
          .eq('id', user.id)
          .single();

      nomeUsuario = response['nome'] ?? 'Sem nome';
      emailUsuario = response['email'] ?? 'Sem e-mail';
      tipoUsuario = response['tipo'] ?? 'Sem tipo';
      idUsuario = user.id;

      if (kDebugMode) {
        print("👤 Nome: $nomeUsuario | 📧 Email: $emailUsuario | 🔑 Tipo: $tipoUsuario | ID: ${user.id}");
      }
    }
  }


  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _clearSession();
  }

  User? getCurrentUser() => supabase.auth.currentUser;

  Future<void> _saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = jsonEncode({
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
    });
    await prefs.setString('supabase_session', sessionJson);
  }

  Future<bool> restoreSessionAndLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSession = prefs.getString('supabase_session');

    if (savedSession != null) {
      final sessionData = jsonDecode(savedSession);
      final refreshToken = sessionData['refresh_token'];

      if (kDebugMode) {
        print("📥 Credenciais recuperadas: ${sessionData['access_token'] != null ? 'sim' : 'não'}");
      }

      if (refreshToken != null) {
        try {
          final response = await supabase.auth.setSession(refreshToken);
          if (response.session != null) {
            if (kDebugMode) {
              print("🔁 Sessão restaurada com sucesso!");
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print("⚠️ Erro ao restaurar sessão: $e");
          }
        }
      }
    }

    // Tentativa de login automático
    final credentials = await getSavedCredentials();
    if (credentials['email']!.isNotEmpty && credentials['password']!.isNotEmpty && true) {
      if (kDebugMode) {
        print("➡️ Tentando login automático com ${credentials['email']}");
      }
      final loginError = await signIn(credentials['email']!, credentials['password']!, true);
      return loginError == null;
    }

    return false;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('supabase_session');
  }

  Future<void> _saveCredentials(String email, String password, bool lembrar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
    await prefs.setBool('lembrar_dados', lembrar);
    if (kDebugMode) {
      print('💾 Credenciais salvas: $email / $password / $lembrar');
    }
  }


  Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email') ?? '';
    final password = prefs.getString('saved_password') ?? '';
    final lembrar = prefs.getBool('lembrar_dados') ?? false;
    if (kDebugMode) {
      print('📥 Credenciais recuperadas: $email / $password');
    }
    return {
      'email': email,
      'password': password,
      'lembrarDados': lembrar.toString(),
    };
  }


  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }
  /// Envia o código de recuperação de senha por e-mail (OTP manual)
  Future<String?> enviarCodigoDeRecuperacao(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
