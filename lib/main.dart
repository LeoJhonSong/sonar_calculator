import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'auto_submit_text_field.dart';
import 'color_schemes.g.dart';
import 'references.dart';
import 'term.dart';
import 'terms_gen.dart';

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
      label: const Text('ROC曲线'),
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
                      height: 1000,
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
                      '水声原理-尤立克 图12.6: 接收机工作特性曲线 (ROC曲线)。p(FA)为虚警概率; p(D)为检测概率; 参数d为检测指数', //TODO: 补充说明这只是示例
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
  final bool isPassive;
  final Map<String, double> knownParams;
  final void Function(bool isIndex0) onSetPassive;
  final void Function(String paramName, double value) onSetParam;
  const SettingsRow({
    super.key,
    required this.isPassive,
    required this.knownParams,
    required this.onSetPassive,
    required this.onSetParam,
  });

  @override
  Widget build(BuildContext context) {
    double paddingSize = 40;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Map<String, String> paramDisplayedNames = {
      'f': '信号频率f (kHz)',
      'c': '声速c (m/s)',
      'B': '信号带宽B (Hz)',
      't': '信号脉宽t (s)',
    };
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
                width: 120,
                child: ParamTextField(
                  paramValue: knownParams[paramName]!,
                  paramName: paramDisplayedNames[paramName]!,
                  fillColor: Theme.of(context).colorScheme.outlineVariant,
                  textColor: Theme.of(context).colorScheme.primary,
                  onSubmitted: (text) => onSetParam(paramName, double.parse(text)),
                ),
              ),
            ),
          const ROCDialog(),
          SizedBox(width: paddingSize),
          const References(),
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
    'f': 1,
    'c': 1500,
    'B': 1000,
    't': 0.01,
  };
  Map<String, double> dependentParams = {
    'alpha': 0,
    'lambda': 0,
  };
  late Map<String, Term> _terms;

  _MyHomePageState() {
    _calcDependent();
    _terms = termsGen(knownParams, dependentParams);
    for (String name in _terms.keys) {
      _terms[name]!.calcValue(0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            Text(
                              '声呐方程计算器',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            SizedBox(
                              height: pow(constraints.maxHeight, 1.2) * 0.05,
                              child: Align(
                                alignment: const Alignment(0, 0.7),
                                child: SettingsRow(
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
                                      for (MapEntry<String, Term> entry in _terms.entries)
                                        TermWidget(
                                          enabled: entry.value.enabled,
                                          name: entry.key,
                                          value: entry.value.value,
                                          onSolve: _handleSolve,
                                          onSetValue: _handleSetTermValue,
                                          definitions: entry.value.definitions,
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

  void _calcDependent() {
    double c = knownParams['c']!;
    double fkHz = knownParams['f']!;
    double f2 = pow(fkHz, 2).toDouble();
    dependentParams['alpha'] = (0.11 * f2 / (1 + f2)) + (44 * f2 / (4100 + f2)) + 3.025e-4 * f2 + 0.0033;
    dependentParams['lambda'] = c / fkHz / 1000;
  }

  void _handleSetDefParam(String name, int defIdx, String paramName, double value) {
    setState(() {
      _terms[name]!.definitions[defIdx].params[paramName] = value;
    });
  }

  void _handleSetParam(String paramName, double value) {
    setState(() {
      knownParams[paramName] = value;
      _calcDependent();
    });
  }

  void _handleSetPassive(bool isIndex0) {
    setState(() {
      isPassive = isIndex0;
      if (isPassive) {
        // 切换为主动声呐方程
        _terms['TL']!.weight = -2;
        _terms['TS']!.weight = 1;
        _terms['TS']!.enabled = true;
      } else {
        // 切换为被动声呐方程
        _terms['TL']!.weight = -1;
        _terms['TS']!.weight = 0;
        _terms['TS']!.enabled = false;
      }
    });
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
}
