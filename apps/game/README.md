# game

dopamine-clicker のゲーム本体の Godot project。単色の背景の中央に 2D のスマホを置き、その画面の縦スクロールのカードをクリックさせる。PC 向け。

## 責務

- 実装すること: ゲーム画面（1280×720 の背景・スマホ・カードのフィード・残高のバッジ・アップグレード欄の点線の枠）、フィードの送り（上下のドラッグ・ホイール・上下キーで 1 枚ずつ、前にも戻れる）、カードのクリックの通知、残高と獲得の演出の表示、ゲーム全体で 1 つのゲームの状態（Autoload `Game`）とゲームの窓口、ローカルの窓口でのセーブ／ロード（`user://save.json`。ウィンドウを閉じたときと、最後の保存から 10 秒以上たったあとのクリックで保存する）
- 実装しないこと: ドーパミンの状態と増減のルール・セーブ文字列の形式（core が持つ）、アップグレードの購入、backend・MCP との通信、本物の動画、mobile・タッチの操作

## 構成

- `scenes/`: ゲーム画面のシーンと、それを組み立てる script。main scene は `scenes/main.tscn`（ゲーム画面 `scenes/game_screen.tscn` を子に置き、Autoload の `Game` につなぐだけの薄い scene）。`scenes/game_screen.tscn` は単体でも開ける
- `state/`: ゲームの状態と窓口。`game_state.gd` はゲーム全体で 1 つの状態（Autoload `Game`）で、窓口の結果を signal で画面に知らせる。`game_gateway.gd` は窓口の基底（非同期の `start`・`click`・`finish`）、`local_game_gateway.gd` は core の状態を中で動かしてセーブを読み書きするローカルの窓口
- `addons/dopamine_core/`: `packages/core/addons/dopamine_core` への相対 symlink
- `addons/gdUnit4/`: `packages/core/addons/gdUnit4` への相対 symlink
- `test/`: GdUnit4 のテスト（`*_test.gd`）と、テスト用の窓口（`deferred_game_gateway.gd`）

## テスト

repo root で実行する。

```sh
mise run test:game
```

`godot --headless --path apps/game --import` でスクリプトの class を登録してから、GdUnit4 の CLI で `test/` を実行する。結果は `reports/` に出る。
