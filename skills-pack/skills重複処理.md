# スキル重複処理（別PC・元PC向け）

**人間のヒデさん向け:** このファイルを Cursor のエージェントに見せて、下の「コピペ用の一言」をそのまま送るだけでOK。

**エージェント向け:** ユーザーがコードを書けない前提。このファイルの手順を**全部自分で実行**すること。説明だけで終わらせない。

---

## いつ使うか

- **設定画面の Skills 件数と `/` メニューの件数が合わない**
- `/writing-plans` `/git-in-clone` などが **2件ずつ** 出る
- `~/.agents/skills` のスキルを編集したのに反映されない（`~/.cursor/skills` 側が読まれている）
- 過去の手動コピーや旧インストールの残骸が残っている

## 原因（先に理解する）

Cursor は次を**全部**読み、`~/.cursor/skills-cursor/`（組み込み）も加える。

| root | 読むツール | 備考 |
|------|-----------|------|
| `~/.agents/skills/` | Cursor / Codex / ChatGPT 系 | **正本。ここに寄せる** |
| `~/.cursor/skills/` | Cursor のみ | Cursor 固有スキルだけ |
| `~/.claude/skills/` | Claude Code（＋Cursor が取り込むことがある） | 消さない |
| `~/.cursor/skills-cursor/` | Cursor 組み込み | **触らない** |

そして:

1. **設定画面は名前で重複排除するが、`/` メニューはしない。** だから件数がズレ、`/` 側だけ同じスキルが2回出る
2. **同名が複数 root にあると、片方だけが実際に使われる。** 観測では `~/.agents` が勝つ。`~/.cursor` 側を編集しても効かない事故が起きる

### ⚠️ Include Third-Party トグルでは直らない

Settings → Rules, Skills, Subagents → **Include Third-Party Plugins, Skills, and Other Configs** を OFF にしても **`~/.agents/skills` は読まれ続ける**。

あのトグルの対象は `~/.claude/skills`・`CLAUDE.md`・Copilot 設定など「よそのベンダー固有の設定」。`~/.agents/` は `AGENTS.md` と同じベンダー中立の共通標準なので、Cursor はネイティブな探索先として扱う。

**`~/.claude` 由来の重複にはトグルが効く。`~/.agents` 由来には効かない。** 後者は下の手順でフォルダを整理するしかない。

---

## 対象は `~/.agents/skills` と `~/.cursor/skills` の2つ

**`~/.claude/skills/` にはこの手順を適用しない。** Claude Code 側の重複・残骸は `install-claude.ps1` を再実行すれば解消する（除外スキルの削除・オーバーレイ適用・Superpowers プラグインの `enabledPlugins` を false にする処理も内蔵。詳細は [INSTALL.md](INSTALL.md)）。

---

## コピペ用の一言（これをそのまま送る）

```
@skills-pack/skills重複処理.md に書いてある手順どおりに、このPCのグローバルスキルの重複を整理して。~/.agents/skills を正本、Cursor固有3つだけ ~/.cursor/skills に残す構成にして。削除ではなく skills.bak へ退避して。最後に確認結果を教えて。
```

フォルダを添付できないとき:

```
skills-maker リポジトリの skills-pack/skills重複処理.md に従って、グローバルスキルの重複を整理して。
```

---

## エージェント実行手順（必ずこの順番）

### 1. 前提確認

- 正本は skills-maker の `skills-pack/` フォルダ（`install.ps1` がコピーする内容）
- 目標の構成:

| root | 中身 |
|------|------|
| `~/.agents/skills/<スキル名>/` | 通常スキル全部（平置き・カテゴリフォルダなし） |
| `~/.cursor/skills/<スキル名>/` | `chat-handoff` / `skill-creator` / `promote-skill` の3つだけ |
| `~/.cursor/skills.bak/` | 退避先（削除しない） |

### 2. まず install.ps1 を試す（これで大半は片付く）

```powershell
cd <skills-maker のパス>\skills-pack
.\install.ps1
```

`install.ps1` は次を自動でやる:

- pack の内容を正しい root へ配置（Cursor 固有3件だけ `~/.cursor`）
- `~/.cursor/skills/` に残った移行前のスキルを `~/.cursor/skills.bak/` へ退避
- Cursor 固有3件が `~/.agents/skills/` にあれば削除
- 最後に全 root を走査して同名2件以上がないか検証

**WARNING が出ずに終わったら手順5（報告）へ。** 残った場合だけ手順3〜4。

### 3. 重複を検出（エージェントが実行）

