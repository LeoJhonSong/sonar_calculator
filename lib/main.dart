import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'auto_submit_text_field.dart';
import 'color_schemes.g.dart';
import 'references.dart';
import 'term.dart';
import 'terms_gen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(MaterialApp(
    title: '声呐方程计算器',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
    ),
    home: const MyHomePage(),
    debugShowCheckedModeBanner: false,
  ));

  doWhenWindowReady(() {
    const initialSize = Size(1800, 1000);
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
            title: const Text('典型接收机工作特性曲线 (ROC曲线)'),
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
                  color: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          '水声原理-尤立克 图12.6: 接收机工作特性曲线 (ROC曲线)。p(FA)为虚警概率; p(D)为检测概率; 参数d为检测指数.',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          '*当系统输出为具有不同的概率密度分布函数的噪声和具有不同的概率密度分布函数的信号加噪声时, 接收机的ROC是不同的.',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final void Function() onUpdateDepParam;
  const SettingsRow({
    super.key,
    required this.isPassive,
    required this.knownParams,
    required this.onSetPassive,
    required this.onUpdateDepParam,
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
    return Row(
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
        for (MapEntry<String, double> paramEntry in knownParams.entries)
          Padding(
            padding: EdgeInsets.only(right: paddingSize),
            child: SizedBox(
              width: 120,
              child: ParamTextField(
                paramValue: paramEntry.value,
                paramName: paramDisplayedNames[paramEntry.key]!,
                fillColor: Theme.of(context).colorScheme.outlineVariant,
                textColor: Theme.of(context).colorScheme.primary,
                onSubmitted: (text) {
                  knownParams[paramEntry.key] = double.parse(text);
                  onUpdateDepParam();
                },
              ),
            ),
          ),
        const ROCDialog(),
        SizedBox(width: paddingSize),
        const References(),
      ],
    );
  }
}

class WindowButtons extends StatelessWidget {
  final void Function() onPressMaximize;
  const WindowButtons({required this.onPressMaximize, super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: WindowButtonColors(iconNormal: Theme.of(context).colorScheme.outline)),
        WindowButton(
          colors: WindowButtonColors(iconNormal: Theme.of(context).colorScheme.outline),
          iconBuilder: (buttonContext) => MaximizeIcon(color: buttonContext.iconColor),
          onPressed: onPressMaximize,
        ),
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
  bool maximized = false;
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
    for (MapEntry<String, Term> termEntry in _terms.entries) {
      termEntry.value.value = termEntry.value.definitions[0].func();
    }
  }

  @override
  Widget build(BuildContext context) {
    final termScrollController = ScrollController();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: EdgeInsets.all((kIsWeb || !Platform.isLinux || maximized) ? 0 : 10),
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
          borderRadius: BorderRadius.circular((kIsWeb || !Platform.isLinux || maximized) ? 0 : 15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((kIsWeb || !Platform.isLinux || maximized) ? 0 : 15),
          child: Column(
            children: [
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(child: Material(color: Theme.of(context).colorScheme.surfaceVariant, child: MoveWindow(onDoubleTap: _handleMaximizeOrRestore))),
                    WindowButtons(onPressMaximize: _handleMaximizeOrRestore),
                  ],
                ),
              ),
              Expanded(
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            Text(
                              '声呐方程计算器',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            SizedBox(
                              height: pow(constraints.maxHeight / 1000, 1.8) * 120,
                              child: Align(
                                alignment: const Alignment(0, 0.65),
                                child: SettingsRow(
                                  knownParams: knownParams,
                                  isPassive: isPassive,
                                  onUpdateDepParam: _handleUpdateDepParam,
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
                                      for (MapEntry<String, Term> termEntry in _terms.entries)
                                        TermWidget(
                                          enabled: termEntry.value.enabled,
                                          name: termEntry.key,
                                          value: termEntry.value.value,
                                          onSolve: _handleSolve,
                                          onSetValue: _handleSetTermValue,
                                          definitions: termEntry.value.definitions,
                                          onSetTermByDef: _handleSetTermByDef,
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

  void _handleMaximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
      maximized = !maximized;
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

  void _handleSetTermByDef(String name, double value) {
    setState(() {
      _terms[name]!.value = value;
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
      for (MapEntry termEntry in _terms.entries) {
        if (termEntry.key != name) {
          sum = sum + termEntry.value.weight * termEntry.value.value;
        }
      }
      _terms[name]!.value = -sum / _terms[name]!.weight;
      _terms[name]!.calcParam();
      // TODO: 给值的更新添加颜色闪变? see: https://pub-web.flutter-io.cn/packages/flutter_animate
    });
  }

  void _handleUpdateDepParam() {
    setState(() {
      _calcDependent();
    });
  }
}
