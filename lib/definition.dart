import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

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
  final TextPainter textPainter;

  final int maxParamLen;
  final List<Definition> definitions;
  final int definitionIdx;
  final List<List<TextEditingController>> paramValueControllers;
  const DefinitionCard({
    super.key,
    required this.textPainter,
    required this.maxParamLen,
    required this.definitions,
    required this.definitionIdx,
    required this.paramValueControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // TextFields for each param in definitions[i]
          for (int j = 0; j < definitions[definitionIdx].params.keys.length; j++)
            Container(
              margin: EdgeInsets.only(right: textPainter.width * 0.8),
              width: textPainter.width * 7,
              child: TextField(
                controller: paramValueControllers[definitionIdx][j],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.outlineVariant,
                  label: SizedBox(
                      width: textPainter.width * 2.5,
                      child: Math.tex(definitions[definitionIdx].params.keys.elementAt(j),
                          textStyle: TextStyle(color: Theme.of(context).colorScheme.primary))),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8), // Set your desired radius
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                // TODO: onSubmitted: ,
              ),
            ),
          const Spacer(),
          JustTheTooltip(
              preferredDirection: AxisDirection.right,
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              content: Padding(
                padding: const EdgeInsets.all(10),
                child: Math.tex(definitions[definitionIdx].eqn, textStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer)),
              ),
              child: FloatingActionButton.extended(
                  onPressed: () => 0,
                  foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  label: Text(definitions[definitionIdx].desc))),
        ],
      ),
    );
  }
}
