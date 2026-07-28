# FILE_TEMPLATE_SOURCE（コードのカタログ）

本ドキュメントは、プロジェクト構成ファイルのソースを集約した原典である。AIはヒアリング結果に応じて必要ブロックのみを抽出し、プレースホルダ `{{NAME}}` を置換して書き出せ。

**構成の正**: フロントは **`ui/`**、共通モジュールは **`ui/src/core/`** と **`ui/src/utils/`**、ビルドはルート **`dist/`**、Tauri は **`src-tauri/`**。`MASTER_PROTOCOL_SOURCE` の STRUCTURE と一致させよ。

---

## 📖 【DOCS】PROJECT.md（単一の真実）

### [TEMPLATE: PROJECT.md]

```markdown
# {{APP_NAME}} - プロジェクト概要

> **AI向け**: 作業前に本ファイルと `.project_rules/MASTER_PROTOCOL.md` を読むこと。
> **優先順位**: グローバル CLAUDE.md（`~/.claude/CLAUDE.md`） > MASTER_PROTOCOL > 本ファイル

## 項目

| 項目 | 内容 |
|------|------|
| プロジェクト名 | {{APP_NAME}} |
| 説明 | {{APP_DESCRIPTION}} |
| パッケージ名（npm） | {{PACKAGE_NAME}} |
| テンプレートレベル | {{TEMPLATE_LEVEL}} |
| **接続形態** | {{CONNECTIVITY}} |
| **配布・実行形態** | {{DISTRIBUTION}} |
| **Git 作業ブランチ** | {{GIT_WORK_BRANCH}} |
| タイムゾーン | {{TIMEZONE}} |

## 技術スタック

| カテゴリ | 技術 |
|---------|-----|
| シェル | Tauri {{TAURI_NOTE}} |
| フロント | Vite + HTML / CSS / JavaScript（root: `ui/`） |

## アプリ内パス（実体との対応）

| 種別 | パス |
|------|------|
| EventBus | `ui/src/core/event-bus.js` |
| StateManager | `ui/src/core/state-manager.js` |
| HTMLSanitizer | `ui/src/utils/sanitizer.js` |
| DataMigrationManager | `ui/src/utils/migration.js` |
| ConfigManager | `ui/src/utils/config.js` |
| DiffRenderer | `ui/src/utils/diff.js` |

※未使用モジュールはヒアリングで選ばなかった場合、上表から削除し、対応ファイルも生成しない（YAGNI）。

## 接続形態の運用

- {{CONNECTIVITY_RULES_ONE_LINE}}

## ドキュメント読み順

1. **グローバル CLAUDE.md**（グローバル掟・再掲なし）
2. **本ファイル（PROJECT.md）** — このアプリの事実
3. **`.project_rules/MASTER_PROTOCOL.md`** — プロジェクト差分
4. `docs/TROUBLESHOOTING.md`
{{OPTIONAL_DOC_BULLETS}}

## 実装開始トリガー（このプロジェクト）

- {{IMPLEMENTATION_TRIGGERS}}
```

---

### [TEMPLATE: docs/TROUBLESHOOTING.md]

```markdown
# トラブルシューティング

## 目次
- [ビルド](#ビルド)
- [実行時](#実行時)
- [過去に解決した問題](#過去に解決した問題)

## ビルド

### Tauri がビルドできない

- Rust / WebView 依存エラーは `npm run dev` と `cargo` のログで切り分け。
- **初回** `cargo` は時間がかかる場合あり。

## 実行時

### 画面がまっ白

- `tauri.conf.json` の `frontendDist` と Vite の `build.outDir`（通常 `../dist`）が一致しているか確認。

---

## 過去に解決した問題

### {{DATE}}: 初期セットアップ完了

- **問題**: 特になし
- **解決策**: FILE_TEMPLATE_SOURCE / MASTER_PROTOCOL_SOURCE に基づき構築
```

---

### [TEMPLATE: docs/TAURI_OPS_CHECKLIST.md]

運用チェックリスト（旧「Tauri開発・運用マニュアル」の要点を集約。詳細はプロジェクト側で追記）。

