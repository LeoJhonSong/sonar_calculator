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
              Sv:& 发射电压响应(dB), 参考级为1\mu Pa/V@1m,\\
                 & 即在1V电压在1m距离产生1\mu Pa声压
            \end{aligned}\end{matrix}''',
          desc: '由发射电压',
          params: {'v': 1, 'S_v': 0},
          func: (params) => params['S_v']! + 20 * log10(params['v']!),
          inv: (result, params) => pow(10, (result - params['S_v']!) / 20).toDouble())
    ]),
    'TL': Term(name: 'TL', weight: -2.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            \boxed{\large{TL=20\lg r+60+\alpha r}}\\
            \begin{aligned}
              r:& 距离 (km). 扩展损失原本以m为单位,\\
                & 补偿60进行单位转换\\
              f:& 信号频率 (kHz)\\
              \alpha:&衰减系数(dB/km)\\
                     &=\frac{0.11f^2}{1+f^2}+\frac{44f^2}{4100+f^2}+3\times10^{-4}f^2+0.0033.\\
                     &适用于0-500kHz声信号
            \end{aligned}\end{matrix}''',
          desc: '粗略传播损失',
          params: {'r': 1},
          func: (params) => 20 * log10(params['r']!) + 60 + dependentParams['alpha']! * params['r']!,
          inv: (result, params) {
            // FIXME: 可能需要先try
            // see: https://github.com/albertodev01/equations/blob/fdc6ebe1049ca53bc5dbda307da7ce43944214d3/example/flutter_example/lib/routes/nonlinear_page/nonlinear_results.dart#L48
            final newton = Newton(function: '20*log(x)/log(10)+60+${dependentParams["alpha"]!}*x-$result', x0: 1.0);
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
              a_1,a_2:& 主曲率半径(m)\\
              r:& 距离\\
              k:& 波数
            \end{aligned}\end{matrix}''',
          desc: '凸面',
          params: {'a_1': 1, 'a_2': 1},
          func: (params) => 10 * log10(params['a_1']! * params['a_2']! / 4),
          inv: (result, params) => pow(10, result / 10) * 4 / params['a_2']!),
      Definition(
          eqn: r'''\begin{matrix}
            当\left\{\begin{aligned}&ka\gg 1\\&r>a\end{aligned}\right.\\
            \boxed{\large{TS=20\lg\frac{a}{2}}}\\
            \begin{aligned}
              a:& 球半径(m)\\
              r:& 距离\\
              k:& 波数
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
              A:& 平板面积(m^2)\\
              L:& 平板最大线度\\
              l:& 平板最小线度\\
              r:& 距离\\
              k:& 波数
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
              &其中TS=10\lg f^{-1.7}+6S+55^{[?]}给出指定\\
              &频点处环境噪声谱级, 加\lg B近似给出以f为\\
              &中心的频段内总噪声谱级
            \end{aligned}\\
            \begin{aligned}
              S:& 海况, 范围0-9\\
              f:& 信号频率(kHz)\\
              B:& 信号带宽(Hz)
            \end{aligned}\end{matrix}''',
          desc: '由海况(浅海)',
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
          params: {'N': 1},
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
          params: {'M': 1, 'N': 1},
          func: (params) => 10 * log10(params['M']! * params['N']!),
          inv: (result, params) => pow(10, result / 10) / params['N']!),
      Definition(
          eqn: r'''\begin{matrix}
            当D>2\lambda\\
            \boxed{\large{DI=20\lg\frac{\pi D}{\lambda}}}\\
            \begin{aligned}
              D:& 活塞阵直径(m)
            \end{aligned}\end{matrix}''',
          desc: '圆形活塞阵',
          params: {'D': 1},
          func: (params) => 20 * log10(pi * params['D']! / dependentParams['lambda']!),
          inv: (result, params) => pow(10, result / 20) * dependentParams['lambda']! / pi),
      Definition(
          eqn: r'''\begin{matrix}
            当a,b<2\lambda\\
            \boxed{\large{DI=10\lg\frac{4\pi S}{\lambda^2}}}\\
            \begin{aligned}
              S:& 活塞阵面积(m^2)\\
              a:& 活塞阵宽度\\
              b:& 活塞阵长度
            \end{aligned}\end{matrix}''',
          desc: '矩形活塞阵',
          params: {'S': 1},
          func: (params) => 10 * log10(4 * pi * params['S']! / pow(dependentParams['lambda']!, 2)),
          inv: (result, params) => pow(10, result / 10) * pow(dependentParams['lambda']!, 2) / 4 / pi),
    ]),
    'DT': Term(name: 'DT', weight: -1.0, definitions: [
      Definition(
          eqn: r'''\begin{matrix}
            单水听器且信号波形准确已知时, 将\\
            波形时间函数与水听器信号互相关\\
            \boxed{\large{DI=10\lg\frac{d}{2t}}}\\
            \begin{aligned}
              d:& 检测指数\\
              t:& 信号脉宽(s)\\
            \end{aligned}\end{matrix}''',
          desc: '匹配(互相关)接收机',
          params: {'d': 1},
          func: (params) => 10 * log10(params['d']! / 2 / knownParams['t']!),
          inv: (result, params) => pow(10, result / 10) * 2 * knownParams['t']!),
      Definition(
          eqn: r'''\begin{matrix}
            将N个水听器信号两两互相关后相加\\
            \boxed{\large{DI=5\lg\frac{dBN}{t(N-1)}\approx 5\lg\frac{dB}{t}}}\\
            \begin{aligned}
              d:& 检测指数\\
              N:& 阵元数\\
              t:& 信号脉宽(s)\\
              B:& 信号带宽(Hz)
            \end{aligned}\end{matrix}''',
          desc: '互相关器',
          params: {'d': 1},
          func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!),
          inv: (result, params) => pow(10, result / 5) * knownParams['t']! / knownParams['B']!),
      Definition(
          eqn: r'''\begin{matrix}
            信号未知时, 将N个水听器信号相加后自相关\\
            \boxed{\large{DI=5\lg\frac{d B}{t}}}\\
            \begin{aligned}
              d:& 检测指数\\
              t:& 信号脉宽(s)\\
              B:& 信号带宽(Hz)
            \end{aligned}\end{matrix}''',
          desc: '平方律(自相关)检波器',
          params: {'d': 1},
          func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!),
          inv: (result, params) => pow(10, result / 5) * knownParams['t']! / knownParams['B']!),
      Definition(
          eqn: r'''\begin{matrix}
            在平方律检波器后以积分处理平滑滤波\\
            \boxed{\large{DI=5\lg\frac{d B}{t}+\left|5\lg\frac{T}{t}\right|}}\\
            \begin{aligned}
              d:& 检测指数\\
              t:& 信号脉宽(s)\\
              B:& 信号带宽(Hz)\\
              T:& 积分时间 (s)
            \end{aligned}\end{matrix}''',
          desc: '积分处理的平方律检波器',
          params: {'d': 1, 'T': 0.01},
          func: (params) => 5 * log10(params['d']! * knownParams['B']! / knownParams['t']!) + (5 * log10(params['T']! / knownParams['t']!)).abs(),
          inv: (result, params) =>
              pow(10, (result - (5 * log10(params['T']! / knownParams['t']!)).abs()) / 5) * knownParams['t']! / knownParams['B']!)
    ]),
  };
}
