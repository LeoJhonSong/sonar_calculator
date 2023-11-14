import 'dart:math';

import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'color_schemes.g.dart';
import 'definition.dart';
import 'term.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isPassive = true;
  Map<String, double> knownParams = {
    'f': 0,
    'c': 0,
    'B': 0,
    't': 0,
  };
  double alpha = 0;
  late Map<String, Term> _terms;

  _MyHomePageState() {
    double f2 = pow(knownParams['f']!, 2).toDouble();
    alpha = 1.0936 * ((0.1 * f2 / (1 + f2)) + (40 * f2 / (4100 + f2)) + 2.75e-4 * f2 + 0.003);
    _terms = {
      'SL': Term(name: 'SL', weight: 1.0, definitions: [
        Definition.byParamNames(
            eqn: r'S_v+20\lg v',
            desc: '由发射电压',
            paramNames: ['v', 'S_v'],
            func: (params) => params['S_v']! + 20 * log10(params['v']!),
            inv: (result, params) => pow(10, (result - params['S_v']!) / 20).toDouble())
      ]),
      'TL': Term(name: 'TL', weight: -2.0, definitions: [
        Definition.byParamNames(
            eqn: r'20\lg r+\alpha r',
            desc: '浅海传播损失',
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
            params: {'a_1': 1.0, 'a_2': 1.0},
            func: (params) => params['a_1']! * params['a_2']! / 4,
            inv: (result, params) => 4 * result / params['a_2']!),
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
            func: (params) => pow(params['A']! * knownParams['f']! / knownParams['c']!, 2).toDouble(),
            inv: (result, params) => pow(result, 0.5) * knownParams['c']! / knownParams['f']!),
      ]),
      'NL': Term(name: 'NL', weight: -1.0, definitions: [
        Definition.byParamNames(
            eqn: r'10\lg f^{-1.7}+6S+55+10\lg B',
            desc: '由海况',
            paramNames: ['S'],
            func: (params) => 10 * log10(pow(knownParams['f']!, -1.7)) + 6 * params['S']! + 55 + 10 * log10(knownParams['B']!),
            inv: (result, params) => ((result - 10 * log10(pow(knownParams['f']!, -1.7)) - 55 - 10 * log10(knownParams['B']!)) ~/ 6).toDouble())
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
            func: (params) => 20 * log10(pi * params['D']! * knownParams['f']! / knownParams['c']!),
            inv: (result, params) => pow(10, result / 20) * knownParams['c']! / knownParams['f']! / pi),
        Definition(
            eqn: r'10\lg\frac{4\pi S}{\lambda^2}',
            desc: '矩形活塞阵',
            params: {'S': 1.0},
            func: (params) => 10 * log10(4 * pi * params['S']! / pow(knownParams['f']! / knownParams['c']!, 2)),
            inv: (result, params) => pow(10, result / 10) * pow(knownParams['c']! / knownParams['f']!, 2) / 4 / pi),
      ]),
      'DT': Term(name: 'DT', weight: -1.0, definitions: [
        Definition(
            eqn: r'10\lg\frac{d}{2t}',
            desc: '互相关接收机',
            params: {'d': 1.0},
            func: (params) => 10 * log10(params['d']! / 2 / knownParams['t']!),
            inv: (result, params) => pow(10, result / 10) * 2 * knownParams['t']!),
        Definition(
            eqn: r'5\lg\frac{d B}{t}',
            desc: '平方律检测器',
            params: {'d': 1.0},
            func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!),
            inv: (result, params) => pow(10, result / 5) * knownParams['t']! / knownParams['B']!),
        Definition(
            eqn: r'5\lg\frac{d B}{t}+|5\lg\frac{T}{t}|',
            desc: '平滑滤波器',
            params: {'d': 1.0, 'T': 1.0},
            func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!) + (5 * log10(params['T']! / knownParams['t']!)).abs(),
            inv: (result, params) =>
                pow(10, (result - (5 * log10(params['T']! / knownParams['t']!)).abs()) / 5) * knownParams['t']! / knownParams['B']!)
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
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPassive ? '主动' : '被动',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Switch(
                    value: isPassive,
                    onChanged: (value) {
                      setState(() {
                        isPassive = value;
                      });
                    },
                  ),
                  // 设置f, c, B, t
                  for (String paramName in knownParams.keys)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: TextEditingController()..text = knownParams[paramName]!.toString(),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.outlineVariant,
                            label: Math.tex(paramName, textStyle: TextStyle(color: Theme.of(context).colorScheme.primary)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(8), // Set your desired radius
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                knownParams[paramName] = double.parse(value);
                              });
                            }
                          },
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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
