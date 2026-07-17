import { intro, outro, text, select, multiselect, confirm, spinner, note } from '@clack/prompts';
import pc from 'picocolors';
import { SourceParser } from './lib/parser.js';
import { ProjectWriter } from './lib/writer.js';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
    intro(pc.bgCyan(pc.black(' 🏗️  PROJECT SCAFFOLDER ')));

    // 1. ヒアリング
    const project = await fetchProjectInfo();
    if (!project) return;

    const s = spinner();
    s.start('プロジェクトを構築中...');

    try {
        const templateSource = path.join(__dirname, 'FILE_TEMPLATE_SOURCE.md');
        const protocolSource = path.join(__dirname, 'MASTER_PROTOCOL_SOURCE.md');

        const parser = new SourceParser(templateSource);
        const protocolParser = new SourceParser(protocolSource);
        const writer = new ProjectWriter(); // process.cwd() に書き出し

        // 共通変数の準備
        const vars = prepareVariables(project);

        // 1. 基本ファイルの動的構成
        let baseTemplates = [
            'PROJECT.md',
            'docs/TROUBLESHOOTING.md',
            '.gitignore'
        ];

        if (project.distribution === 'MAUI') {
            // MAUI (.NET MAUI) 用のファイルセット
            baseTemplates.push(
                '{{SAFE_APP_NAME}}.csproj',
                'App.xaml',
                'App.xaml.cs',
                'AppShell.xaml',
                'AppShell.xaml.cs',
                'MainPage.xaml',
                'MainPage.xaml.cs',
                'MauiProgram.cs'
            );
        } else {
            // Web / Tauri 用のファイルセット (Viteスタック)
            baseTemplates.push('package.json', 'vite.config.js', 'deploy.js', 'ui/index.html', 'ui/styles/main.css');
            
            if (project.distribution === 'Tauri') {
                baseTemplates.push(
                    'src-tauri/tauri.conf.json',
                    'src-tauri/Cargo.toml',
                    'src-tauri/build.rs',
                    'src-tauri/src/main.rs',
                    'docs/TAURI_OPS_CHECKLIST.md'
                );
            }
        }

        // 標準構成以上で追加されるドキュメント
        if (project.level !== 'Minimal') {
            baseTemplates.push('docs/AI_REVIEW_PROMPT.md');
            baseTemplates.push('docs/AI_IMPROVEMENT_PROMPT.md');
            baseTemplates.push('.project_rules/KNOWLEDGE_BASE.md');
        }

        for (const tName of baseTemplates) {
            // MAUI の場合は専用のドキュメントテンプレートに差し替えて読み込む
            let sourceTemplateName = tName;
            if (project.distribution === 'MAUI') {
                if (tName === 'PROJECT.md') sourceTemplateName = 'MAUI_PROJECT.md';
                if (tName === 'docs/TROUBLESHOOTING.md') sourceTemplateName = 'MAUI_TROUBLESHOOTING.md';
            }

            const section = parser.getSection(sourceTemplateName);
            if (section) {
                // 出力パスは元の tName (PROJECT.md 等) を維持するために section.path ではなく tName を使う場合があるが
                // 現状の getSection は section.path に正しい出力パスが入っているのでそれを利用。
                // ただし MAUI_PROJECT.md のカタログ内 Path が PROJECT.md になっている必要がある。
                const finalPath = ProjectWriter.replacePlaceholders(section.path, vars);
                const content = ProjectWriter.replacePlaceholders(section.content, vars);
                writer.writeFile(finalPath, content);
            }
        }

        // 3. モジュールの生成
        for (const moduleName of project.modules) {
            const section = parser.getSection(moduleName);
            if (section) {
                const finalPath = ProjectWriter.replacePlaceholders(section.path, vars);
                const content = ProjectWriter.replacePlaceholders(section.content, vars);
                writer.writeFile(finalPath, content);
            }
        }

        // 4. MASTER_PROTOCOL.md の生成
        const protocolSection = protocolParser.getSection('MASTER_PROTOCOL.md 本文');
        if (protocolSection) {
            const content = ProjectWriter.replacePlaceholders(protocolSection.content, vars);
            writer.writeFile('.project_rules/MASTER_PROTOCOL.md', content);
        }

        s.stop(pc.green('構築完了！'));

        // 5. 事後処理の提案
        const hasPackageJson = fs.existsSync(path.join(process.cwd(), 'package.json'));
        let nextSteps = `1. cd ${project.name} (既にディレクトリ内の場合は不要)\n`;
        if (hasPackageJson) {
            nextSteps += `2. npm install (推奨)`;
        } else {
            nextSteps += `2. 各プラットフォームのビルドツール（Visual Studio 等）で開いてください`;
        }

        note(
            `プロジェクト "${project.name}" が正常に作成されました。\n` +
            `場所: ${process.cwd()}\n\n` +
            `次の一歩:\n` +
            nextSteps,
            '完了報告'
        );

        if (hasPackageJson) {
            const shouldInstall = await confirm({
                message: '今すぐ npm install を実行しますか？',
                initialValue: true
            });

            if (shouldInstall) {
                s.start('依存関係をインストール中...');
                // 実際には child_process で回すが、ここではデモとして完了とする
                s.stop(pc.green('インストール完了（シミュレーション）'));
            }
        }

    } catch (error) {
        s.stop(pc.red('構築失敗'));
        console.error(error);
    }

    outro(pc.cyan('Happy Coding!'));
}