```markdown
# Tauri 開発・運用チェックリスト

## 前提・初回

- [ ] `cargo --version` / `node --version` / `npm --version` が通る
- [ ] **初回** `npm run dev` または `tauri build` は Rust 依存の取得・コンパイルがあり、**10〜30 分程度**かかることがある（2 回目以降はキャッシュで短縮）
- [ ] `npm install` 済み

## 開発

- [ ] `npm run dev` で起動（`beforeDevCommand` が `npm run dev:web` のときは Vite が先に立つ）
- [ ] **開発者ツール**: Windows / Linux は `F12` または `Ctrl+Shift+I`、macOS は `Cmd+Option+I`（デバッグビルドでは起動時に自動オープンする構成も可。`src-tauri/src/main.rs` 参照）
- [ ] 二重起動防止（`tauri-plugin-single-instance`）が必要なら `Cargo.toml` と `main.rs` のプラグイン初期化を維持

## ビルド

- [ ] `npm run build:web` で `dist/` が出力される
- [ ] `tauri build` と `tauri.conf.json` の `frontendDist` が一致
- [ ] **`bundle.active: false`（Portable 想定）のとき**: MSI/NSIS 等のインストーラーは作らず、`target/release/` の exe のみを主成果物とする想定。**配布の簡便性・USB 持ち運び・ビルド時間短縮**が主な理由。インストーラーが欲しい場合は `bundle` を見直し、`PROJECT.md` と掟を更新する
- [ ] エラー `failed to bundle project` が出たら、まず `tauri.conf.json` の `bundle.active` と `targets` を確認（インストーラー無効ならバンドル失敗を起こさない設定に寄せる）

## リリース

- [ ] `devVERSION` ルールどおりインクリメント
- [ ] 必要なら `node deploy.js` で `deploy_tauri/` に exe とバックアップ世代が揃う
```

---

### [TEMPLATE: docs/AI_REVIEW_PROMPT.md]
```markdown
# {{APP_NAME}} - AIレビュー用プロンプト

## このファイルの使い方（推奨）

チャットへ**そのまま貼れる指示文**：

- **単体レビュー**: `docs/AI_REVIEW_PROMPT.md に従い、このプロジェクトをレビューしてください。`
- **レビュー＋改善計画**: `docs/AI_REVIEW_PROMPT.md と docs/AI_IMPROVEMENT_PROMPT.md に従い、レビューと改修計画を出してください。`

---

## プロジェクト概要（自動または手動で要約）

- **プロジェクト名**: {{APP_NAME}}
- **説明**: {{APP_DESCRIPTION}}
- **テンプレートレベル**: {{TEMPLATE_LEVEL}}
- **接続形態**: {{CONNECTIVITY}}
- **使用中モジュール（該当のみ）**: {{MODULES_COMMA}}

---

## 基本プロンプト（コピペ可）

このプロジェクトをレビューし、次を分析してください。

### 必ず作成・更新するファイル

- `docs/REVIEW_PROGRESS.md` — レビュー結果と進捗
- 改修まで行う場合: `docs/IMPROVEMENT_ROADMAP.md` — 改修計画

### 観点

1. **コード品質**: 命名、責務、DRY
2. **アーキテクチャ**: ディレクトリ構成、モジュール間の境界、依存の向き
3. **セキュリティ**: インジェクション/XSS、入力処理、サニタイズの妥当性
4. **パフォーマンス**: 描画、メモリ、状態更新の効率
5. **テスト**（導入している場合）: カバレッジ・エッジケース
6. **掟の遵守**: グローバル CLAUDE.md、`.project_rules/MASTER_PROTOCOL.md`、`PROJECT.md` の優先順位と整合

出力は具体的な問題箇所と改善案にし、`REVIEW_PROGRESS.md` に集約すること。
```

---

### [TEMPLATE: docs/AI_IMPROVEMENT_PROMPT.md]

