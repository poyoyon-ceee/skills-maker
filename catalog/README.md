# Skills Catalog（System Atlas）

`skills一覧.md` から生成する印刷用カタログの出力先。

## 成果物

| ファイル | 説明 |
|---------|------|
| `skills-catalog-system-atlas.pdf` | A4縦・複数ページカタログ（印刷向け・白背景） |
| `system-atlas-philosophy.md` | デザイン哲学（canvas-design 用） |

## 更新手順

`skills一覧.md` を編集したあと、以下のいずれかを実行する。

### PowerShell（推奨）

```powershell
.\scripts\update-skills-catalog.ps1
```

Excel も同時に更新する場合:

```powershell
.\scripts\update-skills-catalog.ps1 -Excel
```

### Python 直接

```bash
python scripts/generate_skills_catalog_pdf.py
```

## エージェントへの指示例

スキル追加・一覧更新後に PDF を再生成するときは、次の一文で足りる。

> `skills一覧.md` を更新したので、カタログ PDF を同じ形式で再生成して。

エージェントは `scripts/generate_skills_catalog_pdf.py`（または `update-skills-catalog.ps1`）を実行すればよい。

## 入力の前提

- **唯一の入力**: リポジトリ直下の `skills一覧.md`
- 表形式（`| コマンド | 説明 | 使いどころ |`）と `##` / `###` 見出し構造を維持すること
- 参照行（使いどころが `—`）は PDF には含めない
- 取得日は `skills一覧.md` 先頭の `取得日:` 行から自動反映

## 依存

- Python 3 + `reportlab`
- Windows 日本語フォント（Yu Gothic）
- フォント: `skills-pack/canvas-design/canvas-fonts/`

## 書式の変更

フォントサイズ・色・レイアウトは `scripts/generate_skills_catalog_pdf.py` 先頭の `FS` / 色定数で一元管理している。**本文の最小サイズは 10pt**（印刷可読性のため）。
