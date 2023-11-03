import 'dart:math';

import 'package:equations/equations.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: '声呐方程计算器',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: const MyHomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

double log10(num x) => log(x) / ln10;

class Definition {
  String desc;
  Map<String, double> params;
  double Function(Map<String, double> params) func;
  double Function(double result, Map<String, double> params) inv;
  Definition({required this.desc, required this.params, required this.func, required this.inv});

  Definition.byParamNames({required this.desc, required List<String> paramNames, required this.func, required this.inv})
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
  final Function(String, double) onSetValue;
  final Function(String) onSolve;
  const TermWidget({
    required this.name,
    required this.value,
    required this.onSetValue,
    required this.onSolve,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: '请输入$name',
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                onSetValue(name, double.parse(value));
              }
            },
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () {
              onSolve(name);
            },
            child: const Text('求解'),
          ),
        ),
        Expanded(
          // TODO: 把数值合并到输入框
          child: Text(value.toString()),
        ),
      ],
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
            desc: 'S_v+20lgv',
            paramNames: ['v', 'Sv'],
            func: (params) => params['Sv']! + 20 * log10(params['v']!),
            inv: (result, params) => pow(10, (result - params['Sv']!) / 20).toDouble())
      ]),
      'TL': Term(name: 'TL', weight: -2.0, definitions: [
        Definition.byParamNames(
            desc: '20lgr+alpha*r',
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
            desc: '凸面: (a1*a2)/4',
            params: {'a1': 1.0, 'a2': 1.0},
            func: (params) => params['a1']! * params['a2']! / 4,
            inv: (result, params) => 4 * result / params['a2']!),
        Definition.byParamNames(
            desc: '大球: a^2/4',
            paramNames: ['a'],
            func: (params) => pow(params['a']!, 2) / 4,
            inv: (result, params) => pow(result * 4, 0.5).toDouble()),
        Definition.byParamNames(
            desc: '有限任意形状平板: (A/lambda)^2',
            paramNames: ['A'],
            func: (params) => pow(params['A']! * f / c, 2).toDouble(),
            inv: (result, params) => pow(result, 0.5) * c / f),
      ]),
      'NL': Term(name: 'NL', weight: -1.0, definitions: [
        Definition.byParamNames(
            desc: '根据海况: 10lgf^(-1.7)+6S+55+10lgB',
            paramNames: ['S'],
            func: (params) => 10 * log10(pow(f, -1.7)) + 6 * params['S']! + 55 + 10 * log10(B),
            inv: (result, params) => ((result - 10 * log10(pow(f, -1.7)) - 55 - 10 * log10(B)) ~/ 6).toDouble())
      ]),
      'DI': Term(name: 'DI', weight: 1.0, definitions: [
        Definition(
            desc: '线列阵: 10lgN',
            params: {'N': 1.0},
            func: (params) => 10 * log10(params['N']!),
            inv: (result, params) => pow(10, result / 10).toDouble()),
        Definition(
            desc: '点源方形阵: 10lgMN',
            params: {'M': 1.0, 'N': 1.0},
            func: (params) => 10 * log10(params['M']! * params['N']!),
            inv: (result, params) => pow(10, result / 10) / params['N']!),
        Definition(
            desc: '圆形活塞阵: 10lg(pi*D/lambda)^2',
            params: {'D': 1.0},
            func: (params) => 20 * log10(pi * params['D']! * f / c),
            inv: (result, params) => pow(10, result / 20) * c / f / pi),
        Definition(
            desc: '矩形活塞阵: 10lg(4pi*S/lambda^2)',
            params: {'S': 1.0},
            func: (params) => 10 * log10(4 * pi * params['S']! / pow(f / c, 2)),
            inv: (result, params) => pow(10, result / 10) * pow(c / f, 2) / 4 / pi),
      ]),
      'DT': Term(name: 'DT', weight: -1.0, definitions: [
        Definition.byParamNames(
            desc: '互相关接收机: 10lg(d/2/t)',
            paramNames: ['d'],
            func: (params) => 10 * log10(params['d']! / 2 / t),
            inv: (result, params) => pow(10, result / 10) * 2 * t),
        Definition.byParamNames(
            desc: '平方律检测器: 5lg(d*B/t)',
            paramNames: ['d'],
            func: (params) => 5 * log10(params['d']! * B / t),
            inv: (result, params) => pow(10, result / 5) * t / B),
        Definition.byParamNames(
            desc: '5lg(d*B/t)+|5lg(T/t)|',
            paramNames: ['d', 'T'],
            func: (params) => 5 * log10(params['d']! * B / t) + (5 * log10(params['T']! / t)).abs(),
            inv: (result, params) => pow(10, (result - (5 * log10(params['T']! / t)).abs()) / 5) * t / B)
      ]),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          for (var i = 0; i < _terms.length; i++)
            TermWidget(
              name: _terms.values.elementAt(i).name,
              value: _terms.values.elementAt(i).value,
              onSolve: _handleSolve,
              onSetValue: _handleSetValue,
            ),
        ],
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
      //FIXME: 先检查其他项填值没有
      double sum = 0.0;
      for (var i = 0; i < _terms.length; i++) {
        if (_terms.keys.elementAt(i) != name) {
          sum = sum + _terms.values.elementAt(i).value;
        }
      }
      _terms[name]!.value = -sum / _terms[name]!.weight;
    });
  }
}
