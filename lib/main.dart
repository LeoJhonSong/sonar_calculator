import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
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

  doWhenWindowReady(() {
    const initialSize = Size(2000, 1000);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

double log10(num x) => log(x) / ln10;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ROCDialog extends StatelessWidget {
  const ROCDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _rocDialogBuilder(context),
      label: const Text('ROC曲线'), // FIXME: 需要改名吗
    );
  }

  Future<void> _rocDialogBuilder(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('接收机工作特性曲线 (ROC曲线)'),
            content: Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        height: 1000, // FIXME: 需要更大吗?
                        width: 1000,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.modulate),
                          child: Image.asset(
                            'assets/roc.png',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Card(
                    // width: double.infinity,
                    color: Theme.of(context).colorScheme.surface,
                    surfaceTintColor: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '水声原理-尤立克 图12.6: 接收机工作特性曲线 (ROC曲线)。p(FA)为虚警概率; p(D)为检测概率; 参数d为检测指数',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('关闭'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: WindowButtonColors(iconNormal: Theme.of(context).colorScheme.outline)),
        MaximizeWindowButton(colors: WindowButtonColors(iconNormal: Theme.of(context).colorScheme.outline)),
        CloseWindowButton(
            colors: WindowButtonColors(
          iconNormal: Theme.of(context).colorScheme.outline,
          mouseOver: Theme.of(context).colorScheme.errorContainer,
        )),
      ],
    );
  }
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
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          border: Border.all(
            color: Colors.grey.withOpacity(0.2), //边框颜色
            width: 1, //边框宽度
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(child: Material(color: Theme.of(context).colorScheme.surfaceVariant, child: MoveWindow())),
                    const WindowButtons(),
                  ],
                ),
              ),
              Expanded(
                child: Material(
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
                            // TODO: 换一下https://pub-web.flutter-io.cn/packages/toggle_switch
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
                            const ROCDialog(),
                            // TODO: 关于页面, 给出参考文献列表
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
      // TODO: 给值的更新添加颜色闪变? see: https://pub-web.flutter-io.cn/packages/flutter_animate
    });
  }
}
