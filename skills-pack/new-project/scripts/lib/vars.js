export function setupInstructions(project) {
    if (project.distribution === 'MAUI') {
        return '- Visual Studio 等で .csproj を開く';
    }
    if (project.distribution === 'docs-only') {
        return '- 追加セットアップなし（README を確認）';
    }
    let lines = '- npm install\n- npm run dev';
    if (project.distribution === 'Tauri') {
        lines += '\n- Tauri の Rust ツールチェインを用意する';
    }
    return lines;
}

export function prepareVariables(p, planned = []) {
    const today = new Date().toISOString().split('T')[0];
    const safeName = p.name.toLowerCase().replace(/[^a-z0-9]/g, '-');

    let rustCrateName = safeName;
    if (/^[0-9]/.test(rustCrateName)) {
        rustCrateName = `app-${rustCrateName}`;
    }

    const docsFiles = planned
        .map((f) => f.replace(/\\/g, '/'))
        .filter((f) => f.startsWith('docs/') && f !== 'docs/index.md');
    const docsIndexRows = docsFiles.length
        ? docsFiles.map((f) => {
            const rel = f.replace(/^docs\//, '');
            return `| [${rel}](${rel}) | supporting notes | current | when you need detail |`;
        }).join('\n')
        : '| (none yet) | — | — | — |';

    const docsHubLine = planned.some((f) => f.replace(/\\/g, '/') === 'docs/index.md')
        ? '- [Documentation index](docs/index.md)'
        : '';
    const agentsLine = p.aiMaintained ? '- `AGENTS.md` — AI working rules for this repository' : '';
    const hidemLinks = p.hidemProfile
        ? '- `PROJECT.md` — purpose, scope, non-goals (Hidem profile)\n- `.project_rules/MASTER_PROTOCOL.md` — working rules (Hidem profile)'
        : '';

    let setup;
    if (p.distribution === 'MAUI') {
        setup = 'Open the `.csproj` in Visual Studio or `dotnet build`.';
    } else if (p.distribution === 'docs-only') {
        setup = 'No runtime install. Read `README.md`.';
    } else {
        setup = '`npm install` then `npm run dev`. These commands have not been run.';
    }

    const vars = {
        APP_NAME: p.name,
        APP_DESCRIPTION: p.description || '',
        PACKAGE_NAME: safeName,
        AUTHOR: p.author,
        TEMPLATE_LEVEL: p.hidemProfile ? 'Hidem' : 'General',
        CONNECTIVITY: p.connectivity,
        DISTRIBUTION: p.distribution,
        TIMEZONE: 'Asia/Tokyo',
        SAFE_APP_NAME: safeName.replace(/-/g, ''),
        NAMESPACE: (/^[0-9]/.test(safeName) ? `app_${safeName}` : safeName).replace(/-/g, '_'),
        EXE_BASENAME: p.name.replace(/\s+/g, '-'),
        WINDOW_WIDTH: '1000',
        WINDOW_HEIGHT: '800',
        WINDOW_RESIZABLE: 'true',
        WINDOW_FULLSCREEN: 'false',
        TAURI_BUNDLE_ACTIVE: 'false',
        DATE: today,
        RUST_CRATE_NAME: rustCrateName,
        PROJECT_EXTRA_CONSTRAINTS: '（特になし）',
        GITIGNORE_MAUI_ENTRIES: p.distribution === 'MAUI' ? 'bin/\nobj/\n.vs/\n*.user\n*.useros' : '# (MAUI entries skipped)',
        DOCS_INDEX_ROWS: docsIndexRows,
        DOCS_HUB_LINE: docsHubLine,
        AGENTS_LINE: agentsLine,
        HIDEM_LINKS: hidemLinks,
        SETUP_INSTRUCTIONS: setup,
        FEATURES_LINE: 'Scaffold only. No application features are implemented yet.',
        STATUS_LINE: 'Greenfield scaffold. Implementation has not started.',
    };

    vars.GIT_MAIN_BRANCH = 'main';
    vars.GIT_STABLE_BRANCH = 'main';
    vars.GIT_DEVELOP_BRANCH = 'develop';
    vars.GIT_WORK_BRANCH = p.gitPattern === 'A' ? 'main' : 'develop';

    if (p.connectivity === 'Online' || p.connectivity === 'Hybrid') {
        vars.ONLINE_FONT_LINKS = `    <link rel="preconnect" href="https://fonts.googleapis.com">\n    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;700&display=swap" rel="stylesheet">`;
    } else {
        vars.ONLINE_FONT_LINKS = '    <!-- Offline mode: No external fonts -->';
    }

    const moduleMap = {
        EventBus: 'src/core/event-bus.js',
        StateManager: 'src/core/state-manager.js',
        HTMLSanitizer: 'src/utils/sanitizer.js',
        DataMigrationManager: 'src/utils/migration.js',
        ConfigManager: 'src/utils/config.js',
        DiffRenderer: 'src/utils/diff.js',
    };
    vars.SCRIPT_IMPORTS_HTML = (p.modules || []).map((m) => {
        const pth = moduleMap[m] || `src/utils/${m.toLowerCase()}.js`;
        return `    <script type="module" src="${pth}"></script>`;
    }).join('\n');

    vars.INIT_SCRIPT_HTML = `    <script type="module">\n        document.addEventListener('DOMContentLoaded', () => {\n            console.log('${p.name} 起動');\n        });\n    </script>`;
    vars.INTRO_LINE = `${p.description || p.name} のエントリーポイントです。`;
    vars.MODULES_COMMA = (p.modules || []).join(', ');
    vars.TAURI_NOTE = p.distribution === 'Tauri' ? '(Rust + WebView)' : '';
    vars.CONNECTIVITY_RULES_ONE_LINE = p.connectivity === 'Offline' ? '外部通信を一切禁止し、ローカルリソースのみを使用する。' : '必要に応じてCDNやAPIを利用する。';
    vars.OPTIONAL_DOC_BULLETS = p.distribution === 'Tauri' ? '- `docs/TAURI_OPS_CHECKLIST.md`' : '';
    vars.IMPLEMENTATION_TRIGGERS = '「実装して」「実行して」「作って」';

    return vars;
}
