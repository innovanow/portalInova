import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocService {
  final supabase = Supabase.instance.client;

  Future<String?> uploadDocumento(String userId, String nomeArquivo, Uint8List bytes) async {
    try {
      final path = "$userId/documentos/$nomeArquivo";

      await supabase.storage.from('fotosjovens').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return path;
    } catch (e) {
      return "Erro ao enviar: $e";
    }
  }

  Future<List<Map<String, dynamic>>> listarDocumentos(String userId) async {
    try {
      final List arquivos = await supabase.storage.from('fotosjovens').list(path: "$userId/documentos");

      return arquivos.map((e) => {
        "name": e.name,
        "path": "$userId/documentos/${e.name}"
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> gerarLinkTemporario(String path) async {
    try {
      return await supabase.storage.from('fotosjovens').createSignedUrl(path, 3600);
    } catch (e) {
      return null;
    }
  }

  Future<String?> excluirDocumento(String path) async {
    try {
      await Supabase.instance.client.storage.from('fotosjovens').remove([path]);
      return null; // null indica sucesso
    } catch (e) {
      return "Erro ao excluir: $e";
    }
  }
}