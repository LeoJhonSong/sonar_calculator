import 'dart:math';

import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'color_schemes.g.dart';

void main() {
  runApp(MaterialApp(
    title: '声呐方程计算器',
    theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme
        // TODO: 适配高分屏缩放
        ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    ),
    home: const MyHomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

double log10(num x) => log(x) / ln10;

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
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      surfaceTintColor: Theme.of(context).colorScheme.outline,
      child: ListTile(
        minVerticalPadding: 15,
        horizontalTitleGap: 0, // 减小leading和title之间的间距
        leading: SizedBox(
          width: textPainter.width * 8 * maxParamLen,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                )
            ],
          ),
        ),
        title: Tooltip(
            preferBelow: false,
            message: definitions[definitionIdx].desc,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ElevatedButton(
                  onPressed: () => 0,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    elevation: 3,
                    foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Math.tex(definitions[definitionIdx].eqn,
                            mathStyle: MathStyle.display, textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                  )),
            )),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

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
        ],
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  double f = 0;
  double c = 0;
  double B = 0;
  double t = 0;
  double alpha = 0;
  late Map<String, Term> _terms;

  _MyHomePageState() {
    double f2 = pow(f, 2).toDouble();
    alpha = 1.0936 * ((0.1 * f2 / (1 + f2)) + (40 * f2 / (4100 + f2)) + 2.75e-4 * f2 + 0.003);
    _terms = {
      'SL': Term(name: 'SL', weight: 1.0, definitions: [
        Definition.byParamNames(
            eqn: r'S_v+20\lg v',
            desc: '',
            paramNames: ['v', r'S_v'],
            func: (params) => params[r'S_v']! + 20 * log10(params['v']!),
            inv: (result, params) => pow(10, (result - params[r'S_v']!) / 20).toDouble())
      ]),
      'TL': Term(name: 'TL', weight: -2.0, definitions: [
        Definition.byParamNames(
            eqn: r'20\lg r+\alpha r',
            desc: '',
            paramNames: ['r'],
            func: (params) => 20 * log10(params['r']!) + alpha * params['r']!,
            inv: (result, params) {
              // FIXME: 可能需要先try
              // see: https://github.com/albertodev01/equations/blob/fdc6ebe1049ca53bc5dbda307da7ce43944214d3/example/flutter_example/lib/routes/nonlinear_page/nonlinear_results.dart#L48
              final newton = Newton(function: '20*log(x)/log(10)+$alpha*x-$result', x0: 1.0);
              final solutions = newton.solve();
              return solutions.guesses.last;
            })
      ]),
      'TS': Term(name: 'TS', weight: 1.0, definitions: [
        Definition(
            eqn: r'\frac{a_1a_2}{4}',
            desc: '凸面',
            params: {r'a_1': 1.0, r'a_2': 1.0},
            func: (params) => params[r'a_1']! * params[r'a_2']! / 4,
            inv: (result, params) => 4 * result / params[r'a_2']!),
        Definition.byParamNames(
            eqn: r'\frac{a^2}{4}',
            desc: '大球',
            paramNames: ['a'],
            func: (params) => pow(params['a']!, 2) / 4,
            inv: (result, params) => pow(result * 4, 0.5).toDouble()),
        Definition.byParamNames(
            eqn: r'(\frac{A}{\lambda})^2',
            desc: '有限任意形状平板',
            paramNames: ['A'],
            func: (params) => pow(params['A']! * f / c, 2).toDouble(),
            inv: (result, params) => pow(result, 0.5) * c / f),
      ]),
      'NL': Term(name: 'NL', weight: -1.0, definitions: [
        Definition.byParamNames(
            eqn: r'10\lg f^{-1.7}+6S+55+10\lg B',
            desc: '根据海况',
            paramNames: ['S'],
            func: (params) => 10 * log10(pow(f, -1.7)) + 6 * params['S']! + 55 + 10 * log10(B),
            inv: (result, params) => ((result - 10 * log10(pow(f, -1.7)) - 55 - 10 * log10(B)) ~/ 6).toDouble())
      ]),
      'DI': Term(name: 'DI', weight: 1.0, definitions: [
        Definition(
            eqn: r'10\lg N',
            desc: '线列阵',
            params: {'N': 1.0},
            func: (params) => 10 * log10(params['N']!),
            inv: (result, params) => pow(10, result / 10).toDouble()),
        Definition(
            eqn: r'10\lg MN',
            desc: '点源方形阵',
            params: {'M': 1.0, 'N': 1.0},
            func: (params) => 10 * log10(params['M']! * params['N']!),
            inv: (result, params) => pow(10, result / 10) / params['N']!),
        Definition(
            eqn: r'20\lg\frac{\pi D}{\lambda}',
            desc: '圆形活塞阵',
            params: {'D': 1.0},
            func: (params) => 20 * log10(pi * params['D']! * f / c),
            inv: (result, params) => pow(10, result / 20) * c / f / pi),
        Definition(
            eqn: r'10\lg\frac{4\pi S}{\lambda^2}',
            desc: '矩形活塞阵',
            params: {'S': 1.0},
            func: (params) => 10 * log10(4 * pi * params['S']! / pow(f / c, 2)),
            inv: (result, params) => pow(10, result / 10) * pow(c / f, 2) / 4 / pi),
      ]),
      'DT': Term(name: 'DT', weight: -1.0, definitions: [
        Definition(
            eqn: r'10\lg\frac{d}{2t}',
            desc: '互相关接收机',
            params: {'d': 1.0},
            func: (params) => 10 * log10(params['d']! / 2 / t),
            inv: (result, params) => pow(10, result / 10) * 2 * t),
        Definition(
            eqn: r'5\lg\frac{d B}{t}',
            desc: '平方律检测器',
            params: {'d': 1.0},
            func: (params) => 5 * log10(params['d']! * B / t),
            inv: (result, params) => pow(10, result / 5) * t / B),
        Definition(
            eqn: r'5\lg\frac{d B}{t}+|5\lg\frac{T}{t}|',
            desc: '平滑滤波器',
            params: {'d': 1.0, 'T': 1.0},
            func: (params) => 5 * log10(params['d']! * B / t) + (5 * log10(params['T']! / t)).abs(),
            inv: (result, params) => pow(10, (result - (5 * log10(params['T']! / t)).abs()) / 5) * t / B)
      ]),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                '声呐方程计算器',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < _terms.length; i++)
                        TermWidget(
                          name: _terms.values.elementAt(i).name,
                          value: _terms.values.elementAt(i).value,
                          onSolve: _handleSolve,
                          onSetValue: _handleSetValue,
                          definitions: _terms.values.elementAt(i).definitions,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSetValue(String name, double value) {
    setState(() {
      _terms[name]!.value = value;
    });
  }

  void _handleSolve(String name) {
    setState(() {
      double sum = 0.0;
      for (var i = 0; i < _terms.length; i++) {
        if (_terms.keys.elementAt(i) != name) {
          sum = sum + _terms.values.elementAt(i).weight * _terms.values.elementAt(i).value;
        }
      }
      _terms[name]!.value = -sum / _terms[name]!.weight;
    });
  }
}
