import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class CustomMacrosNotifier extends StateNotifier<List<CustomMacro>> {
  CustomMacrosNotifier() : super(_defaultMacros) {
    _load();
  }

  static final List<CustomMacro> _defaultMacros = [
    CustomMacro(label: 'Date', text: '{{date}}'),
    CustomMacro(label: 'Todo', text: '[ ] '),
    CustomMacro(label: 'Action', text: '#action '),
    CustomMacro(label: 'Summary', text: '## Summary\n\n'),
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('customMacros');
    if (saved != null) {
      try {
        state = saved
            .map((s) => CustomMacro.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Fallback to default
      }
    }
  }

  Future<void> setMacros(List<CustomMacro> macros) async {
    state = macros;
    final prefs = await SharedPreferences.getInstance();
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

final customMacrosProvider =
    StateNotifierProvider<CustomMacrosNotifier, List<CustomMacro>>((ref) {
  return CustomMacrosNotifier();
});
