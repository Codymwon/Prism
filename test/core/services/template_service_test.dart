import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/services/template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempVaultDir;
  late ProviderContainer container;
  late TemplateService service;

  setUp(() {
    tempVaultDir = Directory.systemTemp.createTempSync('prism_template_test');
    SharedPreferences.setMockInitialValues({
      'welcomeNotesSeeded_${tempVaultDir.path.hashCode}': true,
    });
    container = ProviderContainer(
      overrides: [
        activeVaultPathProvider.overrideWith((ref) => tempVaultDir.path),
      ],
    );
    service = container.read(templateServiceProvider);
  });

  tearDown(() {
    container.dispose();
    try {
      if (tempVaultDir.existsSync()) {
        tempVaultDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('TemplateService - ID helpers', () {
    test('isTemplateId detects prefixed IDs', () {
      expect(isTemplateId('template:Gratitude'), isTrue);
      expect(isTemplateId('123e4567-e89b-12d3-a456-426614174000'), isFalse);
      expect(isTemplateId(''), isFalse);
    });

    test('nameFromId strips the prefix', () {
      expect(service.nameFromId('template:Gratitude'), 'Gratitude');
    });
  });

  group('TemplateService - write/read/list/delete', () {
    test('writeTemplate creates a file under .prism/templates/ and returns Right', () async {
      const name = 'Gratitude';
      const content = '---\ntitle: "Gratitude"\n---\n\nWhat am I thankful for?';

      final res = await service.writeTemplate(name, content);

      expect(res.isRight(), isTrue);
      final file = File(p.join(tempVaultDir.path, '.prism', 'templates', 'gratitude.md'));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), content);
    });

    test('listTemplates returns names of all .md files in the templates dir', () async {
      await service.writeTemplate('Gratitude', 'a');
      await service.writeTemplate('Daily Review', 'b');

      final res = await service.listTemplates();

      expect(res.isRight(), isTrue);
      final names = res.getOrElse((_) => <String>[]);
      expect(names..sort(), ['daily-review', 'gratitude']);
    });

    test('listTemplates returns empty list when the dir does not exist yet', () async {
      final res = await service.listTemplates();
      expect(res.isRight(), isTrue);
      expect(res.getOrElse((_) => <String>[]), isEmpty);
    });

    test('readTemplate returns the file content', () async {
      await service.writeTemplate('Gratitude', '# Gratitude Log');
      final res = await service.readTemplate('Gratitude');

      expect(res.isRight(), isTrue);
      expect(res.getOrElse((_) => ''), '# Gratitude Log');
    });

    test('readTemplate returns Left(TemplateNotFoundFailure) for missing template', () async {
      final res = await service.readTemplate('DoesNotExist');

      expect(res.isLeft(), isTrue);
      res.fold(
        (f) => expect(f, isA<TemplateNotFoundFailure>()),
        (_) => fail('Expected a Left failure'),
      );
    });

    test('writeTemplate overwrites an existing template', () async {
      await service.writeTemplate('Gratitude', 'old');
      await service.writeTemplate('Gratitude', 'new');

      final res = await service.readTemplate('Gratitude');
      expect(res.getOrElse((_) => ''), 'new');
    });

    test('deleteTemplate removes the file', () async {
      await service.writeTemplate('Gratitude', 'x');
      expect((await service.exists('Gratitude')).getOrElse((_) => false), isTrue);

      await service.deleteTemplate('Gratitude');

      expect((await service.exists('Gratitude')).getOrElse((_) => true), isFalse);
    });

    test('deleteTemplate is idempotent for a missing template', () async {
      final res = await service.deleteTemplate('NeverExisted');
      expect(res.isRight(), isTrue);
    });

    test('exists returns Right(false) when the template file is absent', () async {
      final res = await service.exists('Nope');
      expect(res.isRight(), isTrue);
      expect(res.getOrElse((_) => true), isFalse);
    });
  });

  group('TemplateService - error type names', () {
    test('TemplateFailure subclasses stringify sensibly', () {
      expect(const TemplateNotFoundFailure('X').toString(), contains('TemplateNotFoundFailure'));
      expect(const TemplateIoFailure('disk full').message, 'disk full');
    });
  });
}
