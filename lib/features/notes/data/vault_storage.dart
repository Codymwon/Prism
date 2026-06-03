abstract class VaultStorage {
  Future<String> readContent(String relativePath);
  Future<void> writeContent(String relativePath, String content);
  Future<void> deleteContent(String relativePath);
  Future<bool> exists(String relativePath);
  Future<List<String>> listDocumentIdentifiers(String vaultPath);
  Future<DateTime> getLastModified(String relativePath);
}
