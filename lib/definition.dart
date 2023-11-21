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
    Map<String, TextEditingController> paramValueControllers = {
      for (String param in definitions[definitionIdx].params.keys)
        param: TextEditingController()..text = (definitions[definitionIdx].params[param]!).toString()
    };
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // TextFields for each param in definitions[definitionIdx]
          for (String param in definitions[definitionIdx].params.keys)
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 70, // TODO: 输入框的宽度要想办法能动态
              child: TextField(
                controller: paramValueControllers[param],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.outlineVariant,
                  label: SizedBox(
                    width: 20, // TODO: 参数名的字体肯定要变大, 这个宽度现在刚刚好, 所以肯定要变大
                    child: Math.tex(param, textStyle: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8), // Set your desired radius
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                  onPressed: () {
                    // TODO: 这个按钮删掉, 用上面输入框的submit
                    for (String param in definitions[definitionIdx].params.keys) {
                      String value = paramValueControllers[param]!.text;
                      if (value.isNotEmpty) {
                        setDefParam(param, double.parse(value));
                      }
                    }
                    onCalcTermValue();
                  },
                  foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  label: Text(definitions[definitionIdx].desc))),
        ],
      ),
    );
  }
}
