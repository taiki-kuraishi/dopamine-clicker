# AGENTS.md

## GDScript

- class・signal・const・var・関数（private を含む）すべてに、日本語の doc comment（`##`）を付ける。関数には引数・戻り値・`null` を返す条件・emit する signal を書く
- 変数・引数・戻り値・ループ変数は明示の型アノテーションで書く（`:=` の推論も使わない）。Godot project ごとに `project.godot` で GDScript の `untyped_declaration`・`inferred_declaration`・`unsafe_*` の warning を error にし、`directory_rules` で自分のコード（`res://addons/dopamine_core` と `res://test`）には効かせ、vendoring した `res://addons/gdUnit4` には効かせない
- 複数の段を持つ関数は、処理の塊ごとに空行で区切り、各塊の先頭に何をしているかを日本語のコメントで書く

## テスト

- テスト関数の上に、何を確かめるテストかを日本語の doc comment（`##`）で書く
- headless では InputEvent が配送されない。UI のテストは InputEvent を送らず、signal を emit するかメソッドを直接呼んで検証する
- GdUnit4 の exit code 101（警告。orphan node を含む）も失敗として扱い、0 になるまで直す
