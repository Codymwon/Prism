import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/template_service.dart';
import 'note_model.dart';

class TemplateRepository {
  final TemplateService _templateService;

  TemplateRepository(this._templateService);

  bool isTemplate(String id) => isTemplateId(id);

  String nameFromId(String id) => _templateService.nameFromId(id);

  Future<Note> getTemplateNoteById(String id) async {
    final name = _templateService.nameFromId(id);
    return Note(
      id: id,
      title: name,
      filePath: '',
      wordCount: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<String> readTemplateContent(String id) async {
    final name = _templateService.nameFromId(id);
    final res = await _templateService.readTemplate(name);
    return res.fold(
      (f) => throw ArgumentError(f.message),
      (content) => content,
    );
  }

  Future<void> saveTemplate(String id, String content) async {
    final name = _templateService.nameFromId(id);
    final res = await _templateService.writeTemplate(name, content);
    res.fold(
      (f) => throw ArgumentError(f.message),
      (_) => null,
    );
  }

  Future<void> deleteTemplate(String id) async {
    final name = _templateService.nameFromId(id);
    final res = await _templateService.deleteTemplate(name);
    res.fold(
      (f) => throw ArgumentError(f.message),
      (_) => null,
    );
  }
}

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.read(templateServiceProvider));
});