async function fetchProjectInfo() {
    const name = await text({
        message: 'プロジェクト名を入力してください',
        placeholder: 'my-awesome-app',
        validate: (value) => {
            if (value.length === 0) return '名前は必須だぜ！';
        }
    });
    if (typeof name === 'symbol') return null;

    const description = await text({
        message: 'プロジェクトの説明を入力してください',
        placeholder: '〇〇管理システム'
    });
    if (typeof description === 'symbol') return null;

    const author = await text({
        message: '作成者名を入力してください',
        initialValue: 'ヒデ'
    });
    if (typeof author === 'symbol') return null;

    const distribution = await select({
        message: '配信形式を選んでください',
        options: [
            { value: 'Web', label: 'Web App (Vite)' },
            { value: 'Tauri', label: 'Tauri (Desktop App)', hint: 'Vite + Rust' },
            { value: 'MAUI', label: 'MAUI (Desktop/Mobile)', hint: 'C#' }
        ]
    });
    if (typeof distribution === 'symbol') return null;

    const connectivity = await select({
        message: '接続形態を選んでください',
        options: [
            { value: 'Offline', label: '完全オフライン', hint: '外部アクセス一切なし' },
            { value: 'Online', label: 'オンライン', hint: 'CDN等を利用する' },
            { value: 'Hybrid', label: 'ハイブリッド', hint: '状況に応じて切り替え' }
        ]
    });
    if (typeof connectivity === 'symbol') return null;

    const level = await select({
        message: 'テンプレートレベルを選んでください',
        options: [
            { value: 'Minimal', label: '最小構成' },
            { value: 'Standard', label: '標準構成', hint: 'おすすめ' },
            { value: 'Full', label: 'フル構成' }
        ]
    });
    if (typeof level === 'symbol') return null;

    // MAUI の場合は JS モジュールの選択をスキップ（仕様不整合回避）
    let modules = [];
    if (distribution !== 'MAUI') {
        modules = await multiselect({
            message: '使用するモジュールを選択してください (Spaceで選択)',
            options: [
                { value: 'EventBus', label: 'EventBus', hint: 'イベント駆動', checked: true },
                { value: 'StateManager', label: 'StateManager', hint: '状態管理', checked: true },
                { value: 'HTMLSanitizer', label: 'HTMLSanitizer', hint: 'XSS対策', checked: true },
                { value: 'DataMigrationManager', label: 'DataMigrationManager', hint: 'データマイグレーション' },
                { value: 'ConfigManager', label: 'ConfigManager', hint: 'JSON設定管理' },
                { value: 'DiffRenderer', label: 'DiffRenderer', hint: '差分描画' }
            ]
        });
        if (typeof modules === 'symbol') return null;
    }

    const gitPattern = await select({
        message: 'Git運用パターンを選んでください',
        options: [
            { value: 'A', label: 'パターンA (main一本)', hint: '小規模・個人' },
            { value: 'B', label: 'パターンB (main + develop)', hint: '中規模・チーム' }
        ]
    });
    if (typeof gitPattern === 'symbol') return null;

    return { name, description, author, distribution, connectivity, level, modules, gitPattern };
}