```markdown
# {{APP_NAME}} - AI改善提案用プロンプト

## 使い方

チャットへ貼る: `docs/AI_IMPROVEMENT_PROMPT.md に従い、改善提案をしてください。`

---

## プロジェクト情報（要約）

- **名前**: {{APP_NAME}}
- **モジュール**: {{MODULES_COMMA}}
- **接続形態**: {{CONNECTIVITY}}

---

## 依頼プロンプト（コピペ可）

このプロジェクトについて、以下の観点で**具体的な改善提案**を出してください。

### 進捗ファイル

- `docs/REVIEW_PROGRESS.md`
- `docs/IMPROVEMENT_ROADMAP.md`

### 観点

1. コード品質・リファクタ案
2. UX・エラーハンドリング
3. アーキテクチャ・保守性
4. パフォーマンス・メモリ
5. テスト戦略（導入時）
6. セキュリティ

優先順位は **緊急度 × 効果 − 実装コスト** で付け、フェーズ（即時 / 短期 / 長期）に分けること。
```

---

### [TEMPLATE: .project_rules/KNOWLEDGE_BASE.md]

```markdown
# 技術辞書 (Knowledge Base)

> AI向け: 回避策・再利用スニペットをここへ集約する。問題解決後や設計変更後に短文で追記する。

## 蓄積された知見

（追記されていく）

```

---

## 📄 【BASE】共通設定

### [TEMPLATE: .gitignore]

```text
# Dependencies
node_modules/

# Build
dist/
target/
src-tauri/target/
deploy_tauri/
deploy_web/
bin/
obj/

# Data
DATA/*.csv
DATA/*.json
!DATA/.gitkeep

# IDE
.vscode/
.idea/
.vs/
*.user
*.suo

# OS
.DS_Store
Thumbs.db

# Rust / デバッグ
*.pdb
*.rlib
*.rmeta

# Logs
*.log
logs/

# Environment
.env
.env.local
.env.*.local

# AI Archives（追跡しない運用でも可だがリストから外す場合は明示）
docs/archives.zip

# MAUI / .NET Specific
{{GITIGNORE_MAUI_ENTRIES}}
```

---

### [TEMPLATE: package.json]

```json
{
  "name": "{{PACKAGE_NAME}}",
  "version": "1.0.0",
  "description": "{{APP_DESCRIPTION}}",
  "private": true,
  "type": "module",
  "scripts": {
    "dev:web": "vite",
    "build:web": "vite build",
    "dev": "tauri dev",
    "build": "tauri build && node deploy.js",
    "build:no-deploy": "tauri build",
    "deploy": "node deploy.js"
  },
  "devDependencies": {
    "@tauri-apps/api": "^2.0.0",
    "@tauri-apps/cli": "^2.0.0",
    "vite": "^5.0.0"
  },
  "author": "{{AUTHOR}}",
  "license": "UNLICENSED"
}
```

※ `deploy.js` を使わない構成なら `build` から `&& node deploy.js` を削ること。

---

### [TEMPLATE: vite.config.js]

```javascript
import { defineConfig } from 'vite';

export default defineConfig({
  root: 'ui',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    target: process.env.TAURI_PLATFORM === 'windows' ? 'chrome105' : 'safari13',
    minify: !process.env.TAURI_DEBUG ? 'esbuild' : false,
    sourcemap: !!process.env.TAURI_DEBUG,
  },
  server: {
    port: 5173,
    strictPort: true,
  },
  envPrefix: ['VITE_', 'TAURI_'],
});
```

---

### [TEMPLATE: src-tauri/tauri.conf.json]

`identifier` はドメイン風に。**Rust の exe 出力名（製品名）と `deploy.js` の `{{EXE_BASENAME}}` を一致させる**（空白は避け、`package.json` の `name` と揃えるのが無難）。

```json
{
  "productName": "{{APP_NAME}}",
  "version": "1.0.0",
  "identifier": "com.{{SAFE_APP_NAME}}.app",
  "build": {
    "beforeDevCommand": "npm run dev:web",
    "beforeBuildCommand": "npm run build:web",
    "frontendDist": "../dist",
    "devUrl": "http://localhost:5173"
  },
  "bundle": {
    "active": {{TAURI_BUNDLE_ACTIVE}},
    "targets": "all"
  },
  "app": {
    "windows": [
      {
        "label": "main",
        "title": "{{APP_NAME}}",
        "width": {{WINDOW_WIDTH}},
        "height": {{WINDOW_HEIGHT}},
        "resizable": {{WINDOW_RESIZABLE}},
        "fullscreen": {{WINDOW_FULLSCREEN}}
      }
    ],
    "security": {
      "csp": null,
      "assetProtocol": {
        "scope": [
          "$RESOURCE/*",
          "./data/*",
          "./ui/*"
        ]
      }
    }
  }
}
```