```powershell
$roots = @(
  (Join-Path $env:USERPROFILE ".agents\skills"),
  (Join-Path $env:USERPROFILE ".cursor\skills")
)

function Get-SkillName($path) {
  $head = Get-Content $path -TotalCount 15 -Encoding UTF8
  foreach ($line in $head) {
    if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
  }
  return $null
}

$byName = @{}
foreach ($root in $roots) {
  if (-not (Test-Path $root)) { continue }
  Get-ChildItem $root -Recurse -Filter "SKILL.md" | ForEach-Object {
    $name = Get-SkillName $_.FullName
    if (-not $name) { return }
    if (-not $byName.ContainsKey($name)) { $byName[$name] = @() }
    $byName[$name] += [PSCustomObject]@{
      Full = $_.FullName
      Hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    }
  }
}

Write-Host "=== Duplicate skill names ==="
$found = 0
foreach ($name in ($byName.Keys | Sort-Object)) {
  $items = $byName[$name]
  if ($items.Count -le 1) { continue }
  $found++
  Write-Host "`n[$name] ($($items.Count) copies)"
  $items | ForEach-Object { Write-Host "    $($_.Full)  [$($_.Hash.Substring(0,8))]" }
}
if ($found -eq 0) { Write-Host "OK: no duplicates." }
```

重複が0件なら **手順5へ**（報告のみ）。

### 4. 重複を退避（削除ではなく移動）

**残す側の決め方:**

| スキル | 残す root |
|--------|----------|
| `chat-handoff` / `skill-creator` / `promote-skill` | `~/.cursor/skills/` |
| それ以外すべて | `~/.agents/skills/` |

ハッシュが違う（内容が違う）場合は、**先に差分を確認して新しい方を残す側へコピー**してから退避する。中身を比較せずに消さない。

```powershell
$agents = Join-Path $env:USERPROFILE ".agents\skills"
$cursor = Join-Path $env:USERPROFILE ".cursor\skills"
$bak    = Join-Path $env:USERPROFILE ".cursor\skills.bak"
$cursorOnly = @("chat-handoff", "skill-creator", "promote-skill")

New-Item -ItemType Directory -Force -Path $bak | Out-Null

# ~/.cursor/skills に残っている非Cursor固有スキルを退避
Get-ChildItem $cursor -Directory | ForEach-Object {
  if ($cursorOnly -contains $_.Name) { return }
  if (-not (Get-ChildItem $_.FullName -Recurse -Filter "SKILL.md" -File)) { return }
  $dest = Join-Path $bak $_.Name
  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  Move-Item $_.FullName $dest -Force
  Write-Host "Moved to skills.bak: $($_.Name)"
}

# Cursor固有スキルが ~/.agents にあれば削除（正本は ~/.cursor 側）
foreach ($name in $cursorOnly) {
  $stray = Join-Path $agents $name
  if (Test-Path $stray) {
    Remove-Item $stray -Recurse -Force
    Write-Host "Removed from agents: $name"
  }
}
```

**触らないもの（skills-maker に無い別スキル）:** `brainstorming-devils`、`brainstorming-persona` など。pack に無いスキルは退避対象にしない。

### 5. 完了確認（エージェントが実行して報告）

```powershell
$roots = @(
  (Join-Path $env:USERPROFILE ".agents\skills"),
  (Join-Path $env:USERPROFILE ".cursor\skills")
)
function Get-SkillName($path) {
  $head = Get-Content $path -TotalCount 15 -Encoding UTF8
  foreach ($line in $head) {
    if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
  }
  return $null
}
$names = @()
foreach ($root in $roots) {
  if (-not (Test-Path $root)) { continue }
  Get-ChildItem $root -Recurse -Filter "SKILL.md" | ForEach-Object {
    $n = Get-SkillName $_.FullName
    if ($n) { $names += $n }
  }
}
$dupes = $names | Group-Object | Where-Object { $_.Count -gt 1 }
Write-Host "agents: $((Get-ChildItem (Join-Path $env:USERPROFILE '.agents\skills') -Recurse -Filter SKILL.md).Count)"
Write-Host "cursor: $((Get-ChildItem (Join-Path $env:USERPROFILE '.cursor\skills') -Recurse -Filter SKILL.md).Count)"
if ($dupes) {
  Write-Host "NG: duplicate skill names remain:"
  $dupes | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" }
} else {
  Write-Host "OK: no duplicate skill names."
}
```

期待値: agents **52**、cursor **3**、重複 0。

### 6. ユーザーへの報告（日本語・やさしく）

次を必ず伝える:

1. **重複処理が完了した**
2. **Cursor を一度終了して起動し直す**
3. **設定画面の Skills 件数と `/` メニューの件数が一致するか**確認（ここが一致して初めて解消）
4. 退避したフォルダ一覧（`~/.cursor/skills.bak/`）と、保留したもの（devils / persona など）があればその旨
5. 問題なければ `skills.bak` は後で消してよいが、**すぐには消さない**

---

## やってはいけないこと

- `~/.claude/skills/` を消して重複だけ直そうとする（Claude Code が壊れる）
- `~/.cursor/skills-cursor/` を触る（Cursor 組み込み用）
- **`~/.claude/skills/` にこの手順を適用する**（Claude Code 側は `install-claude.ps1` の再実行で整理する）
- 中身を比較せずにフォルダごと削除する（**退避＝移動**にする）
- **Include Third-Party トグルを OFF にしただけで解決したと報告する**（`~/.agents` には効かない）
- 同じスキルを `~/.agents` と `~/.cursor` の両方に置く
- 重複0件の報告を、確認コマンドなしで行う

---

## 関連ドキュメント

- 初回セットアップ: [引き継ぎ.md](引き継ぎ.md)
- インストール詳細: [INSTALL.md](INSTALL.md)
- スキル一覧: [../skills一覧.md](../skills一覧.md)
