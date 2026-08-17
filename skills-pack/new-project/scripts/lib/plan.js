const MODULE_PATHS = {
    EventBus: 'ui/src/core/event-bus.js',
    StateManager: 'ui/src/core/state-manager.js',
    HTMLSanitizer: 'ui/src/utils/sanitizer.js',
    DataMigrationManager: 'ui/src/utils/migration.js',
    ConfigManager: 'ui/src/utils/config.js',
    DiffRenderer: 'ui/src/utils/diff.js',
};

const WEB_FILES = [
    'package.json',
    'vite.config.js',
    'deploy.js',
    'ui/index.html',
    'ui/styles/main.css',
    '.gitignore',
    'docs/TROUBLESHOOTING.md',
];

const TAURI_FILES = [
    'src-tauri/tauri.conf.json',
    'src-tauri/Cargo.toml',
    'src-tauri/build.rs',
    'src-tauri/src/main.rs',
    'docs/TAURI_OPS_CHECKLIST.md',
];

const MAUI_FILES = [
    '{{SAFE_APP_NAME}}.csproj',
    'App.xaml',
    'App.xaml.cs',
    'AppShell.xaml',
    'AppShell.xaml.cs',
    'MainPage.xaml',
    'MainPage.xaml.cs',
    'MauiProgram.cs',
    '.gitignore',
    'docs/TROUBLESHOOTING.md',
];

/**
 * @param {{
 *   distribution?: 'Web' | 'Tauri' | 'MAUI' | 'docs-only',
 *   hidemProfile?: boolean,
 *   aiMaintained?: boolean,
 *   modules?: string[],
 * }} options
 * @returns {string[]}
 */
export function buildFilePlan(options = {}) {
    const distribution = options.distribution || 'Web';
    const hidemProfile = Boolean(options.hidemProfile);
    const aiMaintained = Boolean(options.aiMaintained);
    const modules = options.modules || [];

    const files = ['README.md'];
    if (aiMaintained) files.push('AGENTS.md');

    if (distribution === 'MAUI') {
        files.push(...MAUI_FILES);
    } else if (distribution === 'Web' || distribution === 'Tauri') {
        files.push(...WEB_FILES);
        if (distribution === 'Tauri') files.push(...TAURI_FILES);
        for (const name of modules) {
            if (MODULE_PATHS[name]) files.push(MODULE_PATHS[name]);
        }
    }

    if (hidemProfile) {
        files.push('PROJECT.md');
        files.push('.project_rules/MASTER_PROTOCOL.md');
    }

    const hasOtherDocs = files.some((f) => {
        const n = f.replace(/\\/g, '/');
        return n.startsWith('docs/') && n !== 'docs/index.md';
    });
    if (hasOtherDocs) files.push('docs/index.md');

    return files;
}

const PATH_TO_MODULE = Object.fromEntries(
    Object.entries(MODULE_PATHS).map(([name, filePath]) => [filePath, name])
);

export function templateNameFor(outputPath, distribution) {
    if (PATH_TO_MODULE[outputPath]) return PATH_TO_MODULE[outputPath];
    if (distribution === 'MAUI') {
        if (outputPath === 'PROJECT.md') return 'MAUI_PROJECT.md';
        if (outputPath === 'docs/TROUBLESHOOTING.md') return 'MAUI_TROUBLESHOOTING.md';
    }
    if (outputPath === '.project_rules/MASTER_PROTOCOL.md') return 'MASTER_PROTOCOL.md 本文';
    return outputPath;
}
