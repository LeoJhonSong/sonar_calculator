import 'package:flutter/material.dart';

import 'auto_submit_text_field.dart';
import 'definition.dart';

class InvalidatedWidget extends StatelessWidget {
  final bool invalidated;
  final Widget child;
  const InvalidatedWidget({super.key, required this.invalidated, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: invalidated ? SystemMouseCursors.forbidden : SystemMouseCursors.basic,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          invalidated ? Colors.grey : Colors.white,
          BlendMode.modulate,
        ),
        child: AbsorbPointer(
          absorbing: invalidated,
          child: child,
        ),
      ),
    );
  }
}

class Term {
  bool enabled = true;
  String name;
  double weight;
  List<Definition> definitions;
  double value = 0;
  Term({required this.name, required this.weight, required this.definitions});

  /// 根据当前项的值反解出所有定义公式中第一个参数的值
  void calcParam() {
    for (Definition definition in definitions) {
      String defFirstParamName = definition.params.keys.elementAt(0);
      definition.params[defFirstParamName] = definition.inv(value, definition.params);
    }
  }
}

class TermWidget extends StatelessWidget {
  final bool enabled;
  final String name;
  final double value;
  final List<Definition> definitions;
  final void Function(String name, double value) onSetValue;
  final void Function(String name) onSolve;
  final void Function(String name, double value) onSetTermByDef;
  const TermWidget({
    super.key,
    required this.enabled,
    required this.name,
    required this.value,
    required this.onSetValue,
    required this.onSolve,
    required this.definitions,
    required this.onSetTermByDef,
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

    return Flexible(
      child: SizedBox(
        width: 450, // TermWidget的最大宽度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  InvalidatedWidget(
                    invalidated: !enabled,
                    child: SizedBox(
                      width: textPainter.width * 16,
                      child: TermTextField(
                        termName: name,
                        termValue: value,
                        fillColor: Theme.of(context).colorScheme.outlineVariant,
                        onSubmitted: (text) => onSetValue(name, double.parse(text)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InvalidatedWidget(
                    invalidated: !enabled,
                    child: ElevatedButton(
                      onPressed: () => onSolve(name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(name,
                          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              )),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: InvalidatedWidget(
                  invalidated: !enabled,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    surfaceTintColor: Theme.of(context).colorScheme.surface,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ListTile.divideTiles(
                          context: context,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          tiles: [
                            for (Definition definition in definitions)
                              DefinitionCard(
                                definition: definition,
                                onSetTermValue: (value) => onSetTermByDef(name, value),
                              ),
                          ],
                        ).toList()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
