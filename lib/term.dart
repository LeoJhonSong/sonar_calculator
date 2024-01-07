import 'package:flutter/material.dart';

import 'auto_submit_text_field.dart';
import 'definition.dart';

class Term {
  String name;

  double weight;
  List<Definition> definitions;
  double value;
  Term({required this.name, required this.weight, required this.definitions, this.value = 0});

  /// 根据当前项的值反解出所有定义公式中第一个参数的值
  void calcParam() {
    for (int i = 0; i < definitions.length; i++) {
      String defFirstParamName = definitions[i].params.keys.elementAt(0);
      definitions[i].params[defFirstParamName] = definitions[i].inv(value, definitions[i].params);
    }
  }

  /// 由指定的定义公式计算当前项的值
  void calcValue(int defIdx) {
    value = definitions[defIdx].func(definitions[defIdx].params);
  }
}

class TermWidget extends StatelessWidget {
  final String name;

  final double value;
  final List<Definition> definitions;
  final void Function(String name, double value) onSetValue;
  final void Function(String name) onSolve;
  final void Function(String name, int defInx) onSetTermByDefIdx;
  final void Function(String name, int defIdx, String paramName, double value) setDefParam;
  const TermWidget({
    super.key,
    required this.name,
    required this.value,
    required this.onSetValue,
    required this.onSolve,
    required this.definitions,
    required this.onSetTermByDefIdx,
    required this.setDefParam,
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
        width: 400, // TermWidget的最大宽度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  SizedBox(
                    width: textPainter.width * 16,
                    child: TermTextField(
                      termName: name,
                      termValue: value,
                      fillColor: Theme.of(context).colorScheme.outlineVariant,
                      onSubmitted: (text) => onSetValue(name, double.parse(text)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
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
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                          for (int defIdx = 0; defIdx < definitions.length; defIdx++)
                            DefinitionCard(
                              definitions: definitions,
                              definitionIdx: defIdx,
                              onCalcTermValue: () => onSetTermByDefIdx(name, defIdx),
                              setDefParam: (paramName, value) => setDefParam(name, defIdx, paramName, value),
                            ),
                        ],
                      ).toList()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