function prepareVariables(p) {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD 形式
    const safeName = p.name.toLowerCase().replace(/[^a-z0-9]/g, '-');
    
    // Rust クレート名の安全化（数字始まりを回避）
    let rustCrateName = safeName;
    if (/^[0-9]/.test(rustCrateName)) {
        rustCrateName = `app-${rustCrateName}`;
    }

    // 基本変数
    const vars = {
        APP_NAME: p.name,
        APP_DESCRIPTION: p.description || '',
        PACKAGE_NAME: safeName,
        AUTHOR: p.author,
        TEMPLATE_LEVEL: p.level,
        CONNECTIVITY: p.connectivity,
        DISTRIBUTION: p.distribution,
        TIMEZONE: 'Asia/Tokyo',
        SAFE_APP_NAME: safeName.replace(/-/g, ''),
        NAMESPACE: (/^[0-9]/.test(safeName) ? `app_${safeName}` : safeName).replace(/-/g, '_'), // C# 用の名前空間
        EXE_BASENAME: p.name.replace(/\s+/g, '-'),
        WINDOW_WIDTH: '1000',
        WINDOW_HEIGHT: '800',
        WINDOW_RESIZABLE: 'true',
        WINDOW_FULLSCREEN: 'false',
        // フル構成の場合のみインストーラー生成を有効化する運用
        TAURI_BUNDLE_ACTIVE: p.level === 'Full' ? 'true' : 'false',
        DATE: today,
        RUST_CRATE_NAME: rustCrateName,
        PROJECT_EXTRA_CONSTRAINTS: '（特になし）',
        GITIGNORE_MAUI_ENTRIES: p.distribution === 'MAUI' ? 'bin/\nobj/\n.vs/\n*.user\n*.useros' : '# (MAUI entries skipped)'
    };

    // Git変数
    vars.GIT_MAIN_BRANCH = 'main';
    vars.GIT_STABLE_BRANCH = 'main';
    vars.GIT_DEVELOP_BRANCH = 'develop';
    vars.GIT_WORK_BRANCH = p.gitPattern === 'A' ? 'main' : 'develop';

    // UI関連（接続形態による分岐）
    if (p.connectivity === 'Online' || p.connectivity === 'Hybrid') {
        vars.ONLINE_FONT_LINKS = `    <link rel="preconnect" href="https://fonts.googleapis.com">\n    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&display=swap" rel="stylesheet">`;
    } else {
        vars.ONLINE_FONT_LINKS = '    <!-- Offline mode: No external fonts -->';
    }

    // スクリプトインポート（カタログのパスと厳密に一致させる）
    const moduleMap = {
        'EventBus': 'src/core/event-bus.js',
        'StateManager': 'src/core/state-manager.js',
        'HTMLSanitizer': 'src/utils/sanitizer.js',
        'DataMigrationManager': 'src/utils/migration.js',
        'ConfigManager': 'src/utils/config.js',
        'DiffRenderer': 'src/utils/diff.js'
    };
    vars.SCRIPT_IMPORTS_HTML = p.modules.map(m => {
        const path = moduleMap[m] || `src/utils/${m.toLowerCase()}.js`;
        return `    <script type="module" src="${path}"></script>`;
    }).join('\n');

    vars.INIT_SCRIPT_HTML = `    <script type="module">\n        document.addEventListener('DOMContentLoaded', () => {\n            console.log('${p.name} 起動');\n        });\n    </script>`;
    vars.INTRO_LINE = `${p.description || p.name} のエントリーポイントです。`;
    vars.MODULES_COMMA = p.modules.join(', ');
    vars.TAURI_NOTE = p.distribution === 'Tauri' ? '(Rust + WebView)' : '';
    vars.CONNECTIVITY_RULES_ONE_LINE = p.connectivity === 'Offline' ? '外部通信を一切禁止し、ローカルリソースのみを使用する。' : '必要に応じてCDNやAPIを利用する。';
    vars.OPTIONAL_DOC_BULLETS = p.distribution === 'Tauri' ? '- `docs/TAURI_OPS_CHECKLIST.md`' : '';
    vars.IMPLEMENTATION_TRIGGERS = '「実装して」「実行して」「作って」';

    return vars;
}

main();
