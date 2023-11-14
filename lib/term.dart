import 'package:flutter/material.dart';

import 'definition.dart';

class Term {
  String name;

  double weight;
  List<Definition> definitions;
  double value;
  Term({required this.name, required this.weight, required this.definitions, this.value = 0});

  void calcParam(int defIdx) {
    String firstKey = definitions[defIdx].params.keys.elementAt(0);
    definitions[defIdx].params[firstKey] = definitions[defIdx].inv(value, definitions[defIdx].params);
  }

  void calcValue(int defIdx) {
    value = definitions[defIdx].func(definitions[defIdx].params);
  }
}

class TermWidget extends StatelessWidget {
  final String name;

  final double value;
  final List<Definition> definitions;
  final Function(String, double) onSetValue;
  final Function(String) onSolve;
  const TermWidget({
    required this.name,
    required this.value,
    required this.onSetValue,
    required this.onSolve,
    required this.definitions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: 用于给出文本宽度/高度, 也许有更好方式?
    final textPainter = TextPainter(
      text: TextSpan(text: '0', style: Theme.of(context).textTheme.bodyMedium),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final TextEditingController termValueController = TextEditingController();
    // Set the initial value.
    termValueController.text = value.toString();
    List<List<TextEditingController>> paramValueControllers = [
      for (Definition d in definitions) [for (String param in d.params.keys) TextEditingController()..text = (d.params[param]!).toString()]
    ];
    final int maxParamLen = [for (Definition d in definitions) d.params.length].reduce((current, next) => current > next ? current : next);

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  width: textPainter.width * 8,
                  child: TextField(
                    controller: termValueController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.outlineVariant,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(8), // Set your desired radius
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        onSetValue(name, double.parse(value));
                      }
                    },
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => onSolve(name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                  ),
                  child: Text(name,
                      style: Theme.of(context).textTheme.displayMedium!.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          )),
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Theme.of(context).colorScheme.surfaceVariant,
                surfaceTintColor: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < definitions.length; i++)
                      DefinitionCard(
                          textPainter: textPainter,
                          maxParamLen: maxParamLen,
                          definitions: definitions,
                          definitionIdx: i,
                          paramValueControllers: paramValueControllers),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
