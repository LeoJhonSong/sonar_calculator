import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'auto_submit_text_field.dart';
import 'list_tile_reveal.dart';

class Definition {
  String eqn;
  String desc;
  Map<String, double> params;
  double Function(Map<String, double> params) funcHandler;
  double Function(double result, Map<String, double> params) inv;
  Definition({required this.eqn, required this.desc, required this.params, required this.funcHandler, required this.inv});

  Definition.byParamNames({
    required this.eqn,
    required this.desc,
    required List<String> paramNames,
    required this.funcHandler,
    required this.inv,
  }) : params = {for (String paramName in paramNames) paramName: 0.0};

  double func() => funcHandler(params);
}

class DefinitionCard extends StatelessWidget {
  final Definition definition;
  final void Function(double value) onSetTermValue;
  const DefinitionCard({
    super.key,
    required this.definition,
    required this.onSetTermValue,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Column(
      children: [
        ListTileReveal(
          title: Text(definition.desc),
          subtitle: Scrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                definition.eqn,
                textScaleFactor: 1.2,
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
                for (MapEntry<String, double> paramEntry in definition.params.entries) ...[
                  Expanded(
                    child: DefParamTextField(
                      defParamName: paramEntry.key,
                      defParamValue: paramEntry.value,
                      fillColor: Theme.of(context).colorScheme.outlineVariant,
                      textColor: Theme.of(context).colorScheme.primary,
                      onSubmitted: (text) {
                        definition.params[paramEntry.key] = double.parse(text);
                        onSetTermValue(definition.func());
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
