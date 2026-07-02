# スキル重複処理（別PC・元PC向け）

**人間のヒデさん向け:** このファイルを Cursor のエージェントに見せて、下の「コピペ用の一言」をそのまま送るだけでOK。

**エージェント向け:** ユーザーがコードを書けない前提。このファイルの手順を**全部自分で実行**すること。説明だけで終わらせない。

---

## いつ使うか

- `install.ps1` 実行後、`/writing-plans` などが **2件ずつ** 出る
- 過去の手動コピーや旧インストールの残骸が `~/.cursor/skills/` に残っている
- **プロジェクト内の `skills/` フォルダが原因ではない**（Cursor は `.cursor/skills/` を読む。skills-maker の `skills/` は配布用正本）

---

## コピペ用の一言（これをそのまま送る）

```
@skills-pack/skills重複処理.md に書いてある手順どおりに、このPCの ~/.cursor/skills/ の重複スキルを整理して。中身が同じものは削除、内容が違うものは skills-pack 版を残す。最後に確認結果を教えて。
```

フォルダを添付できないとき:

```
skills-maker リポジトリの skills-pack/skills重複処理.md に従って、グローバルスキルの重複を整理して。
```

---

## エージェント実行手順（必ずこの順番）

### 1. 前提確認

- スキル置き場: `%USERPROFILE%\.cursor\skills\`（Windows）/ `~/.cursor/skills/`（Mac/Linux）
- **正本は skills-maker の `skills-pack/` フォルダ**（`install.ps1` がコピーする内容）
- 先に `install.ps1` を実行済みであることが望ましい（未実行なら [引き継ぎ.md](引き継ぎ.md) の手順3を先に実行）

### 2. 重複を検出（エージェントが実行）

**Windows（PowerShell）:**

```powershell
$skillsRoot = "$env:USERPROFILE\.cursor\skills"

function Get-SkillName($path) {
  $head = Get-Content $path -TotalCount 10 -Encoding UTF8
  foreach ($line in $head) {
    if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
  }
  return $null
}

$byName = @{}
Get-ChildItem $skillsRoot -Recurse -Filter "SKILL.md" | ForEach-Object {
  $name = Get-SkillName $_.FullName
  if (-not $name) { return }
  if (-not $byName.ContainsKey($name)) { $byName[$name] = @() }
  $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
  $byName[$name] += [PSCustomObject]@{
    Rel  = $_.FullName.Substring($skillsRoot.Length + 1)
    Hash = $hash
  }
}

Write-Host "=== Duplicate skill names ==="
foreach ($name in ($byName.Keys | Sort-Object)) {
  $items = $byName[$name]
  if ($items.Count -le 1) { continue }
  Write-Host "`n[$name] ($($items.Count) copies)"
  $items | Group-Object Hash | ForEach-Object {
    Write-Host "  Hash $($_.Name.Substring(0,8))... ($($_.Count) files)"
    $_.Group | ForEach-Object { Write-Host "    $($_.Rel)" }
  }
}
```

重複が0件なら **手順5へ**（報告のみ）。

### 3. 中身が同じものを削除（エージェントが実行）

**削除してよいパターン（正本は左・skills-maker 版）:**

| 削除するパス | 残す正本 |
|-------------|----------|
| `writing-plans\writing-plans\` | `writing-plans\SKILL.md` |
| `grill-me\grill-me\` | `grill-me\SKILL.md` |
| `webapp-testing\webapp-testing\` | `webapp-testing\SKILL.md` |
| `debug\debug\` | `debug\debug-allrun\` |
| `github\github\` | `github\github-make-sync\` |
| `git-in-clone\`（トップレベル） | `github\git-in-clone\` ※下記参照 |

`git-in-clone` の注意: `github\git-in-clone\` が無く `github\github\git-in-clone\` だけある場合は、**先に移動**してから `github\github\` とトップレベル `git-in-clone\` を削除する。

**Windows（PowerShell）一括削除:**

```powershell
$root = "$env:USERPROFILE\.cursor\skills"

