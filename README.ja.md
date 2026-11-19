# rdfamily — 回帰不連続デザイン（jamovi モジュール）

回帰不連続 (RD) デザイン。`rdrobust`、`rddensity`、`rdlocrand`、`rdmulti`、`rdhte`、`rdpower`、`RDHonest` を利用します。 詳しい英語の説明は [README.md](README.md)、中国語の要約は [README.zh.md](README.zh.md) を参照してください。

## 分析（jamovi メニュー：RDD）

| 分析 | 内容 |
|---|---|
| **回帰不連続（シャープ、ファジー、キンク）** | 局所多項式。従来型・バイアス補正・頑健な推測、バンド幅、共変量、クラスター、複数カットオフ |
| **密度（操作）検定** | `rddensity` |
| **共変量バランス/プラセボ** | 事前決定変数への RD 効果 |
| **検出力とサンプルサイズ** | `rdpower` |
| **頑健性チェック** | プラセボカットオフ、バンド幅の倍率、ドーナツ半径、多項式次数 |
| **複数カットオフ** | カットオフ別・加重・プール効果 |
| **誠実な信頼区間** | Armstrong-Kolesar |
| **地理的/2 スコア境界** | 境界への符号付き距離 |
| **不連続の差の差** | 政策変更前後の RD |
| **異質な処置効果** | サブグループまたは連続調整変数別 |
| **局所ランダム化** | ウィンドウ内のランダム化推測 |
| **手法の比較** | 複数の設定の推定値を並べて表示 |

各分析の出力には「方法の説明」と「データと設定ガイド」があります。

主要な分析は `rdrobust`、`rddensity`、`rdpower` などを直接呼び出した結果と一致します（`tests/reference.R` など）。Stata との比較は `stata_validation` にあります。サンプルデータは `data/`（`rdsenate.csv` など）。

## インストール
- **jamovi ライブラリ**：jamovi 右上のモジュールボタンから *jamovi library* を開き、検索してインストール（モジュール公開後）。
- **サイドロード**：`.jmo` ファイルをダウンロードし、同じメニューの *Install from file* から導入します。`.jmo` はビルドした OS、プロセッサ、jamovi のバージョンでのみ動作します。
- **ソースから**：R と `jmvtools` が必要です：`jmvtools::install(home = "C:/Program Files/jamovi 28.17.0.0")`（パスはお使いの jamovi に合わせてください）。

## 引用とライセンス
引用：Sun, M. *rdfamily* (jamovi module). https://github.com/mingchao-sun/rdfamily 。使用した手法の原論文（出力に記載）も併せて引用してください。

ライセンス：`DESCRIPTION` を参照（GPL）。第三者のコードとデータは `NOTICE` に記載。不具合や提案：https://github.com/mingchao-sun/rdfamily/issues