- Portable だけ MSI を出したくない等は Tauri の `bundle` とプロジェクトの `MASTER_PROTOCOL` の配布説明で一致させる。`TAURI_BUNDLE_ACTIVE` は `true`/`false` の JSON リテラルに置換。

---

## 🔧 【SCRIPT】deploy.js（Tauri/Web 両対応）

**役割**: `tauri build` または Web ビルド後の成果物を `deploy_tauri/` または `deploy_web/` へコピーし、最大 10 世代のローカルバックアップをずらす。`npm run build` の最後で呼ぶ想定。

**置換**: `{{EXE_BASENAME}}` = Windows の exe のベース名（`productName` 由来。スペース不可ならパッケージ名のケバブ類似で統一）。

### [TEMPLATE: deploy.js]

```javascript
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const EXE_BASE = '{{EXE_BASENAME}}'; // tauri の Windows 実行ファイル名ベース (.exe を除く)

const isTauri = fs.existsSync(path.join(__dirname, 'src-tauri'));

let source, deployDir, destPath, fileName, deployDirName;

if (isTauri) {
    source = path.join(__dirname, 'src-tauri', 'target', 'release', `${EXE_BASE}.exe`);
    deployDirName = 'deploy_tauri';
    fileName = `${EXE_BASE}.exe`;
    deployDir = path.join(__dirname, deployDirName);
    destPath = path.join(deployDir, fileName);
} else {
    source = path.join(__dirname, 'dist');
    deployDirName = 'deploy_web';
    fileName = '';
    deployDir = path.join(__dirname, deployDirName);
    destPath = deployDir;
}

console.log(`デプロイ開始: ${isTauri ? 'TAURI' : 'WEB'}`);

if (!fs.existsSync(deployDir)) {
    fs.mkdirSync(deployDir, { recursive: true });
}

function copyFolderRecursiveSync(src, dest) {
    if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
    if (!fs.lstatSync(src).isDirectory()) return;
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
        const s = path.join(src, entry.name);
        const d = path.join(dest, entry.name);
        if (entry.isDirectory()) copyFolderRecursiveSync(s, d);
        else fs.copyFileSync(s, d);
    }
}

if (fs.existsSync(destPath)) {
    const isDir = fs.lstatSync(destPath).isDirectory();
    const suffix = isTauri ? '_tauri' : '_web';
    let base, ext;
    if (isDir) {
        base = 'backup';
        ext = '';
    } else {
        ext = path.extname(fileName);
        base = path.basename(fileName, ext);
    }

    const oldestBackup = path.join(deployDir, `${base}${suffix}_v1${ext}`);
    if (fs.existsSync(oldestBackup)) {
        try {
            if (fs.lstatSync(oldestBackup).isDirectory()) fs.rmSync(oldestBackup, { recursive: true, force: true });
            else fs.unlinkSync(oldestBackup);
        } catch (err) {
            console.warn('古いバックアップ削除失敗:', err.message);
        }
    }

    for (let i = 2; i <= 10; i++) {
        const oldPath = path.join(deployDir, `${base}${suffix}_v${i}${ext}`);
        const newPath = path.join(deployDir, `${base}${suffix}_v${i - 1}${ext}`);
        if (fs.existsSync(oldPath)) {
            try {
                fs.renameSync(oldPath, newPath);
            } catch (err) {
                console.warn(`バックアップリネーム失敗 v${i}:`, err.message);
            }
        }
    }

    const backupPath = path.join(deployDir, `${base}${suffix}_v10${ext}`);
    try {
        if (isDir) copyFolderRecursiveSync(destPath, backupPath);
        else fs.copyFileSync(destPath, backupPath);
        console.log(`バックアップ作成: ${path.basename(backupPath)}`);
    } catch (err) {
        console.warn('バックアップ作成失敗:', err.message);
    }
}

function copyWithRetry(src, dest, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            if (fs.lstatSync(src).isDirectory()) copyFolderRecursiveSync(src, dest);
            else fs.copyFileSync(src, dest);
            console.log(`デプロイ成功: ${path.basename(dest) || dest}`);
            return true;
        } catch (error) {
            if (i === maxRetries - 1) {
                console.error(`デプロイ失敗 (${maxRetries}回):`, error);
                return false;
            }
            console.warn(`リトライ ${i + 1}/${maxRetries}:`, error.message);
            const start = Date.now();
            while (Date.now() - start < 1000) {}
        }
    }
    return false;
}

if (fs.existsSync(source)) {
    copyWithRetry(source, destPath);
} else {
    console.error(`ソースが見つかりません: ${source}`);
    console.error(isTauri ? '先に tauri build を実行してください。' : '先に npm run build:web 等で dist を用意してください。');
    process.exit(1);
}
```

