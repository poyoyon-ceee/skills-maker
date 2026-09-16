# model-router-gptの委任方法

この補足はsubagentを起動するときだけ読む。モデル名とツールschemaは、そのセッションで公開された値を優先する。

## 現在のDesktop / collaboration

2026-09-16 のローカルCodex `0.154.0-alpha.6.2` では `collaboration.spawn_agent` に `model`, `fork_turns`, `task_name`, `message` が公開され、SolからLuna/Terraへの起動を利用できる。現在の形は以下。ツール引数はJSONとして渡す。

```json
{
  "task_name": "extract_candidates",
  "fork_turns": "none",
  "model": "gpt-5.6-luna",
  "message": "目的・候補・許可範囲・根拠付き返却形式を明示した小さな依頼"
}
```

Terraでは `model: "gpt-5.6-terra"` と別のtask名を使う。Solの通常最終判断は親で行う。

- `fork_turns: "all"`/省略は全履歴継承になり、この環境ではmodel overrideも受け付けない。`"none"` で必要情報をmessageへ明示する。履歴を引き継がなくてもruntimeの共通指示・Skillsが供給される場合があるため「完全にcontextゼロ」とは言わない。
- モデル指定はユーザーまたは適用Skillによる許可が必要なruntimeがある。このSkillの担当分担はLuna/Terraの明示選択を指示する。上位の制約がある場合は従い、無理にoverrideしない。
- `reasoning_effort` は必要な場合だけ、そのモデルが実際にサポートする値を使う。モデルを明示しreasoningを省く場合、このローカル版では指定モデルの既定reasoningが使われる。
- collaborationツールは直接呼ぶ。この環境では `functions.exec` の `tools.*` にないため、JavaScriptから呼び出す関数を創作しない。
- 起動後は結果を待って受け取り、重要原文を親が確認する。進捗説明のための頻繁なpollingは避ける。継続が必要なら公開された `send_message` / `followup_task` / `wait_agent` を使う。
- 子は同じファイルシステムを共有する。「読み取り専用」の依頼は指示であり専用sandboxの保証ではない。元ファイルを変えないPoCでは、実際のsandboxと前後のhashで確認する。

## 別のCodex runtime

`spawn_agent` のschemaに直接 `model` があるなら、その実際のschemaでモデルを指定する。`fork_context: false` 等が本当に公開されていれば履歴継承を避ける。現在のDesktop用引数を別schemaへ流用しない。

role/`agent_type` だけが公開されている場合は、**既に設定された**roleの `model` を確認し、Luna/Terraに対応するroleがある場合だけ使う。公式の `agents.<name>.config_file` はrole用TOMLを指定できるが、このSkillを使うだけでrole設定やglobal configを新設しない。

明示モデルも確認済みroleも使えなければ、モデル間委任はそのセッションでは未対応とReportに記す。通常ツールで候補をさらに絞り、親は必要な原文だけ読む。新しいユーザーtask、別CLI、API課金サービスを暗黙に起動して不足を補わない。

## 標準機能での確認

- ツールの起動・完了履歴で、指定モデル、子の識別子、処理結果を確認する。
- 利用可能な標準UIやapp-server `thread/read` で子の設定モデルを確認できる場合は使用する。ただしAPIの `model` フィールドは設定/最新保存モデルであり、per-turn実行telemetryではない。確認できないものを成功と表示しない。
- subagentが完了した事実と、依頼した全ファイルを検査した事実は別。出力の確認件数・未読を照合する。
- Reportのために毎回履歴全文を読む、私的な全taskを列挙する、認証ファイルを読む、独自監視ログを作ることは不要。
- `codex --version` / `codex features list` は起動したOSユーザーの設定を読む。Windows sandbox用アカウントは実ユーザーとhomeが異なるため、その値をユーザー本環境の値と取り違えない。

## 公式根拠

- [Build skills](https://learn.chatgpt.com/docs/build-skills): User root `~/.agents/skills`、descriptionによる暗黙選択、`agents/openai.yaml`。
- [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents): 明示モデル指定、既定継承、Skill/project指示による委任。
- [Config reference](https://learn.chatgpt.com/docs/config-file/config-reference): `agents.<name>.config_file` 等。存在確認なしに設定を追加しない。

対応状況は変わり得る。ローカル版と公開ツールに合わない場合だけ公式仕様を再確認する。
