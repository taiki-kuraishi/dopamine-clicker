# core

ドーパミンの状態（残高・累計獲得）と、そのセーブ文字列への変換を持つ Godot project。

## 責務

- 実装すること: ドーパミンの状態と増減のルール（クリックでの獲得など）、状態とセーブ文字列（version 付き JSON）の相互変換
- 実装しないこと: 画面・入力・シーン、`user://` などへのファイルの読み書き、backend との通信

## 構成

- `addons/dopamine_core/`: core のコード。ゲーム側からは `addons/dopamine_core` の symlink で参照する
- `addons/gdUnit4/`: テストフレームワーク GdUnit4 v6.2.2 の vendoring。[リリースの source](https://github.com/godot-gdunit-labs/gdUnit4/releases/tag/v6.2.2) の `addons/gdUnit4` に、`godot --import` が生成した `*.uid`・`*.import` を加えたもの
- `test/`: GdUnit4 のテスト（`*_test.gd`）

## テスト

repo root で実行する。

```sh
mise run test:core
```

`godot --headless --path packages/core --import` でスクリプトの class を登録してから、GdUnit4 の CLI で `test/` を実行する。結果は `reports/` に出る。
