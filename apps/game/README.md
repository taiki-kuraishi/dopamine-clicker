# game

dopamine-clicker のゲーム本体の Godot project。単色の背景の中央に 2D のスマホを置き、その画面の縦スクロールのカードをクリックさせる。PC 向け。

## 責務

- 実装すること: ゲーム画面（1280×720 の背景・スマホ・カードのフィード・残高のバッジ・アップグレード欄の点線の枠）、フィードの送り（上下のドラッグ・ホイール・上下キーで 1 枚ずつ、前にも戻れる）、カードのクリックの通知、残高と獲得の演出の表示
- 実装しないこと: ドーパミンの状態と増減のルール（core が持つ）、アップグレードの購入、セーブ／ロード、backend・MCP との通信、本物の動画、mobile・タッチの操作

## 構成

- `scenes/`: ゲーム画面のシーンと、それを組み立てる script。main scene は `scenes/game_screen.tscn`
- `addons/dopamine_core/`: `packages/core/addons/dopamine_core` への相対 symlink
- `addons/gdUnit4/`: `packages/core/addons/gdUnit4` への相対 symlink
- `test/`: GdUnit4 のテスト（`*_test.gd`）

## テスト

repo root で実行する。

```sh
mise run test:game
```

`godot --headless --path apps/game --import` でスクリプトの class を登録してから、GdUnit4 の CLI で `test/` を実行する。結果は `reports/` に出る。
