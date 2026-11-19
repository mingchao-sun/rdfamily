# rdfamily — 断点回归（jamovi 模块）

断点回归（RD）设计：基于 `rdrobust`、`rddensity`、`rdlocrand`、`rdmulti`、`rdhte`、`rdpower`、`RDHonest`。 英文完整说明见 [README.md](README.md)。

## 分析（jamovi 菜单：RDD）

| 分析 | 内容 |
|---|---|
| **断点回归（精确、模糊、拐点）** | 局部多项式，传统、偏差校正与稳健推断，带宽、协变量、整群、多断点 |
| **密度（操纵）检验** | `rddensity` |
| **协变量平衡/安慰剂结果** | 对预先决定变量做 RD |
| **功效与样本量** | `rdpower` |
| **稳健性检查** | 安慰剂断点、带宽倍数、甜甜圈半径、多项式阶数 |
| **多断点** | 各断点、加权与合并效应 |
| **诚实置信区间** | Armstrong-Kolesar |
| **地理/双得分边界** | 到边界的有符号距离 |
| **断点差分** | 政策变化前后的 RD |
| **异质性处理效应** | 按子组或连续调节变量 |
| **局部随机化** | 窗口内随机化推断 |
| **比较方法** | 多种设定的估计并列 |

每个分析的输出部分都有"方法说明"和"数据与设置指南"。

主要分析与 `rdrobust`、`rddensity`、`rdpower` 等直接调用的结果对照一致（`tests/reference.R`、`reference2.R`、`power.R`），Stata 对照在 `stata_validation`。示例数据见 `data/`（`rdsenate.csv` 等）。

## 安装
- **jamovi 模块库**：在 jamovi 右上角打开模块按钮，进入 *jamovi library*，搜索并安装（模块上架后）。
- **侧载**：下载 `.jmo` 文件，在同一菜单选 *Install from file*。`.jmo` 只适用于构建它的操作系统、处理器类型和 jamovi 版本。
- **从源码**：需要 R 和 `jmvtools`：`jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")`（路径按本机 jamovi 修改）。

## 引用与许可
引用：Sun, M. *rdfamily* (jamovi module). https://github.com/mingchao-sun/rdfamily 。请同时引用所用方法的原始文献（输出中列出）。

许可：见 `DESCRIPTION`（GPL）；第三方代码与数据见 `NOTICE`。问题与建议：https://github.com/mingchao-sun/rdfamily/issues

日本語の要約:[README.ja.md](README.ja.md)