# git-in-clone を正しい場所へ（必要な場合のみ）
$srcGit = Join-Path $root "github\github\git-in-clone"
$dstGit = Join-Path $root "github\git-in-clone"
if ((Test-Path $srcGit) -and -not (Test-Path $dstGit)) {
  Move-Item $srcGit $dstGit
  Write-Host "Moved: github\github\git-in-clone -> github\git-in-clone"
}

$toRemove = @(
  "writing-plans\writing-plans",
  "grill-me\grill-me",
  "webapp-testing\webapp-testing",
  "debug\debug",
  "github\github",
  "git-in-clone"
)

foreach ($rel in $toRemove) {
  $path = Join-Path $root $rel
  if (Test-Path $path) {
    Remove-Item $path -Recurse -Force
    Write-Host "Deleted: $rel"
  }
}
```

### 4. 中身が違うものは skills-maker 版を残す（エージェントが実行）

ハッシュが異なる重複が残っていたら、次を適用する。

| 削除するパス | 残す skills-maker 版 |
|-------------|---------------------|
| `test-driven-development\test-driven-development\` | `test-driven-development\SKILL.md`（+ `testing-anti-patterns.md`） |
| `brainstorming\brainstorming\` | `superpowers\brainstorming\` |

**触らないもの（skills-maker に無い別スキル）:**

- `brainstorming\brainstorming-devils\`
- `brainstorming\brainstorming-persona\`

```powershell
$root = "$env:USERPROFILE\.cursor\skills"
foreach ($rel in @(
  "test-driven-development\test-driven-development",
  "brainstorming\brainstorming"
)) {
  $path = Join-Path $root $rel
  if (Test-Path $path) {
    Remove-Item $path -Recurse -Force
    Write-Host "Deleted: $rel"
  }
}
```

### 5. 完了確認（エージェントが実行して報告）

```powershell
$skillsRoot = "$env:USERPROFILE\.cursor\skills"
function Get-SkillName($path) {
  $head = Get-Content $path -TotalCount 10 -Encoding UTF8
  foreach ($line in $head) {
    if ($line -match '^name:\s*(.+)$') { return $Matches[1].Trim() }
  }
  return $null
}
$byName = @{}
Get-ChildItem $skillsRoot -Recurse -Filter "SKILL.md" | ForEach-Object {
  $n = Get-SkillName $_.FullName
  if (-not $byName[$n]) { $byName[$n] = 0 }
  $byName[$n]++
}
$dupes = $byName.GetEnumerator() | Where-Object { $_.Value -gt 1 }
if ($dupes) {
  Write-Host "NG: duplicate skill names remain:"
  $dupes | ForEach-Object { Write-Host "  $($_.Name): $($_.Value)" }
} else {
  Write-Host "OK: no duplicate skill names."
}
```

### 6. ユーザーへの報告（日本語・やさしく）

次を必ず伝える:

1. **重複処理が完了した**
2. **Cursor を一度終了して起動し直す**
3. **Customize → Skills** で `/writing-plans` などが **1件ずつ** になるか確認
4. 削除したフォルダ一覧と、保留したもの（devils / persona など）があればその旨

---

## 原因（参考）

`install.ps1` はフォルダを上書きコピーするが、**古いネスト構造**（例: `writing-plans\writing-plans\`）は自動では消えない。新旧が共存すると Cursor が同じ `name:` のスキルを2回登録する。

---

## やってはいけないこと

- `~/.cursor/skills-cursor/` を触る（Cursor 組み込み用）
- 中身を比較せずにフォルダごと全削除する
- `superpowers\` 以下を丸ごと消す
- 重複0件の報告を、確認コマンドなしで行う

---

## 関連ドキュメント

- 初回セットアップ: [引き継ぎ.md](引き継ぎ.md)
- インストール詳細: [INSTALL.md](INSTALL.md)
- スキル一覧: [../skills一覧.md](../skills一覧.md)
