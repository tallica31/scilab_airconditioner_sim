# 自動車用冷媒回路モデル v0.1

車室用エバポレータとチラーを並列接続した、R1234yfの定常冷凍サイクルです。
対象環境は **Windows 11 x64 + Scilab 2026.1.0 + CoolProp 8.0.0 x64共有ライブラリ**。

順計算、逆計算、車室能力とチラー流量の混合指定、各部状態CSV、p–h線図、凝縮温度の条件比較、Xcosからの実行を用意しています。

## 1. 最初の実行

1. ZIPを展開します。以下では `C:/ac_model/` とします。ZIP内のフォルダ名が違う場合は実際のパスに置き換えてください。
2. [CoolProp公式配布先のWindows/64bitフォルダ](https://sourceforge.net/projects/coolprop/files/CoolProp/8.0.0/shared_library/Windows/64bit/)から **CoolProp.dll** を取得し、`C:/ac_model/lib/CoolProp.dll` に置きます。DLLはZIPに含めていません。32bit版・arm64版・Python用pydは使用しません。
3. Scilabを起動し、コンソールで次を実行します。

```scilab
exec("C:/ac_model/selftest.sce", -1);
```

`PASS: core ...` と `PASS: integrated Xcos ...` の2つが出れば、その環境で基本計算とXcos連携が動作しています。

4. GUIとサンプルを開きます。

```scilab
exec("C:/ac_model/start.sce", -1);
```

コンソールに4ケースの計算結果、`results/` にCSVが出力され、p–h線図とXcosモデルが開きます。図は各状態点を結んだ模式的な経路で、圧縮機や熱交換器内部の分布を表しません。

Python、PIMS、C/C++コンパイラは利用者側では不要です。共有ライブラリの `propssi_` をScilabの `link` / `call` で呼びます。接続時にR1234yfの飽和圧力で簡易確認します。

## 2. 基準ケース

| 入力 | 低負荷 | 高負荷 |
|---|---:|---:|
| 共通の蒸発温度 | 5℃ | 5℃ |
| 凝縮温度 | 50℃ | 50℃ |
| 車室側出口過熱度 | 5 K | 5 K |
| チラー出口過熱度 | 5 K | 5 K |
| コンデンサ出口過冷却度 | 5 K | 5 K |
| 等エントロピー効率 | 0.70 | 0.70 |
| 車室側流量 | 150 kg/h | 150 kg/h |
| チラー流量 | 100 kg/h | 250 kg/h |

参照会話で提示されたチラー流量・外気35℃と、会話内で仮定された車室流量・温度条件を基にしています。外気35℃は背景条件であり、本モデルには空気側性能式がないため、入力から凝縮温度を決める関係はありません。

CoolProp 8.0.0での基準結果（丸め値）：

| 出力 | 低負荷 | 高負荷 |
|---|---:|---:|
| 低圧側 | 0.373006 MPaA | 同左 |
| 高圧側 | 1.302349 MPaA | 同左 |
| 吐出温度 | 59.6135℃ | 同左 |
| 膨張弁出口乾き度 | 0.348589 | 同左 |
| 車室冷却能力 | 4.544211 kW | 4.544211 kW |
| チラー冷却能力 | 3.029474 kW | 7.573685 kW |
| 冷媒への圧縮仕事率 | 2.262721 kW | 3.620354 kW |
| 必要コンデンサ放熱量 | 9.836405 kW | 15.738249 kW |

高負荷で温度・圧力が同じなのは、その状態を入力として指定しているためです。実際の機器が高負荷時にもその状態を維持できると示したものではありません。

## 3. Scilabで条件を変更する

新しいScilabセッションでは最初に `loader.sce` を実行します。

### 順計算：流量から能力

```scilab
exec("C:/ac_model/loader.sce", -1);
c = ac_defaults();
c.value_e = 150;       // 車室側 kg/h
c.value_ch = 250;      // チラー側 kg/h
c.Tc_C = 55;          // 凝縮温度を指定
r = ac_cycle(c);
ac_report(r);
ac_export(r, AC_ROOT+"results", "custom_forward");
ac_plot_ph(r);
```

### 逆計算：能力から流量

```scilab
c = ac_defaults();
c.mode_e = "capacity";
c.mode_ch = "capacity";
c.value_e = 5;        // 車室側要求能力 kW
c.value_ch = 3;       // チラー要求能力 kW
r = ac_cycle(c);
ac_report(r);
```

### 混合指定：車室5 kW、チラー100 kg/h

```scilab
c = ac_defaults();
c.mode_e = "capacity";
c.value_e = 5;        // kW
c.mode_ch = "flow";
c.value_ch = 100;     // kg/h
r = ac_cycle(c);
ac_report(r);
```

この条件では車室流量は約165.05 kg/h、全体は約265.05 kg/hになります。逆計算・混合指定では、全体250/400 kg/hを同時には固定しません。

変更可能な状態条件：`Te_C`, `Tc_C`, `SH_e_K`, `SH_ch_K`, `SC_K`, `eta_is`。
枝ごとに `mode_e` / `mode_ch` を `flow` または `capacity` に設定します。`value_*` の単位はモードで変わります。
両枝の蒸発圧力は共通です。片枝をゼロにすると、その枝の冷却能力はゼロとなり、合流計算から除外されます。その枝の状態表は仮想的な指定状態として `active=0` を付けます。停止中の実際の滞留冷媒状態は表しません。両枝ゼロは停止運転の対象外としてエラーにします。

### 条件の一括比較

```scilab
exec("C:/ac_model/run_sweep.sce", -1);
```

高負荷の流量を固定し、凝縮温度40～65℃を5℃刻みで比較します。`results/condensing_temperature_sweep.csv` に保存します。外気温を変えた結果を予測する計算ではありません。

## 4. Xcosの操作

`start.sce` のほか、次の2行でもモデルを作成できます。

```scilab
exec("C:/ac_model/loader.sce", -1);
exec(AC_ROOT+"build_xcos.sce", -1);
xcos(scs_m);
```

接続は `CONST_m → scifunc_block_m → TOWS_c`。CLOCK_cは結果記録用です。機器ごとの計算は `src/ac_core.sci` 内にまとめ、回路全体の収支を一括して扱っています。ブロックの線は数値信号であり、配管そのものではありません。

左の定数ブロックをダブルクリックし、9要素の列ベクトルを変更します。

```scilab
[Te_C; Tc_C; SH_e_K; SH_ch_K; SC_K; eta_is; mode; a; b]
```

| mode | a | b | 入力例 |
|---:|---|---|---|
| 1 | 車室流量 kg/h | チラー流量 kg/h | `[5;50;5;5;5;0.7;1;150;100]` |
| 2 | 車室能力 kW | チラー能力 kW | `[5;50;5;5;5;0.7;2;5;3]` |
| 3 | 車室能力 kW | チラー流量 kg/h | `[5;50;5;5;5;0.7;3;5;100]` |

シミュレーションを実行すると、Scilabに `AC_LOG.time` と `AC_LOG.values` が作成されます。valuesの各行が1サンプル、12列が以下の出力です。

1. 低圧 MPaA
2. 高圧 MPaA
3. 車室流量 kg/h
4. チラー流量 kg/h
5. 全体流量 kg/h
6. 車室冷却能力 kW
7. チラー冷却能力 kW
8. 冷媒への圧縮仕事率 kW
9. 必要コンデンサ放熱量 kW
10. 吐出温度 ℃
11. 膨張弁出口乾き度（両枝共通）
12. 冷媒サイクルCOP（車室＋チラーの能力／冷媒への圧縮仕事率）

確認例：

```scilab
disp(ac_summary_names());
disp(AC_LOG.values($,:));
```

Xcosの「名前を付けて保存」で `.zcos` として保存できます。別セッションで再度開く場合は先に `loader.sce` を実行してください。生成スクリプトも同梱しているので、保存形式に依存せず再作成できます。

テキスト形式のモデル `ac_steady.cosf` も同梱しています。既存モデルを読み込む場合は、loader実行後に `loadXcosLibs(); loadScicos(); exec(AC_ROOT+"ac_steady.cosf",-1); xcos(scs_m);` と実行できます。

**初期版には蓄積や時定数がありません。** Xcosの時間軸は記録用で、入力変更時は新しい定常状態に即座に切り替わります。車室温度・冷媒圧力の物理的な時間応答ではありません。

コンソールだけで動かす場合は `run_xcos_batch.sce` を実行します。Xcosで入力を編集した後の詳細状態表は、同じベクトルを `c` に設定して `ac_cycle(c)` で出力します。

## 5. モデルの式・境界

- R1234yfの飽和温度から高圧・低圧を計算し、過熱度・過冷却度で各出口状態を定義。
- 膨張弁：`h_out = h_in`。弁開度・流量係数は初期版では扱わず、枝流量または要求能力を指定。
- 蒸発器：`Q = m*(h_out-h_in)`。逆計算は `m = Q/(h_out-h_in)`。
- 分岐前は同じ液状態。合流後の `h` は質量流量による加重平均。
- 圧縮機：`h2 = h1 + (h2s-h1)/eta_is`、`s2s=s1`。
- コンデンサ：`Qcond = m_total*(h2-h3)`。その値が `Qe+Qch+W` と一致するか確認。
- 圧力はすべて絶対圧。内部はPa・K・J/kg・kg/s・W、表示時に換算。
- 乾き度は気相の質量割合。液単相・蒸気単相のCSVでは空欄。体積分率ではない。

初期版は亜臨界、正流量、配管・熱交換器の圧力損失なし、外部配管の熱授受なし、断熱圧縮、二相または飽和液の膨張弁出口を対象とします。共通蒸発圧力、完全混合を仮定します。機器の流量上限、圧縮機回転数、弁開度、空気／冷却液側性能、冷媒充填量、内部位置分布、起動停止、霜付き、制御応答は未実装です。

必要放熱量は設計上の要求値で、コンデンサが達成できる能力ではありません。冷房能力は冷媒側の吸熱量で、実際の吹出温度・除湿量・チラー冷却液温度を決めるには二次側データが必要です。電力・システムCOPにはモータ、インバータ、ファン、ポンプの損失が別途必要です。

## 6. エラー時

- `CoolProp library not found`：DLLの保存先と名前を確認。
- `link`で失敗：Windows x64版を使用しているか確認。`CoolProp.dll`の依存DLLが不足している場合は、それも解消してください。
- `propssi_ is already linked outside this package`：Scilabを再起動し、このパッケージのloaderから読み込み。
- `Undefined variable: ac_xcos_eval`：そのセッションで `loader.sce` を実行。
- 温度・効率・流量エラー：表示された入力条件を修正。物性範囲外を外挿したり、数値を黙って丸めたりはしません。
- 同じファイル名の結果CSVは再実行で更新されます。比較ケースを残す場合は `ac_export` のstemを変えてください。

## 7. 検証と出典

検証結果の詳細は `VALIDATION_JA.md`。同梱CSVは仮定に基づくモデル出力で、実測データではありません。

- ユーザー提供 `log.pdf`：pp.3–7の流量・基準条件、pp.8–11のモデル目的を参照。
- [CoolProp Scilab連携](https://coolprop.org/coolprop/wrappers/Scilab/index.html)
- [CoolProp v8.0.0 公式Scilabサンプル](https://github.com/CoolProp/CoolProp/blob/v8.0.0/Web/coolprop/wrappers/Scilab/sample.sce)
- [CoolProp物性API](https://coolprop.org/coolprop/HighLevelAPI.html)
- [Scilab 2026.1.0 関数ブロック](https://help.scilab.org/docs/2026.1.0/en_US/scifunc_block_m.html)
- [Scilab 2026.1.0 バッチシミュレーション](https://help.scilab.org/docs/2026.1.0/en_US/scicos_simulate.html)

## 8. ファイル構成

| ファイル | 用途 |
|---|---|
| `loader.sce` | 関数と物性ライブラリの読込 |
| `selftest.sce` | 計算・Xcosの動作確認 |
| `start.sce` | サンプル計算、図、Xcosを開く |
| `run_examples.sce` | 4ケースの計算・CSV出力 |
| `run_sweep.sce` | 凝縮温度の条件比較 |
| `build_xcos.sce` | Xcosモデルの生成 |
| `ac_steady.cosf` | テキスト形式のXcosモデル |
| `run_xcos_batch.sce` | Xcosモデルをコンソールから実行 |
| `src/ac_core.sci` | 物性接続・サイクル計算・出力 |
| `src/ac_plot.sci` | Scilabでのp–h線図 |
| `results/` | 基準計算と条件比較のCSV |
| `tests/test_core.sce` | 数値・例外処理の試験 |
| `VALIDATION_JA.md` | 検証済み範囲と未確認範囲 |
