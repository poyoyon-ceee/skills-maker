# マーケティング用スキル（オプトイン）

日常の `skills-pack/` には含まれない。通常の `install.ps1` では入らない・戻らない。

## いつ使うか

商品ローンチ、LP・広告・スライドのトンマナ統一、訴求コピー制作など、マーケ制作が必要なときだけ。

## 中身（47件）

| 種類 | 件数 | 例 |
|------|------|-----|
| marketingskills | 46 | `copywriting`, `ads`, `cro`, `seo-audit` |
| playbook | 1 | `playbook-lp-creative`（入口） |

全件 `MANIFEST.json` 参照。いずれも当面 **手動のみ**（`disable-model-invocation: true`）。

## 運用ポリシー

1. **デフォルト非インストール** — 日常パック更新では入らない
2. **入れる先** — `~/.cursor/skills/` のみ
3. **置かない** — `~/.agents/skills/`、原則 `~/.claude/skills/`（Cursor の二重カタログ防止）
4. **入口** — `/playbook-lp-creative` → 必要に応じて個別 marketing スキル
5. **自動発火** — 最初は手動のまま。常用が固まってからコア数件だけ検討（一括自動はしない）
6. **前提スキル（日常パック側）** — `frontend-design`, `canvas-design`, `theme-factory`, `pptx` が先に入っていること

## インストール（Windows）

```powershell
cd C:\path\to\skills-maker\skills-pack-marketing
.\install.ps1
```

Cursor を再起動し、Customize → Skills で `/playbook-lp-creative` を確認。

## インストール（macOS / Linux）

```bash
cd /path/to/skills-maker/skills-pack-marketing
chmod +x install.sh
./install.sh
```

## アンインストールの目安

`~/.cursor/skills/marketingskills/` と `~/.cursor/skills/playbooks/playbook-lp-creative/` を削除。  
誤って `~/.agents` / `~/.claude` にコピーした場合はそちらも同名を削除。

## 日常パックとの関係

| パック | 役割 |
|--------|------|
| `skills-pack/` | 日常開発・ドキュメント・Obsidian 等 |
| `skills-pack-marketing/`（本フォルダ） | マーケ制作オプトイン |

上位の [SETUP.md](../SETUP.md) / [skills一覧.md](../skills一覧.md) も参照。
