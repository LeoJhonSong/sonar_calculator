import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'auto_submit_text_field.dart';
import 'list_tile_reveal.dart';

class Definition {
  String eqn;
  String desc;
  Map<String, double> params;
  double Function(Map<String, double> params) func;
  double Function(double result, Map<String, double> params) inv;
  Definition({required this.eqn, required this.desc, required this.params, required this.func, required this.inv});

  Definition.byParamNames({required this.eqn, required this.desc, required List<String> paramNames, required this.func, required this.inv})
      : params = {for (String paramName in paramNames) paramName: 0.0};
}

class DefinitionCard extends StatelessWidget {
  final List<Definition> definitions;
  final int definitionIdx;
  final void Function(String paramName, double value) setDefParam;
  final void Function() onCalcTermValue;
  const DefinitionCard({
    super.key,
    required this.definitions,
    required this.definitionIdx,
    required this.setDefParam,
    required this.onCalcTermValue,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Column(
      children: [
        ListTileReveal(
          title: Text(definitions[definitionIdx].desc),
          subtitle: Scrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                definitions[definitionIdx].eqn,
                textScaleFactor: 1.2, // TODO: 这个缩放比
                textStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: () {
              List<Widget> list = [
                for (String param in definitions[definitionIdx].params.keys) ...[
                  Expanded(
                    child: DefParamTextField(
                      defParamName: param,
                      defParamValue: definitions[definitionIdx].params[param]!,
                      fillColor: Theme.of(context).colorScheme.outlineVariant,
                      textColor: Theme.of(context).colorScheme.primary,
                      onSubmitted: (text) {
                        setDefParam(param, double.parse(text));
                        onCalcTermValue();
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ];
              return list.take(list.length - 1);
            }()
                .toList(),
          ),
        ),
      ],
    );
  }
}