---

## 🎨 【UI】ui/index.html と ui/styles/main.css

### [INFO: ui/index.html]

- **オンライン**で Google Fonts を使う場合のみ `{{ONLINE_FONT_LINKS}}` を次のように展開。**オフライン**は空文字（コメントのみ残してよい）。

例（オンライン）:

```html
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&display=swap" rel="stylesheet">
```

### [TEMPLATE: ui/index.html] 本体

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{APP_NAME}}</title>
{{ONLINE_FONT_LINKS}}
    <link rel="stylesheet" href="styles/main.css">
</head>
<body>
    <div class="container">
        <h1>{{APP_NAME}}</h1>
        <p>{{INTRO_LINE}}</p>
        <div id="app"></div>
    </div>
{{SCRIPT_IMPORTS_HTML}}
{{INIT_SCRIPT_HTML}}
</body>
</html>
```

- **`{{SCRIPT_IMPORTS_HTML}}`**: 選んだモジュールごとに `<script type="module" src="src/core/event-bus.js"></script>` を並べる。**未選択は出さない。**
- **`{{INIT_SCRIPT_HTML}}`**: 最小なら `<script>document.addEventListener('DOMContentLoaded', () => { console.log('起動'); });</script>` 程度。

---

### [TEMPLATE: ui/styles/main.css]

```css
/* メイン（オフラインでも破綻しないフォントスタック） */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Noto Sans JP', 'BIZ UDゴシック', 'Segoe UI', system-ui, sans-serif;
    background-color: #f5f5f5;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    background: #fff;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

h1 {
    color: #333;
    margin-bottom: 20px;
}
```

※オンラインで Web フォントを読み込んだ場合のみ、`body` の先頭フォントが有効になる。

---

## 🧩 【MODULES】ui/src — すべて type="module" 前提

パスは厳守: `ui/src/core/`, `ui/src/utils/`。

### [MODULE: EventBus] (Path: ui/src/core/event-bus.js)

```javascript
/**
 * EventBus - イベント駆動の基盤
 */
class EventBus {
    constructor() {
        this.listeners = new Map();
        this.history = [];
    }

    on(event, callback) {
        if (!this.listeners.has(event)) this.listeners.set(event, []);
        this.listeners.get(event).push(callback);
        return () => this.off(event, callback);
    }

    off(event, callback) {
        if (!this.listeners.has(event)) return;
        const listeners = this.listeners.get(event);
        const index = listeners.indexOf(callback);
        if (index !== -1) listeners.splice(index, 1);
    }

    emit(event, data = null) {
        this._recordHistory(event, data);
        if (!this.listeners.has(event)) return;
        const listeners = [...this.listeners.get(event)];
        listeners.forEach((callback) => {
            try {
                callback(data, event);
            } catch (error) {
                console.error(`[EventBus] Error in listener for ${event}:`, error);
            }
        });
    }

    _recordHistory(event, data) {
        this.history.unshift({ event, data, timestamp: new Date().toISOString() });
        if (this.history.length > 100) this.history.pop();
    }

    getHistory(limit = 10) {
        return this.history.slice(0, limit);
    }

    getStats() {
        return {
            totalEvents: this.listeners.size,
            totalListeners: Array.from(this.listeners.values()).reduce((sum, arr) => sum + arr.length, 0),
        };
    }
}

