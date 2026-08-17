import { intro, outro, text, select, multiselect, confirm, spinner, note } from '@clack/prompts';
import pc from 'picocolors';
import { SourceParser } from './lib/parser.js';
import { ProjectWriter } from './lib/writer.js';
import { findCollisions } from './lib/paths.js';
import { buildFilePlan, templateNameFor } from './lib/plan.js';
import { StagingSession } from './lib/staging.js';
import { prepareVariables, setupInstructions } from './lib/vars.js';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
    intro(pc.bgCyan(pc.black(' 🏗️  PROJECT SCAFFOLDER ')));

    const project = await fetchProjectInfo();
    if (!project) return;

    const destDir = path.resolve(String(project.dest || process.cwd()));
    const rawPlan = buildFilePlan(project);
    let vars = prepareVariables(project, []);
    const planned = rawPlan.map((p) => ProjectWriter.replacePlaceholders(p, vars));
    vars = prepareVariables(project, planned);
    const collisions = findCollisions(destDir, planned);

    let preview = `生成先: ${destDir}\n`;
    preview += `Hidemプロファイル: ${project.hidemProfile ? 'ON' : 'OFF'}\n`;
    preview += `AI保守: ${project.aiMaintained ? 'ON' : 'OFF'}\n\n`;
    preview += `作成予定:\n${planned.map((p) => `- ${p}`).join('\n')}`;
    if (collisions.length) {
        preview += `\n\n競合:\n${collisions.map((c) => `- ${c.planned} (existing ${c.existing})`).join('\n')}`;
    }
    note(preview, '書き込み前プレビュー');

    if (collisions.length) {
        outro(pc.red('既存ファイルと衝突したため、1件も書き込まず停止しました。'));
        return;
    }

    const go = await confirm({
        message: 'この内容で生成しますか？（まだ変更していません）',
        initialValue: false,
    });
    if (go !== true) {
        outro(pc.yellow('キャンセルしました。'));
        return;
    }

    const s = spinner();
    s.start('プロジェクトを構築中...');
    const session = new StagingSession(destDir);

    try {
        const templateSource = path.join(__dirname, 'FILE_TEMPLATE_SOURCE.md');
        const protocolSource = path.join(__dirname, 'MASTER_PROTOCOL_SOURCE.md');
        const parser = new SourceParser(templateSource);
        const protocolParser = new SourceParser(protocolSource);

        for (let i = 0; i < rawPlan.length; i++) {
            const raw = rawPlan[i];
            const outputPath = planned[i];
            const templateName = templateNameFor(raw, project.distribution);
            let section = parser.getSection(templateName);
            if (!section && raw === '.project_rules/MASTER_PROTOCOL.md') {
                section = protocolParser.getSection('MASTER_PROTOCOL.md 本文');
            }
            if (!section) {
                throw new Error(`template not found: ${templateName} -> ${outputPath}`);
            }
            const content = ProjectWriter.replacePlaceholders(section.content, vars);
            session.writeFile(outputPath, content);
        }

        session.commit();
        s.stop(pc.green('構築完了'));

        const nextSteps = setupInstructions(project);
        note(
            `プロジェクト "${project.name}" を作成しました。\n` +
            `場所: ${destDir}\n` +
            `Hidem: ${project.hidemProfile ? 'ON' : 'OFF'}\n\n` +
            `次に読む: README.md${project.aiMaintained ? ', AGENTS.md' : ''}${project.hidemProfile ? ', PROJECT.md' : ''}\n\n` +
            `セットアップ（未実行）:\n${nextSteps}`,
            '完了報告'
        );
    } catch (error) {
        s.stop(pc.red('構築失敗'));
        console.error(error);
        if (error.leftover && error.leftover.length) {
            console.error('残存パス（第三者変更の可能性）:', error.leftover);
        }
    } finally {
        session.cleanup();
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
            { value: 'MAUI', label: 'MAUI (Desktop/Mobile)', hint: 'C#' },
            { value: 'docs-only', label: '文書基盤だけ', hint: 'README 中心' }
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

    let modules = [];
    if (distribution !== 'MAUI' && distribution !== 'docs-only') {
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

    const aiMaintained = await confirm({
        message: 'AIで保守しますか？（AGENTS.md を追加）',
        initialValue: true
    });
    if (typeof aiMaintained === 'symbol') return null;

    const hidemProfile = await confirm({
        message: 'Hidemプロファイルを追加しますか？（PROJECT.md / MASTER_PROTOCOL.md）',
        initialValue: false
    });
    if (typeof hidemProfile === 'symbol') return null;

    const dest = await text({
        message: '生成先ディレクトリ',
        initialValue: process.cwd()
    });
    if (typeof dest === 'symbol') return null;

    return {
        name,
        description,
        author,
        distribution,
        connectivity,
        modules,
        gitPattern,
        aiMaintained: aiMaintained === true,
        hidemProfile: hidemProfile === true,
        dest
    };
}

const isMain = process.argv[1] &&
    path.normalize(fileURLToPath(import.meta.url)) === path.normalize(path.resolve(process.argv[1]));
if (isMain) {
    main();
}
