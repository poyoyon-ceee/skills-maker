import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const IGNORE = new Set(['.ds_store', 'thumbs.db', 'desktop.ini']);
const MANIFEST_NAMES = new Set(['package.json', 'cargo.toml', 'pyproject.toml', 'go.mod']);
const SOURCE_DIRS = new Set(['src', 'app', 'ui', 'lib', 'docs']);
const SOURCE_EXTS = new Set(['.js', '.mjs', '.cjs', '.ts', '.tsx', '.jsx', '.cs', '.py', '.rs', '.go']);

function gitHasCommits(gitDir) {
    const refsHeads = path.join(gitDir, 'refs', 'heads');
    if (!fs.existsSync(refsHeads)) return false;
    try {
        const walk = (dir) => {
            for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
                const p = path.join(dir, ent.name);
                if (ent.isDirectory()) {
                    if (walk(p)) return true;
                } else {
                    return true;
                }
            }
            return false;
        };
        return walk(refsHeads);
    } catch {
        return false;
    }
}

function isProjectSignal(ent, dirPath) {
    const lower = ent.name.toLowerCase();
    if (lower.startsWith('readme')) return true;
    if (MANIFEST_NAMES.has(lower) || lower.endsWith('.csproj')) return true;
    if (ent.isDirectory() && SOURCE_DIRS.has(lower)) return true;
    if (ent.isFile() && SOURCE_EXTS.has(path.extname(lower))) return true;
    if (lower === 'agents.md' || lower === 'project.md') return true;
    return false;
}

/**
 * @param {string} dirPath
 * @returns {'new' | 'existing' | 'ambiguous'}
 */
export function classifyProject(dirPath) {
    if (!fs.existsSync(dirPath)) return 'new';
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });

    let hasCommits = false;
    let projectSignals = false;
    let nonGitEntries = 0;

    for (const ent of entries) {
        const lower = ent.name.toLowerCase();
        if (IGNORE.has(lower)) continue;
        if (ent.name === '.git') {
            hasCommits = gitHasCommits(path.join(dirPath, '.git'));
            continue;
        }
        nonGitEntries += 1;
        if (isProjectSignal(ent, dirPath)) projectSignals = true;
    }

    if (hasCommits || projectSignals) return 'existing';
    if (nonGitEntries === 0) return 'new';
    return 'ambiguous';
}

const isMain = process.argv[1] &&
    path.normalize(fileURLToPath(import.meta.url)) === path.normalize(path.resolve(process.argv[1]));

if (isMain) {
    process.stdout.write(`${classifyProject(process.argv[2] || process.cwd())}\n`);
}