if (typeof window !== 'undefined') window.EventBus = new EventBus();
```

### [MODULE: StateManager] (Path: ui/src/core/state-manager.js)

```javascript
/**
 * StateManager - 状態管理
 */
class StateManager {
    constructor() {
        this.state = {};
        this.history = [];
    }

    getState(key = null) {
        if (key === null) return { ...this.state };
        return this.state[key];
    }

    setState(updates) {
        const oldState = { ...this.state };
        this.state = { ...this.state, ...updates };
        if (window.EventBus) {
            window.EventBus.emit('state:updated', {
                oldState,
                newState: this.state,
                changes: this._getChanges(oldState, this.state),
            });
        }
    }

    _getChanges(oldState, newState) {
        const changes = {};
        for (const key of Object.keys(newState)) {
            if (oldState[key] !== newState[key]) {
                changes[key] = { old: oldState[key], new: newState[key] };
            }
        }
        return changes;
    }

    reset() {
        this.state = {};
        this.history = [];
    }
}

if (typeof window !== 'undefined') window.StateManager = new StateManager();
```

### [MODULE: HTMLSanitizer] (Path: ui/src/utils/sanitizer.js)

```javascript
/**
 * HTMLSanitizer - XSS 対策
 */
const HTMLSanitizer = {
    escape(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    },

    stripTags(str) {
        if (!str) return '';
        return String(str).replace(/<[^>]*>/g, '');
    },

    escapeAttribute(str) {
        if (!str) return '';
        return this.escape(str).replace(/"/g, '&quot;');
    },
};

if (typeof window !== 'undefined') window.HTMLSanitizer = HTMLSanitizer;
```

### [MODULE: DataMigrationManager] (Path: ui/src/utils/migration.js)

```javascript
/**
 * DataMigrationManager - データマイグレーション
 */
const DataMigrationManager = {
    currentVersion: '1.0.0',

    migrate(data, fromVersion) {
        console.log(`Migration from ${fromVersion} to ${this.currentVersion}`);
        return data;
    },

    getVersion(data) {
        return data.version || '1.0.0';
    },

    setVersion(data, version) {
        data.version = version;
        return data;
    },
};

if (typeof window !== 'undefined') window.DataMigrationManager = DataMigrationManager;
```

### [MODULE: ConfigManager] (Path: ui/src/utils/config.js)

```javascript
/**
 * ConfigManager - 設定管理
 */
class ConfigManager {
    constructor() {
        this.config = {};
        this.defaults = {};
    }

    setDefault(key, value) {
        this.defaults[key] = value;
    }

    get(key, defaultValue = null) {
        if (key in this.config) return this.config[key];
        if (key in this.defaults) return this.defaults[key];
        return defaultValue;
    }

    set(key, value) {
        this.config[key] = value;
        if (window.EventBus) window.EventBus.emit('config:updated', { key, value });
    }

    loadFromStorage(storageKey = 'app_config') {
        try {
            const stored = localStorage.getItem(storageKey);
            if (stored) this.config = JSON.parse(stored);
        } catch (error) {
            console.error('Config load error:', error);
        }
    }

    saveToStorage(storageKey = 'app_config') {
        try {
            localStorage.setItem(storageKey, JSON.stringify(this.config));
        } catch (error) {
            console.error('Config save error:', error);
        }
    }

    reset() {
        this.config = {};
    }
}

if (typeof window !== 'undefined') window.ConfigManager = new ConfigManager();
```

### [MODULE: DiffRenderer] (Path: ui/src/utils/diff.js)

```javascript
/**
 * DiffRenderer - 差分描画（簡易）
 */
class DiffRenderer {
    constructor() {
        this.cache = new Map();
    }

    renderDiff(oldElement, newElement, container) {
        if (!oldElement || !newElement || !container) return;
        const oldHTML = oldElement.innerHTML || '';
        const newHTML = newElement.innerHTML || '';
        if (oldHTML === newHTML) return;
        const diff = this._calculateDiff(oldHTML, newHTML);
        this._applyDiff(container, diff);
    }

    _calculateDiff(oldText, newText) {
        const changes = [];
        const maxLen = Math.max(oldText.length, newText.length);
        for (let i = 0; i < maxLen; i++) {
            if (oldText[i] !== newText[i]) {
                changes.push({
                    index: i,
                    old: oldText[i] || '',
                    new: newText[i] || '',
                });
            }
        }
        return changes;
    }

    _applyDiff(container, diff) {
        diff.forEach((change) => {
            console.log('Diff at index', change.index, ':', change.old, '->', change.new);
        });
    }

    clearCache() {
        this.cache.clear();
    }
}

if (typeof window !== 'undefined') window.DiffRenderer = new DiffRenderer();
```

---

## 🦀 【TAURI】Rust ひな形（`src-tauri/`）

`[package] name` は **`Cargo.toml` のクレート名**であり、Windows の exe ベース名と一致させる運用が無難（`deploy.js` の `{{EXE_BASENAME}}` と揃える）。`tauri.conf.json` のウィンドウ **`label` は `main`** とし、下記 `main.rs` の `get_webview_window("main")` と一致させよ。

### [TEMPLATE: src-tauri/Cargo.toml]

```toml
[package]
name = "{{RUST_CRATE_NAME}}"
version = "1.0.0"
description = "{{APP_DESCRIPTION}}"
authors = ["{{AUTHOR}}"]
license = ""
repository = ""
edition = "2021"

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = ["protocol-asset"] }
tauri-plugin-single-instance = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[features]
default = ["custom-protocol"]
custom-protocol = ["tauri/custom-protocol"]
```

### [TEMPLATE: src-tauri/build.rs]

```rust
fn main() {
    tauri_build::build()
}
```

### [TEMPLATE: src-tauri/src/main.rs]

- **Portable**: exe 直下の `data` を返す `get_data_dir`（存在しなければ作成）
- **二重起動**: `tauri-plugin-single-instance` で既存ウィンドウにフォーカス
- **デバッグ**: `debug_assertions` のとき DevTools を自動オープン

```rust
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::env;
use std::fs;
use tauri::Manager;

