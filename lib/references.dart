import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class References extends StatelessWidget {
  const References({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _rocDialogBuilder(context),
      label: const Text('参考文献列表'),
    );
  }

  Future<void> _rocDialogBuilder(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('参考文献列表'),
            content: SizedBox(
              width: 800,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Text('[1]'),
                    title: const Text('R. J. 尤立克. 水声原理[M]. 洪申译. 第3版. 哈尔滨船舶工程学院出版社, 1990: 88.'),
                    subtitle: Math.tex(r'文献式中r的单位是m,为方便使用,改用km,因此球面扩展项多出60'),
                  ),
                  ListTile(
                    leading: const Text('[2]'),
                    title: const Text('R. J. 尤立克. 水声原理[M]. 洪申译. 第3版. 哈尔滨船舶工程学院出版社, 1990: 85.'),
                    subtitle: Math.tex(r'对Thorp表达式乘以1.1, 将单位由dB/kyd转换为dB/km'),
                  ),
                  ListTile(
                    leading: const Text('[3]'),
                    title: const Text('R. J. 尤立克. 水声原理[M]. 洪申译. 第3版. 哈尔滨船舶工程学院出版社, 1990: 239.'),
                    subtitle: Math.tex(r'表9.1 简单形状物体的目标强度'),
                  ),
                  ListTile(
                    leading: const Text('[4]'),
                    title: const Text('刘孟庵. 水声工程[M]. 浙江科学技术出版社, 2002: 72.'),
                    subtitle: Math.tex(r'式(2-49) TS=10\lg f^{-1.7}+6S+55给出指定频点的环境噪声谱级, 加\lg B近似给出以f为中心的频段内总噪声谱级.'),
                  ),
                  ListTile(
                    leading: const Text('[5]'),
                    title: const Text('栾桂冬, 张金铎, 王仁乾. 压电换能器和换能器阵. 修订版. 北京大学出版社, 2005: 363.'),
                    subtitle: Math.tex(r'当给定d=\frac{n\lambda}{2}时由式(14.30)化简得.'),
                  ),
                  ListTile(
                    leading: const Text('[6]'),
                    title: const Text('栾桂冬, 张金铎, 王仁乾. 压电换能器和换能器阵. 修订版. 北京大学出版社, 2005: 382.'),
                    subtitle: Math.tex(r'当给定d_1=\frac{m\lambda}{2},d_2=\frac{n\lambda}{2}时由非相控阵空间增益化简得.'),
                  ),
                  ListTile(
                    leading: const Text('[7]'),
                    title: const Text('栾桂冬, 张金铎, 王仁乾. 压电换能器和换能器阵. 修订版. 北京大学出版社, 2005: 373.'),
                    subtitle: Math.tex(r'忽略式(14.55)中\frac{J_1(4\pi a/\lambda)}{2\pi a/\lambda}项整理得.'),
                  ),
                  const ListTile(
                    leading: Text('[8]'),
                    title: Text('栾桂冬, 张金铎, 王仁乾. 压电换能器和换能器阵. 修订版. 北京大学出版社, 2005: 376.'),
                  ),
                  const ListTile(
                    leading: Text('[9]'),
                    title: Text('R. J. 尤立克. 水声原理[M]. 洪申译. 第3版. 哈尔滨船舶工程学院出版社, 1990: 309.'),
                  ),
                  const ListTile(
                    leading: Text('[10]'),
                    title: Text('R. J. 尤立克. 水声原理[M]. 洪申译. 第3版. 哈尔滨船舶工程学院出版社, 1990: 300'),
                  ),
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
