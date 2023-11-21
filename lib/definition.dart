import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
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
    Map<String, TextEditingController> paramValueControllers = {
      for (String param in definitions[definitionIdx].params.keys)
        param: TextEditingController()..text = (definitions[definitionIdx].params[param]!).toString()
    };
    final scrollController = ScrollController();
    return Column(
      children: [
        ListTileReveal(
          title: Text(definitions[definitionIdx].desc),
          subtitle: Scrollbar(
            controller: scrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
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
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setDefParam(param, double.parse(value));
                        }
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
