import 'dart:math';

import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  runApp(MaterialApp(
    title: '声呐方程计算器',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFC3C0FF),
        onPrimary: Color(0xFF221693),
        primaryContainer: Color(0xFF3A34A9),
        onPrimaryContainer: Color(0xFFE2DFFF),
        secondary: Color(0xFFBEC2FF),
        onSecondary: Color(0xFF1F2578),
        secondaryContainer: Color(0xFF373E90),
        onSecondaryContainer: Color(0xFFE0E0FF),
        tertiary: Color(0xFF57D6F6),
        onTertiary: Color(0xFF003641),
        tertiaryContainer: Color(0xFF004E5E),
        onTertiaryContainer: Color(0xFFB0ECFF),
        error: Color(0xFFFFB4AB),
        errorContainer: Color(0xFF93000A),
        onError: Color(0xFF690005),
        onErrorContainer: Color(0xFFFFDAD6),
        background: Color(0xFF001B3D),
        onBackground: Color(0xFFD6E3FF),
        surface: Color(0xFF001B3D),
        onSurface: Color(0xFFD6E3FF),
        surfaceVariant: Color(0xFF47464F),
        onSurfaceVariant: Color(0xFFC8C5D0),
        outline: Color(0xFF928F9A),
        onInverseSurface: Color(0xFF001B3D),
        inverseSurface: Color(0xFFD6E3FF),
        inversePrimary: Color(0xFF534FC2),
        shadow: Color(0xFF000000),
        surfaceTint: Color(0xFFC3C0FF),
        outlineVariant: Color(0xFF47464F),
        scrim: Color(0xFF000000),
      ),
      // TODO: 适配高分屏缩放
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
    final int maxParamLen = [for (Definition d in definitions) d.params.length].reduce((curr, next) => curr > next ? curr : next);

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  SizedBox(
                    width: textPainter.width * 8,
                    child: TextField(
                      controller: termValueController,
                      decoration: null,
                      onChanged: (value) {
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
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                    child: Text(name, style: Theme.of(context).textTheme.displayMedium),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < definitions.length; i++)
                  Card(
                    // TODO: 提取为单独的widget
                    child: ListTile(
                      horizontalTitleGap: 0,
                      leading: SizedBox(
                        width: textPainter.width * 8 * maxParamLen,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TextFields for each param in definitions[i]
                            for (int j = 0; j < definitions[i].params.keys.length; j++)
                              SizedBox(
                                width: textPainter.width * 8,
                                child: TextField(
                                  controller: paramValueControllers[i][j],
                                  decoration: InputDecoration(
                                    prefix: SizedBox(width: textPainter.width * 2.5, child: Math.tex(definitions[i].params.keys.elementAt(j))),
                                    border: InputBorder.none,
                                  ),
                                  // TODO: onChanged: ,
                                ),
                              )
                          ],
                        ),
                      ),
                      title: Tooltip(
                          message: definitions[i].desc,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ElevatedButton(
                                onPressed: () => 0,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  elevation: 3,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: FittedBox(fit: BoxFit.scaleDown, child: Math.tex(definitions[i].eqn, mathStyle: MathStyle.display)),
                                )),
                          )),
                    ),
                  ),
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
            paramNames: ['v', 'Sv'],
            func: (params) => params['Sv']! + 20 * log10(params['v']!),
            inv: (result, params) => pow(10, (result - params['Sv']!) / 20).toDouble())
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
            params: {'a1': 1.0, 'a2': 1.0},
            func: (params) => params['a1']! * params['a2']! / 4,
            inv: (result, params) => 4 * result / params['a2']!),
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
        color: Theme.of(context).colorScheme.background,
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
