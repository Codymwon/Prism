import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../onboarding/data/onboarding_provider.dart';

part 'custom_macro_provider.g.dart';

class CustomMacro {
  final String label;
  final String text;

  CustomMacro({required this.label, required this.text});

  factory CustomMacro.fromJson(Map<String, dynamic> json) {
    return CustomMacro(
      label: json['label'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'text': text,
  };
}

@riverpod
class CustomMacros extends _$CustomMacros {
  static final List<CustomMacro> _defaultMacros = [
    CustomMacro(label: 'Timestamp', text: '{{datetime}} - '),
    CustomMacro(label: 'Todo', text: '- [ ] '),
    CustomMacro(label: 'Important', text: '> [!IMPORTANT]\n> '),
    CustomMacro(label: 'Summary', text: '### Summary\n- '),
  ];

  @override
  List<CustomMacro> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList('customMacros');
    if (saved != null) {
      try {
        return saved
            .map((s) => CustomMacro.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return _defaultMacros;
  }

  Future<void> setMacros(List<CustomMacro> macros) async {
    state = macros;
    final prefs = ref.read(sharedPreferencesProvider);
    final list = macros.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('customMacros', list);
  }

  Future<void> updateMacro(int index, CustomMacro macro) async {
    if (index >= 0 && index < state.length) {
      final updated = List<CustomMacro>.from(state);
      updated[index] = macro;
      await setMacros(updated);
    }
  }

  Future<void> addMacro(CustomMacro macro) async {
    if (state.length < 5) {
      final updated = List<CustomMacro>.from(state)..add(macro);
      await setMacros(updated);
    }
  }

  Future<void> removeMacro(int index) async {
    if (state.length > 3 && index >= 0 && index < state.length) {
      final updated = List<CustomMacro>.from(state)..removeAt(index);
      await setMacros(updated);
    }
  }

  Future<void> resetToDefaults() async {
    await setMacros(_defaultMacros);
  }
}
