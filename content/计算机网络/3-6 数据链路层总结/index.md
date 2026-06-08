+++

title = '3.6 数据链路层总结'

date = 2026-06-07T12:00:00+08:00

lastmod = 2026-06-07T12:00:00+08:00

draft = false

weight = 36
slug = "summary of data link layer"

summary = "串联数据链路层的关键知识点"

tags = []

categories = ["计算机网络"]

+++

## 核心设计思想

```
物理层不可靠
↓
需要封装成帧

帧可能出错
↓
需要CRC

CRC只能检错
↓
需要ARQ

停等效率低
↓
滑动窗口

共享信道冲突
↓
MAC协议

总线效率低
↓
交换机

广播域过大
↓
VLAN

点对点链路
↓
PPP
```