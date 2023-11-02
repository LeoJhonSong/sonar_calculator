# sonar_calculator

## 需求

[思维导图](https://docs.qq.com/mind/DY01GakVYcFlJdnFj?u=91afc42b08304211b09fd88daf9c0b43)

- 基本参数
  - 信号参数: 频率f，声速C，信号形式:CW/Chirp，脉宽t_pulse，带宽B
  - 探测方式: 主动探测, 被动探测
  - 探测距离: 最近距离, 最远距离
  - 换能器参数: 发送响应、接收灵敏度、指向性（阵型、通道数）
- 计算结果
  - `SL` 最大发射功率  发射电压有效值
  - `TL` α吸收系数
  - `NL` 海洋背景噪声
  - `DI` 阵型、阵元数
  - `TS` 目标类型 目标大小
  - `DT` 虚警概率 检测概率（输入值）

### 公式

**可以整理出必填参数为: $f, c/\lambda$**

```
         信号级  -背景干扰级=检测阈
主动: (SL-2TL+TS)-(NL-DI)=DT
被动: (SL- TL)   -(NL-DI)=DT
```

- $SL=S_v+20\lg v=S_w+10\lg P, S_v/S_w为发射电压/功率响应 (值一样), v为发射器终端电压, P为发射器终端功率$

- $TL=20\lg r+\alpha r$ *尤里克P141, 近距离范围内浅海传播损失*
  - $\alpha=1.0936\times(\frac{0.1f^2}{1+f^2}+\frac{40f^2}{4100+f^2}+2.75\times10^{-4}f^2+0.003)$ *尤里克P85, 低频段吸收系数经验公式 (Thorp)* ==针对4度, 3000英尺约为914.4m处==

- $TS$: 凸面, 大球, 有限任意平板

  <img src="README/image-20231026215022847.png" alt="image-20231026215022847"  />

- $NL=10\lg f^{-1.7}+6S+55+10\lg B$ *刘伯胜P249公式7.20c用海况表示的浅海噪声谱级 (加上带内噪声)*

- DI=

  - | 型式         | AG                                             | 符号                             | 条件                                                | 参考文献                                            |
    | ------------ | ---------------------------------------------- | -------------------------------- | --------------------------------------------------- | --------------------------------------------------- |
    | 线列阵       | $10\lg N$                                      | $N为阵元数,d为孔径$              | $d=\frac{n\lambda}{2}$                              | *压电换能器和换能器阵P363公式14.30*                 |
    | 点源方形阵   | $10\lg MN$                                     | $N行M列阵元,行间距d_1,列间距d_2$ | $d_1=\frac{n_1\lambda}{2},d_2=\frac{n_2\lambda}{2}$ | *压电换能器和换能器阵P382非相控阵空间增益*          |
    | 椭圆形活塞阵 | $10\lg \frac{4\pi^2\sqrt{a^2+b^2}}{\lambda^2}$ | $2b为长轴,2a为短轴$              | $b>\lambda$                                         | *压电换能器和换能器阵P374*                          |
    | 圆形活塞阵   | $10\lg(\frac{\pi D}{\lambda})^2$               | $D为活塞阵直径$                  | $a>\lambda$                                         | *压电换能器和换能器阵P374* (由椭圆形活塞阵AG变换得) |
    | 矩形活塞阵   | $10\lg \frac{4\pi S}{\lambda^2}$               | $b为长,a为宽$                    | $a, b<2\lambda$                                     | *压电换能器和换能器阵P376*                          |

- DT *尤里克P300*
  - 互相关接收机: $DT=10\lg \frac{d}{2t}, t为信号持续时间, B为带宽$
  - 平方律检测器: $DT=5\lg\frac{dB}{t}$
  - 平滑滤波器: $DT=5\lg\frac{dB}{t}+|5\lg\frac{T}{t}|, T为积分时间$
  - d检测指数由$检测概率p(D)和虚警概率p(FA)的ROC曲线给出$ *尤里克P299*<img src="README/image-20231027020229545.png" alt="image-20231027020229545"  />




## 参考资料

### Flutter

- [Flutter中文文档](https://flutter.cn/docs/)
- [Flutter换官方源](https://flutter.cn/community/china) [换清华源](https://help.mirrors.cernet.edu.cn/flutter/)
- [Material UI组件示例](https://flutter.github.io/samples/web/material_3_demo/)
- [数学公式渲染包](https://pub.dev/packages/flutter_math_fork)
- [找第三方包网站](https://fluttergems.dev/)
- ["将状态维护在父部件, 子部件调用接收自父部件的句柄"方式实现参考](https://flutter.cn/docs/ui#bringing-it-all-together)
- [TabBar class](https://api.flutter.dev/flutter/material/TabBar-class.html)
- [动画图标](https://api.flutter.dev/flutter/material/AnimatedIcon-class.html)