#[tauri::command]
fn get_data_dir() -> String {
    if let Ok(mut exe_path) = env::current_exe() {
        exe_path.pop();
        exe_path.push("data");
        if !exe_path.exists() {
            let _ = fs::create_dir_all(&exe_path);
        }
        return exe_path.to_string_lossy().to_string();
    }
    "./data".to_string()
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            let _ = app
                .get_webview_window("main")
                .expect("no main window")
                .set_focus();
        }))
        .invoke_handler(tauri::generate_handler![get_data_dir])
        .setup(|app| {
            #[cfg(debug_assertions)]
            {
                if let Some(window) = app.get_webview_window("main") {
                    window.open_devtools();
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**補足**: `cargo tauri init` で骨格を作り、上記 3 ファイルで上書きする運用でもよい。`icons/` は CLI 生成物を流用する。

---

## 📱 【MAUI】MAUI (.NET MAUI) ひな形

### [TEMPLATE: {{SAFE_APP_NAME}}.csproj]

```xml
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFrameworks>net8.0-android;net8.0-ios;net8.0-maccatalyst</TargetFrameworks>
        <TargetFrameworks Condition="$([MSBuild]::IsOSPlatform('windows'))">$(TargetFrameworks);net8.0-windows10.0.19041.0</TargetFrameworks>
        <OutputType>Exe</OutputType>
        <RootNamespace>{{NAMESPACE}}</RootNamespace>
        <UseMaui>true</UseMaui>
        <SingleProject>true</SingleProject>
        <ApplicationTitle>{{APP_NAME}}</ApplicationTitle>
        <ApplicationId>com.{{SAFE_APP_NAME}}.app</ApplicationId>
        <ApplicationVersion>1</ApplicationVersion>
    </PropertyGroup>
</Project>
```

### [TEMPLATE: MauiProgram.cs]

```csharp
namespace {{NAMESPACE}};

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder.UseMauiApp<App>();
        return builder.Build();
    }
}
```

### [TEMPLATE: App.xaml]

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<Application xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             x:Class="{{NAMESPACE}}.App">
    <Application.Resources>
        <ResourceDictionary />
    </Application.Resources>
</Application>
```

### [TEMPLATE: App.xaml.cs]

```csharp
namespace {{NAMESPACE}};

public partial class App : Application
{
    public App()
    {
        InitializeComponent();
        MainPage = new AppShell();
    }
}
```

### [TEMPLATE: AppShell.xaml]

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<Shell x:Class="{{NAMESPACE}}.AppShell"
       xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
       xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
       xmlns:local="clr-namespace:{{NAMESPACE}}"
       Shell.FlyoutBehavior="Disabled"
       Title="{{APP_NAME}}">
    <ShellContent Title="Home" ContentTemplate="{DataTemplate local:MainPage}" Route="MainPage" />
</Shell>
```

### [TEMPLATE: AppShell.xaml.cs]

```csharp
namespace {{NAMESPACE}};

public partial class AppShell : Shell
{
    public AppShell() { InitializeComponent(); }
}
```

### [TEMPLATE: MainPage.xaml]

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<ContentPage xmlns="http://schemas.microsoft.com/dotnet/2021/maui"
             xmlns:x="http://schemas.microsoft.com/winfx/2009/xaml"
             x:Class="{{NAMESPACE}}.MainPage">
    <ScrollView>
        <VerticalStackLayout Padding="30" Spacing="25" VerticalOptions="Center">
            <Label Text="Hello, MAUI!" FontSize="32" HorizontalOptions="Center" />
            <Label Text="{{APP_DESCRIPTION}}" FontSize="18" HorizontalOptions="Center" />
            <Button x:Name="CounterBtn" Text="Click me" Clicked="OnCounterClicked" HorizontalOptions="Center" />
        </VerticalStackLayout>
    </ScrollView>
</ContentPage>
```

### [TEMPLATE: MainPage.xaml.cs]

```csharp
namespace {{NAMESPACE}};

public partial class MainPage : ContentPage
{
    int count = 0;
    public MainPage() { InitializeComponent(); }
    private void OnCounterClicked(object sender, EventArgs e)
    {
        count++;
        CounterBtn.Text = $"Clicked {count} times";
    }
}
```

---

## 📱 【MAUI】MAUI 専用ドキュメント

### [TEMPLATE: MAUI_PROJECT.md] (Path: PROJECT.md)

```markdown
# {{APP_NAME}} (MAUI版)

> **AI向け**: 作業前に本ファイルと `.project_rules/MASTER_PROTOCOL.md` を読むこと。
> **優先順位**: グローバル CLAUDE.md（`~/.claude/CLAUDE.md`） > MASTER_PROTOCOL > 本ファイル

{{APP_DESCRIPTION}}

## プロジェクト構成 (C# / .NET MAUI)

| カテゴリ | 技術 |
|---------|-----|
| フレームワーク | .NET MAUI (.NET 8.0) |
| 言語 | C# |
| UIスタック | XAML |
| **Git 作業ブランチ** | {{GIT_WORK_BRANCH}} |
| **接続形態** | {{CONNECTIVITY}} |

## アプリ内パス（実体との対応）

| 種別 | パス |
|------|------|
| プロジェクトファイル | `{{SAFE_APP_NAME}}.csproj` |
| エントリーポイント | `MauiProgram.cs` |
| メイン画面 | `MainPage.xaml` |

## 接続形態の運用

- {{CONNECTIVITY_RULES_ONE_LINE}}

## ドキュメント読み順

1. **グローバル CLAUDE.md**（グローバル掟・再掲なし）
2. **本ファイル（PROJECT.md）** — このアプリの事実
3. **`.project_rules/MASTER_PROTOCOL.md`** — プロジェクト差分
4. `docs/TROUBLESHOOTING.md`
{{OPTIONAL_DOC_BULLETS}}

## 実装開始トリガー（このプロジェクト）

- {{IMPLEMENTATION_TRIGGERS}}
```

---

### [TEMPLATE: MAUI_TROUBLESHOOTING.md] (Path: docs/TROUBLESHOOTING.md)

```markdown
# トラブルシューティング (MAUI)

## ビルド・実行エラー

### ビルドが通らない
- `bin/` や `obj/` フォルダを削除してリビルドを試してください。
- .NET SDK のバージョン（8.0以上）を確認してください。

### エミュレーターで起動しない
- Android SDK や Xcode の設定を確認してください。
- Hyper-V が有効になっているか確認してください。
```
