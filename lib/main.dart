import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
    const initialSize = Size(2000, 1080);
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
        builder: (context) {
          return AlertDialog(
            title: const Text('接收机工作特性曲线 (ROC曲线)'),
            content: Column(
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

class SettingsRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isPassive;
  final Map<String, double> knownParams;
  final void Function(bool isIndex0) onSetPassive;
  final void Function(String paramName, double value) onSetParam;
  const SettingsRow({
    super.key,
    required this.colorScheme,
    required this.isPassive,
    required this.knownParams,
    required this.onSetPassive,
    required this.onSetParam,
  });

  @override
  Widget build(BuildContext context) {
    double paddingSize = 40;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(right: paddingSize),
            child: ToggleSwitch(
              minHeight: 56,
              initialLabelIndex: isPassive ? 0 : 1,
              totalSwitches: 2,
              activeBgColor: [colorScheme.primaryContainer],
              activeFgColor: colorScheme.onPrimaryContainer,
              inactiveBgColor: colorScheme.outlineVariant,
              inactiveFgColor: colorScheme.inversePrimary,
              labels: const ['主动', '被动'],
              onToggle: (index) => onSetPassive(index == 0),
            ),
          ),
          // 设置f, c, B, t
          for (String paramName in knownParams.keys)
            Padding(
              padding: EdgeInsets.only(right: paddingSize),
              child: SizedBox(
                width: 100,
                child: TextField(
                  controller: TextEditingController()..text = knownParams[paramName]!.toString(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.outlineVariant,
                    label: Math.tex(paramName, textStyle: TextStyle(color: colorScheme.primary)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8), // Set your desired radius
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      onSetParam(paramName, double.parse(value));
                    }
                  },
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const ROCDialog(),
        ],
      ),
    );
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
    // FIXME: 目前是通过给定默认初值的方式避免出错的, 但还是加上输入框的判断禁止填非正数比较好, 很多输入框都需要
    'f (kHz)': 1,
    'c': 1500,
    'B': 1,
    't': 1,
  };
  double alpha = 0;
  double lambda = 0;
  late Map<String, Term> _terms;

  _MyHomePageState() {
    alpha = _calcAlpha(knownParams['f (kHz)']!);
    lambda = _calcLambda(knownParams['c']!, knownParams['f (kHz)']!);
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
            eqn: r'\begin{aligned}&20\lg(1.0936r)+\alpha\times1.0936r,\\ &\alpha=\frac{\frac{0.1f^2}{1+f^2}+\frac{40f^2}{4100+f^2}+2.75\times10^{-4}f^2+0.003}{1.0936}\end{aligned}',
            desc: '浅海传播损失',
            paramNames: ['r'],
            func: (params) => 20 * log10(params['r']! * 1.0936) + alpha * params['r']! * 1.0936,
            inv: (result, params) {
              // FIXME: 可能需要先try
              // see: https://github.com/albertodev01/equations/blob/fdc6ebe1049ca53bc5dbda307da7ce43944214d3/example/flutter_example/lib/routes/nonlinear_page/nonlinear_results.dart#L48
              final newton = Newton(function: '20*log(x*1.0936)/log(10)+$alpha*x*1.0936-$result', x0: 1.0);
              final solutions = newton.solve();
              return solutions.guesses.last;
            })
      ]),
      'TS': Term(name: 'TS', weight: 1.0, definitions: [
        Definition(
            eqn:
                r'10\lg\frac{a_1a_2}{4}\left|\begin{aligned}a_1a_2&=主曲率半径\\r&=距离\\k&=波数\end{aligned}\right| \left.\begin{aligned}ka_1,ka_2&\gg1\\ r&>a\end{aligned}\right.',
            desc: '凸面',
            params: {'a_1': 1.0, 'a_2': 1.0},
            func: (params) => 10 * log10(params['a_1']! * params['a_2']! / 4),
            inv: (result, params) => pow(10, result/10) * 4 / params['a_2']!),
        Definition.byParamNames(
            eqn: r'20\lg\frac{a}{2}, a=球半径',
            desc: '大球',
            paramNames: ['a'],
            func: (params) => 20 * log10(params['a']!/2),
            inv: (result, params) => (pow(10, result / 20) * 2).toDouble()),
        Definition.byParamNames(
            eqn: r'20\lg\frac{A}{\lambda}',
            desc: '有限任意形状平板',
            paramNames: ['A'],
            func: (params) => 20 * log10(params['A']! / lambda).toDouble(),
            inv: (result, params) => pow(10, result / 20) * lambda),
      ]),
      'NL': Term(name: 'NL', weight: -1.0, definitions: [
        Definition.byParamNames(
            eqn: r'10\lg f^{-1.7}+6S+55+10\lg B',
            desc: '由海况',
            paramNames: ['S'],
            func: (params) => 10 * log10(pow(knownParams['f (kHz)']!, -1.7)) + 6 * params['S']! + 55 + 10 * log10(knownParams['B']!),
            inv: (result, params) => ((result - 10 * log10(pow(knownParams['f (kHz)']!, -1.7)) - 55 - 10 * log10(knownParams['B']!)) ~/ 6).toDouble())
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
            func: (params) => 20 * log10(pi * params['D']! /lambda),
            inv: (result, params) => pow(10, result / 20) * lambda / pi),
        Definition(
            eqn: r'10\lg\frac{4\pi S}{\lambda^2}',
            desc: '矩形活塞阵',
            params: {'S': 1.0},
            func: (params) => 10 * log10(4 * pi * params['S']! / pow(lambda, 2)),
            inv: (result, params) => pow(10, result / 10) * pow(lambda, 2) / 4 / pi),
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final termScrollController = ScrollController();
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
                      child: LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            // TODO: 关于页面, 给出参考文献列表, 这改为row
                            Text(
                              '声呐方程计算器',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            SizedBox(
                              height: pow(constraints.maxHeight, 1.2) * 0.05,
                              child: Align(
                                alignment: const Alignment(0, 0.7),
                                child: SettingsRow(
                                  colorScheme: colorScheme,
                                  knownParams: knownParams,
                                  isPassive: isPassive,
                                  onSetParam: _handleSetParam,
                                  onSetPassive: _handleSetPassive,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Scrollbar(
                                controller: termScrollController,
                                child: SingleChildScrollView(
                                  controller: termScrollController,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (var i = 0; i < _terms.length; i++)
                                        TermWidget(
                                          name: _terms.values.elementAt(i).name,
                                          value: _terms.values.elementAt(i).value,
                                          onSolve: _handleSolve,
                                          onSetValue: _handleSetTermValue,
                                          definitions: _terms.values.elementAt(i).definitions,
                                          onSetTermByDefIdx: _handleSetTermByDefIdx,
                                          setDefParam: _handleSetDefParam,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      })),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSetDefParam(String name, int defIdx, String paramName, double value) {
    setState(() {
      _terms[name]!.definitions[defIdx].params[paramName] = value;
    });
  }

  void _handleSetParam(String paramName, double value) {
    setState(() {
      knownParams[paramName] = value;
      alpha = _calcAlpha(knownParams['f (kHz)']!);
      lambda = _calcLambda(knownParams['c']!, knownParams['f (kHz)']!);
    });
  }

  void _handleSetPassive(bool isIndex0) {
    setState(() {
      isPassive = isIndex0;
      // 在主动/被动声呐方程间切换
      if (isPassive) {
        _terms['TL']!.weight = -2;
        _terms['TS']!.weight = 1;
      } else {
        _terms['TL']!.weight = -1;
        _terms['TS']!.weight = 0;
      }
    });
    // TODO: Color filtered TS列
  }

  void _handleSetTermByDefIdx(String name, int defIdx) {
    setState(() {
      _terms[name]!.calcValue(defIdx);
    });
  }

  void _handleSetTermValue(String name, double value) {
    setState(() {
      _terms[name]!.value = value;
      _terms[name]!.calcParam();
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
      _terms[name]!.calcParam();
      // TODO: 给值的更新添加颜色闪变? see: https://pub-web.flutter-io.cn/packages/flutter_animate
    });
  }

  double _calcAlpha(double f) {
    double f2 = pow(f, 2).toDouble();
    return ((0.1 * f2 / (1 + f2)) + (40 * f2 / (4100 + f2)) + 2.75e-4 * f2 + 0.003) / 1.0936;
  }

  double _calcLambda(double c, double fkHz) {
    return c / fkHz / 1000;
  }
}
