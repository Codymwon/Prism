import 'dart:io';
import '../vault_storage.dart';

class LocalVaultStorage implements VaultStorage {
  @override
  Future<String> readContent(String relativePath) {
    return File(relativePath).readAsString();
  }

  @override
  Future<void> writeContent(String relativePath, String content) {
    return File(relativePath).writeAsString(content);
  }

  @override
  Future<void> deleteContent(String relativePath) async {
    final file = File(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<bool> exists(String relativePath) {
    return File(relativePath).exists();
  }

  @override
  Future<List<String>> listDocumentIdentifiers(String vaultPath) async {
    final dir = Directory(vaultPath);
    if (!await dir.exists()) return [];
    
    final list = await dir.list().toList();
    return list
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .map((f) => f.path)
        .toList();
  }

  @override
  Future<DateTime> getLastModified(String relativePath) {
    return File(relativePath).lastModified();
  }
}
