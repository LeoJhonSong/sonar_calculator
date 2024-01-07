import 'dart:math';

import 'package:equations/equations.dart';

import 'definition.dart';
import 'term.dart';

double log10(num x) => log(x) / ln10;

Map<String, Term> termsGen(Map<String, double> knownParams, Map<String, double> dependentParams) {
  return {
    'SL': Term(name: 'SL', weight: 1.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{SL=S_v+20\lg v}}\\
            \begin{aligned}
              v:& 发射器终端电压(V)\\
              Sv:& 发射电压响应
            \end{aligned}\end{matrix}''',
          desc: '由发射电压',
          params: {'v': 1, 'S_v': 0},
          func: (params) => params['S_v']! + 20 * log10(params['v']!),
          inv: (result, params) => pow(10, (result - params['S_v']!) / 20).toDouble())
    ]),
    'TL': Term(name: 'TL', weight: -2.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{TL=20\lg(1.0936r)+\alpha\times1.0936r}}\\
            \begin{aligned}
              r:& 距离 (km)\\
              \alpha:&衰减系数=\frac{\frac{0.1f^2}{1+f^2}+\frac{40f^2}{4100+f^2}+2.75\times10^{-4}f^2+0.003}{1.0936}
            \end{aligned}\end{matrix}''',
          desc: '近距离浅海传播损失',
          params: {'r': 1},
          func: (params) => 20 * log10(params['r']! * 1.0936) + dependentParams['alpha']! * params['r']! * 1.0936,
          inv: (result, params) {
            // FIXME: 可能需要先try
            // see: https://github.com/albertodev01/equations/blob/fdc6ebe1049ca53bc5dbda307da7ce43944214d3/example/flutter_example/lib/routes/nonlinear_page/nonlinear_results.dart#L48
            final newton = Newton(function: '20*log(x*1.0936)/log(10)+${dependentParams["alpha"]!}*x*1.0936-$result', x0: 1.0);
            final solutions = newton.solve();
            return solutions.guesses.last;
          })
    ]),
    'TS': Term(name: 'TS', weight: 1.0, definitions: [
      //TODO: 单位
      Definition(
          eqn: r'''\begin{matrix}
            当垂直于表面入射且\left\{\begin{aligned}&ka_1,ka_2\gg 1\\&r>a\end{aligned}\right.\\
            \boxed{\large{TS=10\lg\frac{a_1a_2}{4}}}\\
            \begin{aligned}
              a_1a_2:& 主曲率半径\\
              r:& 距离\\
              k:& 波数
            \end{aligned}\end{matrix}''',
          desc: '凸面',
          params: {'a_1': 1.0, 'a_2': 1.0},
          func: (params) => 10 * log10(params['a_1']! * params['a_2']! / 4),
          inv: (result, params) => pow(10, result / 10) * 4 / params['a_2']!),
      Definition(
          eqn: r'''\begin{matrix}
            当\left\{\begin{aligned}&ka\gg 1\\&r>a\end{aligned}\right.\\
            \boxed{\large{TS=20\lg\frac{a}{2}}}\\
            \begin{aligned}
              a:&球半径
            \end{aligned}\end{matrix}''',
          desc: '大球',
          params: {'a': 1},
          func: (params) => 20 * log10(params['a']! / 2),
          inv: (result, params) => (pow(10, result / 20) * 2).toDouble()),
      Definition(
          eqn: r'''\begin{matrix}
            当垂直于平板入射且r>\frac{L^2}{\lambda},kl\gg 1\\
            \boxed{\large{TS=20\lg\frac{A}{\lambda}}}\\
            \begin{aligned}
              A:& 平板面积\\
              L:& 平板最大线度\\
              l:& 平板最小线度
            \end{aligned}\end{matrix}''',
          desc: '有限任意形状平板',
          params: {'A': 1},
          func: (params) => 20 * log10(params['A']! / dependentParams['lambda']!).toDouble(),
          inv: (result, params) => pow(10, result / 20) * dependentParams['lambda']!),
    ]),
    'NL': Term(name: 'NL', weight: -1.0, definitions: [
      Definition.byParamNames(
          eqn: r'''\begin{matrix}
            \boxed{\large{TS=10\lg f^{-1.7}+6S+55+10\lg B}}\\
            \begin{aligned}
              S:& 海况
            \end{aligned}\end{matrix}''',
          desc: '用海况表示的浅海噪声谱级',
          paramNames: ['S'],
          func: (params) => -17 * log10(knownParams['f']!) + 6 * params['S']! + 55 + 10 * log10(knownParams['B']!),
          inv: (result, params) => ((result + 17 * log10(knownParams['f']!) - 55 - 10 * log10(knownParams['B']!)) ~/ 6).toDouble())
    ]),
    'DI': Term(name: 'DI', weight: 1.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{DI=10\lg N}}\\
            \begin{aligned}
              N:& 阵元数
            \end{aligned}\end{matrix}''',
          desc: '线列阵',
          params: {'N': 1.0},
          func: (params) => 10 * log10(params['N']!),
          inv: (result, params) => pow(10, result / 10).toDouble()),
      Definition(
          eqn: r'''\begin{matrix}
            当\left\{\begin{aligned}&d_1=\frac{n_1\lambda}{2}\\&d_2=\frac{n_2\lambda}{2}\end{aligned}\right.\\
            \boxed{\large{DI=10\lg MN}}\\
            \begin{aligned}
              N:& 行阵元数\\
              M:& 列阵元数\\
              d_1:& 行间距\\
              d_2:& 列间距
            \end{aligned}\end{matrix}''',
          desc: '点源方形阵',
          params: {'M': 1.0, 'N': 1.0},
          func: (params) => 10 * log10(params['M']! * params['N']!),
          inv: (result, params) => pow(10, result / 10) / params['N']!),
      Definition(
          eqn: r'''\begin{matrix}
            当D>2\lambda\\
            \boxed{\large{DI=20\lg\frac{\pi D}{\lambda}}}\\
            \begin{aligned}
              D:& 活塞阵直径
            \end{aligned}\end{matrix}''',
          desc: '圆形活塞阵',
          params: {'D': 1.0},
          func: (params) => 20 * log10(pi * params['D']! / dependentParams['lambda']!),
          inv: (result, params) => pow(10, result / 20) * dependentParams['lambda']! / pi),
      Definition(
          eqn: r'''\begin{matrix}
            当a,b<2\lambda\\
            \boxed{\large{DI=10\lg\frac{4\pi S}{\lambda^2}}}\\
            \begin{aligned}
              S:& 活塞阵面积\\
              a:& 活塞阵宽度\\
              b:& 活塞阵长度
            \end{aligned}\end{matrix}''',
          desc: '矩形活塞阵',
          params: {'S': 1.0},
          func: (params) => 10 * log10(4 * pi * params['S']! / pow(dependentParams['lambda']!, 2)),
          inv: (result, params) => pow(10, result / 10) * pow(dependentParams['lambda']!, 2) / 4 / pi),
    ]),
    'DT': Term(name: 'DT', weight: -1.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{DI=10\lg\frac{d}{2t}}}\\
            \begin{aligned}
              t:& 信号持续时间 (脉宽)
            \end{aligned}\end{matrix}''',
          desc: '互相关接收机',
          params: {'d': 1.0},
          func: (params) => 10 * log10(params['d']! / 2 / knownParams['t']!),
          inv: (result, params) => pow(10, result / 10) * 2 * knownParams['t']!),
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{DI=5\lg\frac{d B}{t}}}\\
            \begin{aligned}
              t:& 信号持续时间 (脉宽)\\
              B:& 信号带宽
            \end{aligned}\end{matrix}''',
          desc: '平方律检测器',
          params: {'d': 1.0},
          func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!),
          inv: (result, params) => pow(10, result / 5) * knownParams['t']! / knownParams['B']!),
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{DI=5\lg\frac{d B}{t}+\left|5\lg\frac{T}{t}\right|}}\\
            \begin{aligned}
              t:& 信号持续时间 (脉宽)\\
              B:& 信号带宽\\
              T:& 积分时间 (s)
            \end{aligned}\end{matrix}''',
          desc: '平滑滤波器',
          params: {'d': 1.0, 'T': 1.0},
          func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!) + (5 * log10(params['T']! / knownParams['t']!)).abs(),
          inv: (result, params) =>
              pow(10, (result - (5 * log10(params['T']! / knownParams['t']!)).abs()) / 5) * knownParams['t']! / knownParams['B']!)
    ]),
  };
}
