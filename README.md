# Scilab / Xcos 自動車用冷媒回路モデル

R1234yfを使用し、車室用エバポレータとチラーを並列接続した定常冷凍サイクルのモデルです。
対象環境は **Windows 11 x64 / Scilab 2026.1.0 / CoolProp 8.0.0 x64** です。

- [配布ZIPをダウンロード](https://github.com/tallica31/scilab_airconditioner_sim/raw/refs/heads/main/downloads/ac_model_v0.1.zip)
- [日本語の導入・操作手順](ac_model/README_JA.md)
- [検証結果と未確認範囲](ac_model/VALIDATION_JA.md)
- [基準ケースと条件比較のCSV](ac_model/results/)

## できること

- 各分岐の冷媒流量から、冷却能力・圧縮仕事・必要放熱量を計算。
- 要求冷却能力から、必要な冷媒循環流量を逆算。
- 車室の要求能力とチラー流量を組み合わせた混合指定。
- 各部の温度、絶対圧力、比エンタルピー、密度、相、乾き度をCSVに保存。
- 蒸発温度・凝縮温度・過熱度・過冷却度などの条件比較。
- Xcosモデルの実行とScilabによるp–h線図の作図。

## 最初の実行

1. ZIP内の `ac_model` フォルダを、例として `C:/ac_model/` に展開します。
2. [CoolProp公式配布先](https://sourceforge.net/projects/coolprop/files/CoolProp/8.0.0/shared_library/Windows/64bit/)から `CoolProp.dll` を取得し、`C:/ac_model/lib/CoolProp.dll` に保存します。DLLはこのリポジトリと配布ZIPには含めていません。
3. Scilabコンソールで動作確認し、サンプルとXcosを開きます。

```scilab
exec("C:/ac_model/selftest.sce", -1);
exec("C:/ac_model/start.sce", -1);
```

Gitでcloneした場合は、上記のパスをclone先の `ac_model/` に置き換えてください。PythonやC/C++コンパイラは利用者側では不要です。

## 基準ケース

蒸発5℃、凝縮50℃、両枝の過熱度5 K、過冷却度5 K、等エントロピー効率70%を指定しています。

| 出力 | チラー低負荷 | チラー高負荷 |
|---|---:|---:|
| 車室側流量 | 150 kg/h | 150 kg/h |
| チラー流量 | 100 kg/h | 250 kg/h |
| 車室冷却能力 | 4.544 kW | 4.544 kW |
| チラー冷却能力 | 3.029 kW | 7.574 kW |
| 必要コンデンサ放熱量 | 9.836 kW | 15.738 kW |

これらは指定した状態条件での計算結果です。実機がその運転点を達成できるかの判定には、部品性能特性が別途必要です。外気温・風量からの圧力予測、冷媒充填量、起動停止・時間応答は初期版の対象外です。

## 検証状況

Linux / Scilab 2024.1.0 / CoolProp 8.0.0で、基準値・逆算・混合・境界条件・入力エラーとXcosの3モードを検証済みです。
**Windows 11 / Scilab 2026.1.0そのものとGUI表示は未確認**です。導入時は `selftest.sce` で確認してください。

ZIPのSHA-256は [downloads/SHA256SUMS](downloads/SHA256SUMS) に記録しています。
