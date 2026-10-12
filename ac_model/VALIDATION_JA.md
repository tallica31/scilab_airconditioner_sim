# 検証結果 — 2026-10-12

## 検証済み範囲

実行環境は **Debian 13 / Scilab 2024.1.0 / CoolProp 8.0.0共有ライブラリ**です。
利用者の対象環境は Windows 11 x64 / Scilab 2026.1.0 ですが、この環境そのもので実行した結果ではありません。

CoolPropは公開ソースからLinux共有ライブラリを構築し、実際に `propssi_` を `link` / `call` で呼びました。補助照合には別途Python版CoolProp 8.0.0を使用しました。Pythonは配布モデルの実行には不要です。

| 試験 | 結果 |
|---|---|
| Scilab関数の読込・構文・共有ライブラリ呼出し | PASS |
| PDFの低負荷・高負荷の圧力、能力、圧縮仕事、放熱量との照合 | 丸め誤差の範囲で一致 |
| 順計算の能力を逆計算へ渡し、元の枝流量を復元 | PASS |
| 車室能力5 kW・チラー流量100 kg/hの混合指定 | PASS |
| 両枝で過熱度が異なる場合の合流エンタルピー | PASS |
| 一方の枝が流量ゼロの場合の混合・能力 | PASS |
| 過熱度0 K、過冷却度0 Kの飽和境界 | PASS |
| 凝縮温度上昇時の高圧・冷却能力の変化 | PASS |
| 両枝ゼロ、効率0、効率1超、負流量、温度逆転、臨界温度超過、NaN、不明モードの拒否 | PASS |
| Xcosモデルの生成と低負荷の全出力サンプル照合 | PASS |
| Xcos逆計算で5 kW・3 kWの要求能力を満足 | PASS |
| Xcos混合指定で5 kW・100 kg/hを満足 | PASS |
| `.cosf`の書出し・読込・実物性によるシミュレーション | PASS |
| 4ケースの入力・状態・サマリーCSV出力 | PASS |
| 凝縮温度40～65℃の6ケース比較CSV | PASS |
| 4ケース計48状態点をPython版CoolPropのP,H物性計算と照合 | PASS |

4基準ケースの質量収支残差は1e-14 kg/s未満、エネルギー収支残差の最大絶対値は **5.002e-12 W**でした。
CSVを読み戻してPython版と照合した際の温度差最大値は **3.938e-8 K**、密度の相対差最大値は **5.199e-10**でした。
これらは数値実装と物性呼出しの整合性を示すもので、実機に対する予測誤差を示す値ではありません。

Scilab 2026.1.0公式ソースの `scifunc_block_m.sci`, `CONST_m.sci`, `TOWS_c.sci`, `scicos_link.sci` は、今回試験した2024.1.0環境の対応ファイルと内容が一致することを確認しました。ただし、これだけでWindows版全体の動作を保証するものではありません。

## この環境で未確認の範囲

- Windows 11上でのCoolProp.dllの依存関係・読込。
- Scilab 2026.1.0そのものの実行。
- XcosエディタのGUI表示・マウス操作・`.zcos`保存。
- Scilabグラフィックスによるp–h線図の描画。
- 実機の性能との一致。部品性能マップ・実測による同定は未実施。

上記のため、導入後は最初に `selftest.sce` を実行してください。GUIについては続いて `start.sce` で確認できます。

## 再現

```scilab
exec("C:/ac_model/selftest.sce", -1);
exec("C:/ac_model/run_examples.sce", -1);
exec("C:/ac_model/run_sweep.sce", -1);
```

試験コードは `tests/test_core.sce` と `selftest.sce` に同梱しています。
実行ログは `validation/validation_log.txt` に保存しました。ログのローカルパスだけを `<package>/` に置き換えています。
